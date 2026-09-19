import type { CollectionSlug, Endpoint, PayloadRequest } from "payload";
import { writeAuditLog } from "@/hooks/audit";
import {
  BULK_ACTION_AUDIT_LABEL,
  BULK_ACTIONS,
  BULK_MAX_IDS,
  countResults,
  isBulkCollection,
  precheckBulkItem,
  type BulkAction,
  type BulkItemResult,
  type BulkItemState,
} from "@/lib/bulkActionRules";

/**
 * Toplu işlemler (18.09.2026, product list item 4) — `POST /api/bulk-actions`.
 *
 * Why an endpoint of our own instead of Payload's built-in bulk buttons:
 * Payload's list view offers Edit / Publish / Unpublish / Delete for a
 * selection based on collection `access` alone (`ListSelection` →
 * `PublishMany_v4` only checks `permissions.collections[slug].update`). It knows
 * nothing about our beforeChange guards, so a Growth Maker was offered a bulk
 * "Yayınla" whose only possible outcome was a 403 per record, and every role
 * got one generic toast ("X güncellendi" + a bare error list) with no way to
 * tell which record failed or why. Those built-ins are switched off on the
 * drafts-enabled collections (`disableBulkEdit`/`disableBulkDelete`) and
 * BulkActionsBar calls this instead. Those two flags also close the REST side
 * door: Payload's where-based `PATCH`/`DELETE /api/{slug}?where=…` now answers
 * 403 "has disabled bulk edit/delete" for every non-overrideAccess caller
 * (collections/operations/update.js, delete.js), so this endpoint is the only
 * multi-record write path on these collections. Nothing in this codebase used
 * the where-based form (all writes are by id); verified by grep 18.09.2026.
 *
 * What this does NOT do is re-implement any rule. Each record is saved through
 * the Local API as the real user, with `overrideAccess: false` and
 * `overrideLock: false`, in its own request object (so its own transaction —
 * one failure never rolls back the others). denyMakerPublish,
 * denyMakerEditPublished, guardPublishedEdit, manageCampaignSchedule,
 * blockDeleteIfReferenced and the rest run exactly as they do for a single
 * save, and so do the per-record audit and revalidate hooks. `precheckBulkItem`
 * only adds skips, never permissions.
 *
 * Records are processed one at a time on purpose: the order-assigning hooks
 * (assignFooterOrder, assignNextOrder) do read-then-write and are not safe to
 * run in parallel against each other.
 */

type Doc = Record<string, unknown> & { id?: string | number };

type ErrorLike = { status?: number; message?: string; name?: string };

function localized(req: PayloadRequest, tr: string, en: string): string {
  return req.i18n?.language === "en" ? en : tr;
}

/** A fresh request per record: same user, language and client headers (for the audit IP), no transaction, no query. */
function itemReq(req: PayloadRequest): Partial<PayloadRequest> {
  return { user: req.user, i18n: req.i18n, t: req.t, headers: req.headers, query: {}, context: {} };
}

function messageOf(err: unknown, req: PayloadRequest): { status: number; message: string } {
  const e = (err ?? {}) as ErrorLike;
  const status = typeof e.status === "number" ? e.status : 500;
  if (status === 404 || e.name === "NotFound") {
    return {
      status: 404,
      message: localized(req, "Kayıt bulunamadı ya da bu kayıt üzerinde bu işlem için yetkiniz yok.", "Record not found, or you may not do this to it."),
    };
  }
  if (status === 423 || e.name === "Locked") {
    return { status: 423, message: localized(req, "Kayıt şu anda başka biri tarafından düzenleniyor.", "Someone else is editing this record right now.") };
  }
  const message = typeof e.message === "string" && e.message.trim() ? e.message : localized(req, "İşlem tamamlanamadı.", "The action couldn't complete.");
  return { status, message };
}

function titleOf(doc: Doc | null | undefined, useAsTitle: string | undefined, id: string): string {
  const raw = doc && useAsTitle ? doc[useAsTitle] : undefined;
  return typeof raw === "string" && raw.trim() ? raw : `#${id}`;
}

async function readState(req: PayloadRequest, collection: CollectionSlug, id: string): Promise<{ main: Doc; latest: Doc; state: BulkItemState }> {
  const base = { collection, id, depth: 0, overrideAccess: false } as const;
  const main = (await req.payload.findByID({ ...base, draft: false, req: itemReq(req) })) as unknown as Doc;
  const latest = (await req.payload.findByID({ ...base, draft: true, req: itemReq(req) })) as unknown as Doc;
  return {
    main,
    latest,
    state: {
      mainStatus: main._status as string | undefined,
      hasPendingDraft: main._status === "published" && latest._status === "draft",
      reviewStatus: latest.reviewStatus as string | undefined,
      scheduledPublishAt: latest.scheduledPublishAt as string | undefined,
      unpublishRequest: main.unpublishRequest as string | undefined,
      createdBy: (main.createdBy ?? latest.createdBy) as BulkItemState["createdBy"],
    },
  };
}

async function perform(req: PayloadRequest, action: BulkAction, collection: CollectionSlug, id: string): Promise<void> {
  const common = { collection, id, depth: 0, overrideAccess: false, overrideLock: false, req: itemReq(req) } as const;
  switch (action) {
    case "publish":
      // Same request Payload's own PublishMany sends: only `_status`, so the
      // newest version (a pending draft, if any) is what goes live.
      await req.payload.update({ ...common, draft: false, data: { _status: "published" } as never });
      return;
    case "unpublish":
      // No `?draft=true`: a real unpublish, not a queued edit (see guardPublishedEdit).
      await req.payload.update({ ...common, draft: false, data: { _status: "draft" } as never });
      return;
    case "requestUnpublish":
      await req.payload.update({
        ...common,
        draft: false,
        data: {
          _status: "published",
          unpublishRequest: "pending",
          unpublishRequestedBy: req.user?.id,
          unpublishRequestedAt: new Date().toISOString(),
        } as never,
      });
      return;
    case "deleteDraft":
      await req.payload.delete({ ...common });
      return;
  }
}

const STATE_LABEL = (state: BulkItemState | undefined): string => {
  if (!state) return "—";
  if (state.hasPendingDraft) return "yayında (onay bekleyen değişiklik var)";
  return state.mainStatus === "published" ? "yayında" : "taslak";
};

const truncate = (s: string, max = 300) => (s.length > max ? `${s.slice(0, max)}…` : s);

export async function runBulkAction(
  req: PayloadRequest,
  input: { collection: CollectionSlug; action: BulkAction; ids: string[]; reviewConfirmed?: boolean }
): Promise<BulkItemResult[]> {
  const { collection, action, ids, reviewConfirmed } = input;
  const role = (req.user as { role?: string } | undefined)?.role;
  const userId = req.user?.id;
  const useAsTitle = req.payload.collections[collection]?.config.admin?.useAsTitle;
  const results: BulkItemResult[] = [];
  const auditRows: { field: string; before: string; after: string }[] = [];

  for (const id of ids) {
    let title = `#${id}`;
    let state: BulkItemState | undefined;
    let result: BulkItemResult;
    try {
      const read = await readState(req, collection, id);
      state = read.state;
      title = titleOf(read.latest, useAsTitle, id);
      const skip = precheckBulkItem({ action, collection, state, role, userId });
      if (skip) {
        result = { id, title, status: "skipped", message: req.i18n?.language === "en" ? skip.en : skip.tr };
      } else {
        await perform(req, action, collection, id);
        result = { id, title, status: "ok", message: localized(req, "Tamamlandı.", "Done.") };
      }
    } catch (err) {
      const { status, message } = messageOf(err, req);
      result = { id, title, status: "failed", message };
      // A refused write through the Local API never reaches the REST-only
      // afterError hook (auditForbiddenAttempt), so the attempt is logged here.
      if (status === 403) {
        await writeAuditLog(req, {
          action: "denied",
          collectionSlug: collection,
          documentId: id,
          summary: truncate(`${collection}: "${title}" ${BULK_ACTION_AUDIT_LABEL[action]} sırasında engellendi — ${message}`),
        });
      }
    }
    results.push(result);
    const outcome = { ok: "başarılı", skipped: "atlandı", failed: "başarısız" }[result.status];
    auditRows.push({
      field: truncate(`${id} — ${title}`, 120),
      before: STATE_LABEL(state),
      after: truncate(result.status === "ok" ? outcome : `${outcome}: ${result.message}`),
    });
  }

  const counts = countResults(results);
  await writeAuditLog(req, {
    action: "bulk",
    collectionSlug: collection,
    summary: `${collection}: ${BULK_ACTION_AUDIT_LABEL[action]} — ${ids.length} kayıt: ${counts.ok} başarılı, ${counts.skipped} atlandı, ${counts.failed} başarısız${
      reviewConfirmed ? " — kullanıcı seçili kayıtların her birini incelediğini ve yayına alınmasını onayladığını beyan etti" : ""
    }`,
    changes: auditRows,
  });
  return results;
}

function badRequest(req: PayloadRequest, tr: string, en: string): Response {
  return Response.json({ errors: [{ message: localized(req, tr, en) }] }, { status: 400 });
}

export const bulkActionsEndpoint: Endpoint = {
  path: "/bulk-actions",
  method: "post",
  handler: async (req) => {
    if (!req.user?.id) {
      return Response.json({ errors: [{ message: localized(req, "Giriş yapmalısınız.", "You must be logged in.") }] }, { status: 401 });
    }
    let body: { collection?: unknown; action?: unknown; ids?: unknown; reviewConfirmed?: unknown } = {};
    try {
      if (req.json) body = await req.json();
    } catch {
      return badRequest(req, "İstek okunamadı.", "The request couldn't be read.");
    }
    const { collection, action, ids } = body;
    if (typeof collection !== "string" || !isBulkCollection(collection)) {
      return badRequest(req, "Bu içerik tipinde toplu işlem yapılamaz.", "Bulk actions aren't available for this content type.");
    }
    if (typeof action !== "string" || !(BULK_ACTIONS as readonly string[]).includes(action)) {
      return badRequest(req, "Bilinmeyen toplu işlem.", "Unknown bulk action.");
    }
    if (!Array.isArray(ids) || ids.length === 0 || !ids.every((v) => typeof v === "string" || typeof v === "number")) {
      return badRequest(req, "Kayıt seçilmedi.", "No records selected.");
    }
    // 19.09.2026 kullanıcı: toplu yayın kapatılmasın, ama Checker "hepsini
    // inceledim ve onaylıyorum" diye ikinci kez açıkça beyan etsin. Required
    // here, not only in the UI, so a direct API call can't skip it; the
    // statement is written into the bulk audit row.
    if (action === "publish" && body.reviewConfirmed !== true) {
      return badRequest(
        req,
        "Toplu yayınlama için seçili kayıtların her birini incelediğinizi ve onayladığınızı beyan etmeniz gerekir.",
        "To publish in bulk you must confirm you have reviewed and approve every selected record."
      );
    }
    const unique = [...new Set(ids.map(String))];
    if (unique.length > BULK_MAX_IDS) {
      return badRequest(
        req,
        `Tek seferde en fazla ${BULK_MAX_IDS} kayıt işlenebilir.`,
        `At most ${BULK_MAX_IDS} records can be processed at once.`
      );
    }
    const results = await runBulkAction(req, {
      collection: collection as CollectionSlug,
      action: action as BulkAction,
      ids: unique,
      reviewConfirmed: action === "publish",
    });
    return Response.json({ action, collection, results, counts: countResults(results) });
  },
};
