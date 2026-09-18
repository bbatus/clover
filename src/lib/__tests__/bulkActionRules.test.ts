import { describe, expect, it } from "vitest";
import { ROLES } from "@/access/roleConstants";
import { BULK_COLLECTIONS, bulkActionsFor, countResults, precheckBulkItem, type BulkItemState } from "@/lib/bulkActionRules";
import { DRAFT_ENABLED_COLLECTIONS } from "@/lib/collectionLabels";

const offer = (role: string, collection = "blog-posts", extra: Partial<Parameters<typeof bulkActionsFor>[0]> = {}) =>
  bulkActionsFor({ role, collection, canUpdate: true, canDelete: false, isActiveDelegate: false, ...extra });

describe("bulkActionsFor", () => {
  it("never offers a plain Growth Maker publish or unpublish", () => {
    expect(offer(ROLES.GROWTH_MAKER)).toEqual([]);
    expect(offer(ROLES.GROWTH_MAKER, "campaigns")).toEqual(["requestUnpublish"]);
    expect(offer(ROLES.GROWTH_MAKER, "campaigns", { canDelete: true })).toEqual(["requestUnpublish", "deleteDraft"]);
  });

  it("lets an active checker delegate publish, but still not unpublish", () => {
    expect(offer(ROLES.GROWTH_MAKER, "pages", { isActiveDelegate: true })).toEqual(["publish"]);
  });

  it("gives the checkers publish and unpublish, never delete", () => {
    expect(offer(ROLES.GROWTH_CHECKER)).toEqual(["publish", "unpublish"]);
    expect(offer(ROLES.NEW_VERTICAL_CHECKER, "campaigns")).toEqual(["publish", "unpublish"]);
  });

  it("gives the New Vertical Maker everything it has access to", () => {
    expect(offer(ROLES.NEW_VERTICAL_MAKER, "faq-items", { canDelete: true })).toEqual(["publish", "unpublish", "deleteDraft"]);
  });

  it("follows collection access and the collection allow-list", () => {
    expect(offer(ROLES.NEW_VERTICAL_MAKER, "faq-items", { canUpdate: false })).toEqual([]);
    expect(offer(ROLES.NEW_VERTICAL_MAKER, "users", { canDelete: true })).toEqual([]);
    expect(offer("", "pages")).toEqual([]);
  });

  it("covers exactly the drafts-enabled collections", () => {
    expect(new Set(BULK_COLLECTIONS)).toEqual(DRAFT_ENABLED_COLLECTIONS);
  });
});

const draft: BulkItemState = { mainStatus: "draft", hasPendingDraft: false };
const live: BulkItemState = { mainStatus: "published", hasPendingDraft: false };
const check = (action: Parameters<typeof precheckBulkItem>[0]["action"], state: BulkItemState, collection = "blog-posts", role: string = ROLES.NEW_VERTICAL_MAKER, userId: number | undefined = 1) =>
  precheckBulkItem({ action, collection, state, role, userId })?.code ?? null;

describe("precheckBulkItem", () => {
  it("publish: skips what is already live unless an edit is waiting", () => {
    expect(check("publish", draft)).toBeNull();
    expect(check("publish", live)).toBe("alreadyPublished");
    expect(check("publish", { ...live, hasPendingDraft: true })).toBeNull();
  });

  it("publish: leaves scheduled and rejected campaigns alone, with the plan time in the reason", () => {
    const reason = precheckBulkItem({
      action: "publish",
      collection: "campaigns",
      state: { ...draft, reviewStatus: "scheduled", scheduledPublishAt: "2026-10-15T09:00:00.000Z" },
      role: ROLES.GROWTH_CHECKER,
      userId: 2,
    });
    expect(reason?.code).toBe("scheduled");
    expect(reason?.tr).toContain("15.10.2026 12:00 (İstanbul)");
    expect(check("publish", { ...draft, reviewStatus: "rejected" }, "campaigns")).toBe("rejected");
    // The same review field on another collection means nothing.
    expect(check("publish", { ...draft, reviewStatus: "scheduled" }, "pages")).toBeNull();
  });

  it("unpublish: only live records", () => {
    expect(check("unpublish", draft)).toBe("notPublished");
    expect(check("unpublish", live)).toBeNull();
  });

  it("requestUnpublish: live campaigns without an open request or a queued edit", () => {
    expect(check("requestUnpublish", live, "pages")).toBe("notSupported");
    expect(check("requestUnpublish", draft, "campaigns")).toBe("notPublished");
    expect(check("requestUnpublish", { ...live, unpublishRequest: "pending" }, "campaigns")).toBe("alreadyRequested");
    expect(check("requestUnpublish", { ...live, hasPendingDraft: true }, "campaigns")).toBe("pendingDraft");
    expect(check("requestUnpublish", live, "campaigns", ROLES.GROWTH_MAKER)).toBeNull();
  });

  it("deleteDraft: never a live record; a Growth Maker only its own drafts", () => {
    expect(check("deleteDraft", live)).toBe("published");
    expect(check("deleteDraft", { ...live, hasPendingDraft: true })).toBe("published");
    expect(check("deleteDraft", draft)).toBeNull();
    expect(check("deleteDraft", { ...draft, createdBy: 1 }, "faq-items", ROLES.GROWTH_MAKER, 1)).toBeNull();
    expect(check("deleteDraft", { ...draft, createdBy: { id: 1 } }, "faq-items", ROLES.GROWTH_MAKER, 1)).toBeNull();
    expect(check("deleteDraft", { ...draft, createdBy: 7 }, "faq-items", ROLES.GROWTH_MAKER, 1)).toBe("notOwner");
    expect(check("deleteDraft", { ...draft, createdBy: null }, "faq-items", ROLES.GROWTH_MAKER, 1)).toBe("notOwner");
  });
});

describe("countResults", () => {
  it("counts each outcome", () => {
    expect(
      countResults([
        { id: "1", title: "a", status: "ok", message: "" },
        { id: "2", title: "b", status: "failed", message: "x" },
        { id: "3", title: "c", status: "ok", message: "" },
        { id: "4", title: "d", status: "skipped", message: "y" },
      ])
    ).toEqual({ ok: 2, skipped: 1, failed: 1 });
  });
});
