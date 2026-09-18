import { APIError } from "payload";
import type { CollectionBeforeChangeHook, Payload, PayloadRequest } from "payload";
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
/** How the scheduler shows up in the audit log. */
const SYSTEM_ACTOR = "sistem (zamanlanmış yayın)";

/**
 * Thrown when the scheduler's own publish finds the plan gone by the time the
 * save runs (a Maker edited, a Checker cancelled or published by hand between
 * the scheduler's query and its update). Not an error — the run skips it.
 */
export class ScheduleNoLongerDueError extends APIError {
  constructor() {
    super("Scheduled publish no longer applies to this campaign", 409, undefined, false);
    this.name = "ScheduleNoLongerDueError";
  }
}

export const manageCampaignSchedule: CollectionBeforeChangeHook = async ({ data, operation, originalDoc, req, context }) => {
  if (!data) return data;
  const role = (req.user as { role?: string } | undefined)?.role;
  const before = (originalDoc ?? {}) as Doc;

  if (context?.[SCHEDULED_PUBLISH_CONTEXT]) {
    // 18.09.2026 review: the scheduler's context flag skips every rule below,
    // and its update publishes whatever the NEWEST version is. Its due-list
    // query runs before the update, so a Maker edit saved in between (which
    // drops the approval to "pending") would otherwise go live unapproved.
    // `originalDoc` here is read inside this same save, so re-checking it
    // closes that window: only a still-approved, still-due draft is published.
    const at = before.scheduledPublishAt as string | undefined;
    const stillDue = before.reviewStatus === "scheduled" && before._status !== "published" && Boolean(at) && new Date(at as string).getTime() <= Date.now();
    if (!stillDue) throw new ScheduleNoLongerDueError();
    return data;
  }
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

export type ScheduledRunResult = { published: string[]; failed: { id: string; error: string }[]; skipped: string[] };

/**
 * Per-campaign retry state for publishes that failed. A failure that repeats
 * (typically validation: a category or image the campaign points at was
 * deleted after approval — the same trap AGENTS.md describes for FAQ
 * categories) used to be retried and logged as an error every 30 seconds
 * forever, and nobody in the CMS could see why the campaign never went live.
 * Now: exponential backoff up to an hour, and the first failure is written to
 * the audit log so it shows up where editors and auditors look. In-memory per
 * pod on purpose — at worst a second pod retries once more, which is harmless.
 */
const RETRY_BASE_MS = 30_000;
const RETRY_MAX_MS = 60 * 60 * 1000;
const failures = new Map<string, { count: number; retryAt: number }>();

/** Test hook: forget retry state between cases. */
export function resetScheduledPublishRetries(): void {
  failures.clear();
}

function systemReq(payload: Payload): PayloadRequest {
  return { payload, headers: new Headers(), context: {} } as unknown as PayloadRequest;
}

/**
 * Publishes every approved campaign whose time has come. Safe to call from
 * several pods at once: each pod only acts while holding a Postgres advisory
 * lock (see `startScheduledPublishing`), and a campaign that is already
 * published no longer matches the query — or, if it changed after the query,
 * is refused by manageCampaignSchedule's own re-check.
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
    // Oldest plan first; anything beyond 50 is picked up on the next tick.
    sort: "scheduledPublishAt",
    limit: 50,
    overrideAccess: true,
    pagination: false,
  });

  const result: ScheduledRunResult = { published: [], failed: [], skipped: [] };
  for (const doc of due.docs as unknown as Doc[]) {
    const id = String(doc.id);
    const retry = failures.get(id);
    if (retry && retry.retryAt > now.getTime()) continue;
    try {
      await payload.update({
        collection: "campaigns",
        id: doc.id as number,
        data: { _status: "published", reviewStatus: "pending" },
        depth: 0,
        overrideAccess: true,
        context: { [SCHEDULED_PUBLISH_CONTEXT]: true, auditActor: { email: SYSTEM_ACTOR, role: "system" } },
      });
      failures.delete(id);
      result.published.push(id);
      const planned = doc.scheduledPublishAt ? ` (planned ${formatIstanbul(String(doc.scheduledPublishAt))} Istanbul)` : "";
      payload.logger.info(`[scheduled-publish] campaign ${id} published${planned}`);
    } catch (err) {
      if (err instanceof ScheduleNoLongerDueError) {
        failures.delete(id);
        result.skipped.push(id);
        payload.logger.info(`[scheduled-publish] campaign ${id} skipped: its plan changed after this run started`);
        continue;
      }
      const error = err instanceof Error ? err.message : String(err);
      const count = (retry?.count ?? 0) + 1;
      const delay = Math.min(RETRY_BASE_MS * 2 ** (count - 1), RETRY_MAX_MS);
      failures.set(id, { count, retryAt: now.getTime() + delay });
      result.failed.push({ id, error });
      payload.logger.error(`[scheduled-publish] campaign ${id} could not be published (attempt ${count}, next try in ${Math.round(delay / 1000)}s): ${error}`);
      if (count === 1) {
        await writeAuditLog(systemReq(payload), {
          action: "update",
          collectionSlug: "campaigns",
          documentId: id,
          actorEmail: SYSTEM_ACTOR,
          actorRole: "system",
          summary: `campaigns: "${doc.title ?? id}" zamanlanmış yayını BAŞARISIZ oldu, kampanya yayına girmedi — ${error}`.slice(0, 500),
        });
      }
    }
  }
  return result;
}

/** Arbitrary, fixed advisory-lock key for the scheduler ("VFPAYSCH"). */
const ADVISORY_LOCK_KEY = 5_641_893_217;
const INTERVAL_MS = 30_000;

type PgPool = {
  connect: () => Promise<{ query: (sql: string, params?: unknown[]) => Promise<{ rows: Record<string, unknown>[] }>; release: (destroy?: Error | boolean) => void }>;
};

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
    // A session-level advisory lock lives on the pooled connection, not on
    // this tick. If unlocking fails, handing that connection back to the pool
    // would leave the lock held for as long as the connection lives, and every
    // other pod would skip every tick. Destroying the connection instead makes
    // Postgres drop the lock with the session (same as a pod dying mid-run).
    let broken: Error | undefined;
    try {
      let locked = false;
      try {
        const { rows } = await client.query("SELECT pg_try_advisory_lock($1) AS locked", [ADVISORY_LOCK_KEY]);
        locked = Boolean(rows[0]?.locked);
      } catch (err) {
        broken = err instanceof Error ? err : new Error(String(err));
        throw err;
      }
      if (!locked) return;
      try {
        await runScheduledPublishes(payload);
      } finally {
        try {
          await client.query("SELECT pg_advisory_unlock($1)", [ADVISORY_LOCK_KEY]);
        } catch (err) {
          broken = err instanceof Error ? err : new Error(String(err));
        }
      }
    } finally {
      client.release(broken);
    }
  };
  const safeTick = () => {
    tick().catch((err) => payload.logger.error(`[scheduled-publish] tick failed: ${err instanceof Error ? err.message : String(err)}`));
  };
  g[globalKey] = setInterval(safeTick, INTERVAL_MS);
  safeTick();
  payload.logger.info("[scheduled-publish] scheduler started (every 30s, Europe/Istanbul display)");
}
