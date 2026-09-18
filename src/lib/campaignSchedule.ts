import { APIError } from "payload";
import type { CollectionBeforeChangeHook, Payload } from "payload";
import { hasActiveCheckerDelegate, ROLES } from "@/access/roles";
import { writeAuditLog } from "@/hooks/audit";
import { formatIstanbul, SCHEDULE_TIME_ZONE } from "@/lib/istanbulTime";

/**
 * 18.09.2026 kullanıcı: "Maker onaya gönderirken ileri tarihte yayınla derse
 * tarih ve saat seçip onaya göndersin, Checker ona göre onaylasın, onay
 * alırsa o tarihte çıksın. OpenShift'e alacağım için İstanbul saatine uyumlu
 * olsun."
 *
 * The flow, all enforced here on the server:
 * 1. A Maker fills `scheduledPublishAt` and sends the draft for review as usual.
 * 2. A role that may publish approves it: `reviewStatus` → "scheduled". The
 *    campaign stays a DRAFT; who approved and when is stamped on it.
 * 3. `runScheduledPublishes` (started from payload.config's onInit) publishes
 *    every approved campaign whose time has come.
 * 4. Any content change after approval — including moving the date — drops the
 *    approval back to "pending", so what goes live is exactly what was approved.
 *
 * Time zone: `scheduledPublishAt` is stored as an absolute UTC instant (a
 * Postgres timestamptz); the admin picker is pinned to Europe/Istanbul, so the
 * editor picks Istanbul wall-clock time whatever their browser or the pod is
 * set to. Every comparison below is instant-to-instant, which is why the pod's
 * own TZ (UTC on OpenShift unless set) can't shift a publish by 3 hours.
 */

export { SCHEDULE_TIME_ZONE, formatIstanbul };

/** Review-state and bookkeeping fields: changing only these is not a content change. */
const SCHEDULE_META_FIELDS = new Set([
  "_status",
  "reviewStatus",
  "rejectionReason",
  "rejectedAt",
  "rejectedBy",
  "scheduleApprovedBy",
  "scheduleApprovedAt",
  "unpublishRequest",
  "unpublishRequestedBy",
  "unpublishRequestedAt",
  "forceLiveEdit",
  "updatedAt",
  "createdAt",
  "id",
]);

type Doc = Record<string, unknown>;

/** Relationship values come back as ids from the form but as objects from a depth>0 read. */
function normalize(value: unknown): unknown {
  if (value && typeof value === "object" && !Array.isArray(value) && "id" in (value as Doc)) {
    return (value as Doc).id;
  }
  if (value instanceof Date) return value.toISOString();
  return value;
}

export function changedContentFields(data: Doc, originalDoc: Doc): string[] {
  return Object.keys(data).filter(
    (key) => !SCHEDULE_META_FIELDS.has(key) && JSON.stringify(normalize(data[key])) !== JSON.stringify(normalize(originalDoc[key]))
  );
}

function message(req: { i18n?: { language?: string } }, tr: string, en: string): string {
  return req.i18n?.language === "en" ? en : tr;
}

/** Context flag set by the scheduler itself; lets its own publish through the rules below. */
export const SCHEDULED_PUBLISH_CONTEXT = "scheduledPublish";

export const manageCampaignSchedule: CollectionBeforeChangeHook = async ({ data, operation, originalDoc, req, context }) => {
  if (!data) return data;
  if (context?.[SCHEDULED_PUBLISH_CONTEXT]) return data;

  const role = (req.user as { role?: string } | undefined)?.role;
  const before = (originalDoc ?? {}) as Doc;
  const wasScheduled = operation === "update" && before.reviewStatus === "scheduled";
  const wantsScheduled = data.reviewStatus === "scheduled";

  // Publishing by hand (a Checker's normal "Yayınla") supersedes a pending plan.
  if (data._status === "published") {
    if (wasScheduled || wantsScheduled) {
      data.reviewStatus = "pending";
      data.scheduleApprovedBy = null;
      data.scheduleApprovedAt = null;
    }
    return data;
  }

  // Approving a plan: only a role that could publish may do it, and only for a future time.
  if (wantsScheduled && !wasScheduled) {
    const mayPublish =
      role === ROLES.NEW_VERTICAL_MAKER ||
      role === ROLES.NEW_VERTICAL_CHECKER ||
      role === ROLES.GROWTH_CHECKER ||
      (role === ROLES.GROWTH_MAKER && req.user?.id !== undefined && (await hasActiveCheckerDelegate(req.payload, req.user.id)));
    if (!mayPublish) {
      throw new APIError(
        message(req, "Zamanlanmış yayını yalnızca bir Checker onaylayabilir.", "Only a Checker can approve a scheduled publish."),
        403,
        undefined,
        true
      );
    }
    const at = (data.scheduledPublishAt ?? before.scheduledPublishAt) as string | undefined;
    if (!at) {
      throw new APIError(
        message(req, "Planlamak için önce bir yayın tarihi ve saati seçin.", "Pick a publish date and time before scheduling."),
        400,
        undefined,
        true
      );
    }
    if (new Date(at).getTime() <= Date.now()) {
      throw new APIError(
        message(
          req,
          `Seçilen yayın zamanı (${formatIstanbul(at)}, İstanbul) geçmişte kaldı. Tarihi ileri alın ya da hemen yayınlayın.`,
          `The chosen publish time (${formatIstanbul(at)}, Istanbul) is already in the past. Move it forward or publish now.`
        ),
        400,
        undefined,
        true
      );
    }
    if (before._status === "published") {
      throw new APIError(
        message(req, "Bu kampanya zaten yayında.", "This campaign is already live."),
        409,
        undefined,
        true
      );
    }
    data.scheduleApprovedBy = req.user?.id ?? null;
    data.scheduleApprovedAt = new Date().toISOString();
    await writeAuditLog(req, {
      action: "update",
      collectionSlug: "campaigns",
      documentId: String(before.id ?? ""),
      summary: `campaigns: "${data.title ?? before.title ?? before.id}" ${formatIstanbul(at)} (İstanbul) tarihinde yayınlanmak üzere onaylandı`,
    });
    return data;
  }

  if (!wasScheduled) return data;

  // Already approved: cancelling, or changing what was approved, both send it back to review.
  const cancelled = data.reviewStatus !== undefined && data.reviewStatus !== "scheduled";
  const changed = changedContentFields(data, before);
  if (cancelled || changed.length > 0) {
    data.reviewStatus = "pending";
    data.scheduleApprovedBy = null;
    data.scheduleApprovedAt = null;
    await writeAuditLog(req, {
      action: "update",
      collectionSlug: "campaigns",
      documentId: String(before.id ?? ""),
      summary: cancelled
        ? `campaigns: "${before.title ?? before.id}" zamanlanmış yayın planı iptal edildi`
        : `campaigns: "${before.title ?? before.id}" onaydan sonra değiştirildi (${changed.join(", ")}) — zamanlanmış yayın onayı düştü, yeniden onay gerekiyor`,
    });
  }
  return data;
};

export type ScheduledRunResult = { published: string[]; failed: { id: string; error: string }[] };

/**
 * Publishes every approved campaign whose time has come. Safe to call from
 * several pods at once: each pod only acts while holding a Postgres advisory
 * lock (see `startScheduledPublishing`), and a campaign that is already
 * published no longer matches the query.
 */
export async function runScheduledPublishes(payload: Payload, now: Date = new Date()): Promise<ScheduledRunResult> {
  const due = await payload.find({
    collection: "campaigns",
    where: {
      and: [
        { reviewStatus: { equals: "scheduled" } },
        { _status: { equals: "draft" } },
        { scheduledPublishAt: { less_than_equal: now.toISOString() } },
      ],
    },
    draft: true,
    depth: 0,
    limit: 50,
    overrideAccess: true,
    pagination: false,
  });

  const result: ScheduledRunResult = { published: [], failed: [] };
  for (const doc of due.docs as unknown as Doc[]) {
    const id = String(doc.id);
    try {
      await payload.update({
        collection: "campaigns",
        id: doc.id as number,
        data: { _status: "published", reviewStatus: "pending" },
        depth: 0,
        overrideAccess: true,
        context: { [SCHEDULED_PUBLISH_CONTEXT]: true, auditActor: { email: "sistem (zamanlanmış yayın)", role: "system" } },
      });
      result.published.push(id);
      const planned = doc.scheduledPublishAt ? ` (planned ${formatIstanbul(String(doc.scheduledPublishAt))} Istanbul)` : "";
      payload.logger.info(`[scheduled-publish] campaign ${id} published${planned}`);
    } catch (err) {
      const error = err instanceof Error ? err.message : String(err);
      result.failed.push({ id, error });
      payload.logger.error(`[scheduled-publish] campaign ${id} could not be published: ${error}`);
    }
  }
  return result;
}

/** Arbitrary, fixed advisory-lock key for the scheduler ("VFPAYSCH"). */
const ADVISORY_LOCK_KEY = 5_641_893_217;
const INTERVAL_MS = 30_000;

type PgPool = { connect: () => Promise<{ query: (sql: string, params?: unknown[]) => Promise<{ rows: Record<string, unknown>[] }>; release: () => void }> };

/**
 * Starts the once-every-30-seconds check. Every pod runs the timer, but only the
 * pod that wins `pg_try_advisory_lock` does the work for that tick, so an
 * HPA-scaled deployment still publishes each campaign once. Disabled in tests
 * and during `next build`, and with SCHEDULED_PUBLISH_DISABLED=true.
 */
export function startScheduledPublishing(payload: Payload): void {
  if (process.env.SCHEDULED_PUBLISH_DISABLED === "true") return;
  if (process.env.VITEST || process.env.NEXT_PHASE === "phase-production-build") return;
  const globalKey = "__vfpayScheduledPublishTimer";
  const g = globalThis as unknown as Record<string, ReturnType<typeof setInterval> | undefined>;
  if (g[globalKey]) return; // dev hot reload re-runs onInit; keep one timer

  const pool = (payload.db as unknown as { pool?: PgPool }).pool;
  const tick = async () => {
    if (!pool) {
      await runScheduledPublishes(payload);
      return;
    }
    const client = await pool.connect();
    try {
      const { rows } = await client.query("SELECT pg_try_advisory_lock($1) AS locked", [ADVISORY_LOCK_KEY]);
      if (!rows[0]?.locked) return;
      try {
        await runScheduledPublishes(payload);
      } finally {
        await client.query("SELECT pg_advisory_unlock($1)", [ADVISORY_LOCK_KEY]);
      }
    } finally {
      client.release();
    }
  };
  const safeTick = () => {
    tick().catch((err) => payload.logger.error(`[scheduled-publish] tick failed: ${err instanceof Error ? err.message : String(err)}`));
  };
  g[globalKey] = setInterval(safeTick, INTERVAL_MS);
  safeTick();
  payload.logger.info("[scheduled-publish] scheduler started (every 30s, Europe/Istanbul display)");
}
