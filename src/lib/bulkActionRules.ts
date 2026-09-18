import { ROLES } from "@/access/roleConstants";
import { formatIstanbul } from "@/lib/istanbulTime";

/**
 * Toplu işlemler (18.09.2026, product list item 4) — the pure half.
 *
 * Deliberately imports nothing from "payload": BulkActionsBar (a client
 * component) uses `bulkActionsFor` to decide which buttons to show, and the
 * server endpoint (lib/bulkActions.ts) uses the same function plus
 * `precheckBulkItem`, so the list view and the server can never disagree about
 * what is on offer.
 *
 * Precheck only ever makes the bulk path STRICTER than a single save. Every
 * record that passes it still goes through the collection's own hooks as the
 * real user (`overrideAccess: false`) — denyMakerPublish, denyMakerEditPublished,
 * guardPublishedEdit, manageCampaignSchedule, blockDeleteIfReferenced… — and
 * those remain the authority. What precheck adds is (a) a clear reason for the
 * states where a bulk action would do something nobody asked for, and (b) a
 * cheap skip for records that are already in the target state.
 */

export type BulkAction = "publish" | "unpublish" | "requestUnpublish" | "deleteDraft";

export const BULK_ACTIONS: readonly BulkAction[] = ["publish", "unpublish", "requestUnpublish", "deleteDraft"];

/** Hard cap per request — keeps one click from turning into minutes of sequential saves. */
export const BULK_MAX_IDS = 100;

/**
 * Every drafts-enabled collection (DRAFT_ENABLED_COLLECTIONS). Kept as its own
 * list — rather than importing that Set — so the server endpoint's allow-list
 * is explicit and reviewed on its own.
 */
export const BULK_COLLECTIONS = [
  "campaigns",
  "blog-posts",
  "pages",
  "faq-items",
  "announcements",
  "fee-rows",
  "limit-tables",
  "nav-links",
  "legal-pages",
  "cookie-rows",
  "page-meta",
  "categories",
  "representatives",
  "documents",
] as const;

export function isBulkCollection(slug: string): boolean {
  return (BULK_COLLECTIONS as readonly string[]).includes(slug);
}

/** Roles that may take something live or off the air themselves (never a plain Growth Maker). */
const PUBLISHER_ROLES = new Set<string>([ROLES.NEW_VERTICAL_MAKER, ROLES.NEW_VERTICAL_CHECKER, ROLES.GROWTH_CHECKER]);

/**
 * Which bulk actions a role gets on a collection's list view.
 *
 * - publish: New Vertical Maker/Checker, Growth Checker, and a Growth Maker
 *   while an active checker delegate (denyRolePublish lets a delegate publish).
 * - unpublish: New Vertical Maker/Checker and Growth Checker only. A Growth
 *   Maker can never take something down itself — delegate or not, both
 *   denyMakerEditPublished and Campaigns' guardPublishedEdit refuse it.
 * - requestUnpublish: Growth Maker on campaigns — the bulk form of the
 *   "Yayından Kaldırma Talebi Oluştur" button it already has on one campaign.
 * - deleteDraft: whoever has delete access (New Vertical Maker; Growth Maker
 *   for its own drafts). Published records are never deleted in bulk.
 *
 * Payload's bulk "Düzenle" (EditMany) is not offered: `disableBulkEdit` also
 * closes the where-based `PATCH /api/{slug}?where=…` it depends on — Payload's
 * update operation throws "has disabled bulk edit" for any non-overrideAccess
 * call (payload/dist/collections/operations/update.js) — and its drawer carried
 * a role-blind "Publish changes" button anyway. Bulk field edits were never
 * part of the maker→checker flow; records are edited one at a time.
 */
export function bulkActionsFor(input: {
  role: string | undefined;
  collection: string;
  canUpdate: boolean;
  canDelete: boolean;
  isActiveDelegate: boolean;
}): BulkAction[] {
  const { role, collection, canUpdate, canDelete, isActiveDelegate } = input;
  const actions: BulkAction[] = [];
  if (!role || !isBulkCollection(collection)) return actions;
  const isGrowthMaker = role === ROLES.GROWTH_MAKER;
  if (canUpdate && (PUBLISHER_ROLES.has(role) || (isGrowthMaker && isActiveDelegate))) actions.push("publish");
  if (canUpdate && PUBLISHER_ROLES.has(role)) actions.push("unpublish");
  if (canUpdate && isGrowthMaker && collection === "campaigns") actions.push("requestUnpublish");
  if (canDelete) actions.push("deleteDraft");
  return actions;
}

/** What the server knows about one record before acting on it. */
export type BulkItemState = {
  /** `_status` of the live row (a `draft: false` read). */
  mainStatus?: string | null;
  /** The newest version is a draft while the live row is published: an edit is waiting for review. */
  hasPendingDraft: boolean;
  reviewStatus?: string | null;
  scheduledPublishAt?: string | null;
  unpublishRequest?: string | null;
  /** Id, or the populated user object from a depth>0 read. */
  createdBy?: string | number | { id: string | number } | null;
};

export type SkipReason = { code: string; tr: string; en: string };

function idOf(value: unknown): string | undefined {
  if (value === null || value === undefined) return undefined;
  if (typeof value === "object" && "id" in (value as Record<string, unknown>)) return String((value as { id: unknown }).id);
  return String(value as string | number);
}

/**
 * Returns a reason to leave this record alone, or null to go ahead (and let the
 * collection's own hooks decide).
 */
export function precheckBulkItem(input: {
  action: BulkAction;
  collection: string;
  state: BulkItemState;
  role: string | undefined;
  userId: string | number | undefined;
}): SkipReason | null {
  const { action, collection, state, role, userId } = input;
  const isPublished = state.mainStatus === "published";
  const isCampaign = collection === "campaigns";

  switch (action) {
    case "publish": {
      if (isPublished && !state.hasPendingDraft) {
        return { code: "alreadyPublished", tr: "Zaten yayında, bekleyen bir değişiklik yok.", en: "Already live with no pending changes." };
      }
      // A plan a Checker approved for a specific time is not overridden by a
      // bulk click — manageCampaignSchedule would silently drop it.
      if (isCampaign && state.reviewStatus === "scheduled") {
        const at = state.scheduledPublishAt ? formatIstanbul(state.scheduledPublishAt) : "";
        return {
          code: "scheduled",
          tr: `${at} (İstanbul) için planlanmış. Planı değiştirmek ya da hemen yayınlamak için kampanyayı açın.`,
          en: `Scheduled for ${at} (Istanbul). Open the campaign to change the plan or publish now.`,
        };
      }
      if (isCampaign && state.reviewStatus === "rejected") {
        return {
          code: "rejected",
          tr: "Reddedilmiş. Maker düzeltip yeniden onaya göndermeden toplu yayınlanmaz.",
          en: "Rejected. Not bulk-published until the Maker fixes and resubmits it.",
        };
      }
      return null;
    }
    case "unpublish": {
      if (!isPublished) {
        return { code: "notPublished", tr: "Zaten yayında değil.", en: "Not live already." };
      }
      return null;
    }
    case "requestUnpublish": {
      if (!isCampaign) {
        return { code: "notSupported", tr: "Yayından kaldırma talebi yalnızca kampanyalarda var.", en: "Unpublish requests exist only on campaigns." };
      }
      if (!isPublished) {
        return { code: "notPublished", tr: "Yayında değil, talep gerekmiyor.", en: "Not live, no request needed." };
      }
      if (state.unpublishRequest === "pending") {
        return { code: "alreadyRequested", tr: "Bu kampanya için zaten bekleyen bir talep var.", en: "A request is already pending for this campaign." };
      }
      // The request is saved as a normal update; with an edit already queued
      // it would carry that edit along. Filed from the campaign screen instead.
      if (state.hasPendingDraft) {
        return {
          code: "pendingDraft",
          tr: "Onay bekleyen bir düzenlemesi var. Talebi kampanya ekranından oluşturun.",
          en: "It has an edit waiting for review. File the request from the campaign screen.",
        };
      }
      return null;
    }
    case "deleteDraft": {
      if (isPublished) {
        return {
          code: "published",
          tr: "Yayındaki kayıt toplu silinmez. Önce yayından kaldırın.",
          en: "A live record is not deleted in bulk. Unpublish it first.",
        };
      }
      if (role === ROLES.GROWTH_MAKER && (userId === undefined || idOf(state.createdBy) !== String(userId))) {
        return {
          code: "notOwner",
          tr: "Yalnızca kendi oluşturduğunuz taslakları silebilirsiniz.",
          en: "You can only delete drafts you created.",
        };
      }
      return null;
    }
    default:
      return { code: "unknownAction", tr: "Bilinmeyen işlem.", en: "Unknown action." };
  }
}

export type BulkItemResult = {
  id: string;
  title: string;
  status: "ok" | "skipped" | "failed";
  message: string;
};

export type BulkResponse = {
  action: BulkAction;
  collection: string;
  results: BulkItemResult[];
  counts: { ok: number; skipped: number; failed: number };
};

export function countResults(results: BulkItemResult[]): BulkResponse["counts"] {
  return {
    ok: results.filter((r) => r.status === "ok").length,
    skipped: results.filter((r) => r.status === "skipped").length,
    failed: results.filter((r) => r.status === "failed").length,
  };
}

/** Turkish verb phrase for the audit summary (audit summaries are always Turkish, like every other entry). */
export const BULK_ACTION_AUDIT_LABEL: Record<BulkAction, string> = {
  publish: "toplu yayınlama",
  unpublish: "toplu yayından kaldırma",
  requestUnpublish: "toplu yayından kaldırma talebi",
  deleteDraft: "toplu taslak silme",
};

/**
 * The list-view slot entry every bulk collection wires into
 * `admin.components.beforeListTable` (next to `disableBulkEdit` /
 * `disableBulkDelete: true`, which switch off Payload's own role-blind bulk
 * buttons — see lib/bulkActions.ts).
 */
export function bulkActionsBar(collection: (typeof BULK_COLLECTIONS)[number]) {
  return { path: "/components/BulkActionsBar#default", clientProps: { collection } };
}
