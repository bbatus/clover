import { beforeEach, describe, expect, it, vi } from "vitest";
import { bulkActionsEndpoint } from "@/lib/bulkActions";
import { writeAuditLog } from "@/hooks/audit";

vi.mock("@/hooks/audit", () => ({ writeAuditLog: vi.fn() }));

type Doc = Record<string, unknown>;
/** Loose shape of what the endpoint passes to the Local API — enough to assert on. */
type CallArgs = { id: string; draft?: boolean; overrideAccess?: boolean; req?: Record<string, unknown>; data?: Record<string, unknown> };

/** A fake Local API: `docs[id]` is the live row, `drafts[id]` the newest version (defaults to the live row). */
function makeReq(opts: { body?: unknown; user?: unknown; docs?: Record<string, Doc>; drafts?: Record<string, Doc>; failOn?: Record<string, Error> }) {
  const docs = opts.docs ?? {};
  const drafts = opts.drafts ?? {};
  const failOn = opts.failOn ?? {};
  const payload = {
    collections: { "blog-posts": { config: { admin: { useAsTitle: "title" } } }, campaigns: { config: { admin: { useAsTitle: "title" } } } },
    findByID: vi.fn(async ({ id, draft }: CallArgs) => {
      const doc = draft ? (drafts[id] ?? docs[id]) : docs[id];
      if (!doc) throw Object.assign(new Error("Not Found"), { status: 404, name: "NotFound" });
      return doc;
    }),
    update: vi.fn(async ({ id }: CallArgs) => {
      if (failOn[id]) throw failOn[id];
      return {};
    }),
    delete: vi.fn(async ({ id }: CallArgs) => {
      if (failOn[id]) throw failOn[id];
      return {};
    }),
  };
  const req = {
    user: "user" in opts ? opts.user : { id: 1, role: "growth_checker" },
    i18n: { language: "tr" },
    t: (k: string) => k,
    headers: new Headers(),
    json: async () => opts.body,
    payload,
  };
  return { req, payload };
}

const call = async (req: unknown) => {
  const res = await bulkActionsEndpoint.handler(req as never);
  return { status: res.status, body: (await res.json()) as { results: { id: string; status: string; message: string }[]; counts: Record<string, number> } & { errors?: { message: string }[] } };
};

beforeEach(() => {
  vi.mocked(writeAuditLog).mockClear();
});

describe("POST /api/bulk-actions — input", () => {
  it("requires a logged-in user", async () => {
    const { req } = makeReq({ user: undefined, body: { collection: "pages", action: "publish", ids: [1] } });
    expect((await call(req)).status).toBe(401);
  });

  it("rejects unknown collections, unknown actions, empty and oversized selections", async () => {
    for (const body of [
      { collection: "users", action: "publish", ids: [1] },
      { collection: "pages", action: "approveEverything", ids: [1] },
      { collection: "pages", action: "publish", ids: [] },
      { collection: "pages", action: "publish", ids: [{ id: 1 }] },
      { collection: "pages", action: "publish", ids: Array.from({ length: 101 }, (_, i) => i + 1) },
    ]) {
      const { req, payload } = makeReq({ body });
      const { status } = await call(req);
      expect(status).toBe(400);
      expect(payload.update).not.toHaveBeenCalled();
    }
  });
});

describe("POST /api/bulk-actions — review statement (19.09.2026)", () => {
  it("refuses a bulk publish unless the caller states every record was reviewed", async () => {
    for (const reviewConfirmed of [undefined, false, "true"]) {
      const { req, payload } = makeReq({ body: { collection: "blog-posts", action: "publish", ids: [1], reviewConfirmed } });
      const { status } = await call(req);
      expect(status).toBe(400);
      expect(payload.update).not.toHaveBeenCalled();
    }
  });

  it("does not ask for it on unpublish", async () => {
    const { req } = makeReq({ body: { collection: "blog-posts", action: "unpublish", ids: [1] } });
    expect((await call(req)).status).not.toBe(400);
  });
});

describe("POST /api/bulk-actions — per record", () => {
  it("saves each record as the real user, without overriding access or locks, and keeps going after a failure", async () => {
    const { req, payload } = makeReq({
      body: { collection: "blog-posts", action: "publish", ids: [1, 2, 3, "2"], reviewConfirmed: true },
      docs: { 1: { id: 1, title: "Bir", _status: "draft" }, 2: { id: 2, title: "İki", _status: "draft" }, 3: { id: 3, title: "Üç", _status: "published" } },
      failOn: { 1: Object.assign(new Error("Bu işlemi gerçekleştirmek için izniniz yok."), { status: 403, name: "Forbidden" }) },
    });
    const { status, body } = await call(req);
    expect(status).toBe(200);
    expect(body.results.map((r) => [r.id, r.status])).toEqual([
      ["1", "failed"],
      ["2", "ok"],
      ["3", "skipped"],
    ]);
    expect(body.results[0].message).toBe("Bu işlemi gerçekleştirmek için izniniz yok.");
    expect(body.counts).toEqual({ ok: 1, skipped: 1, failed: 1 });

    expect(payload.update).toHaveBeenCalledTimes(2);
    for (const [args] of payload.update.mock.calls) {
      expect(args).toMatchObject({ collection: "blog-posts", overrideAccess: false, overrideLock: false, draft: false, data: { _status: "published" } });
      // Its own request object: the user, no shared transaction, no ?draft=true.
      expect(args.req).toMatchObject({ user: { id: 1, role: "growth_checker" }, query: {} });
      expect(args.req?.transactionID).toBeUndefined();
    }
    expect(payload.update.mock.calls[0][0].req).not.toBe(payload.update.mock.calls[1][0].req);
    for (const [args] of payload.findByID.mock.calls) expect(args.overrideAccess).toBe(false);
  });

  it("publishes a live record's waiting edit, and names it by its newest title", async () => {
    const { req, payload } = makeReq({
      body: { collection: "blog-posts", action: "publish", ids: [5], reviewConfirmed: true },
      docs: { 5: { id: 5, title: "Eski", _status: "published" } },
      drafts: { 5: { id: 5, title: "Yeni", _status: "draft" } },
    });
    const { body } = await call(req);
    expect(body.results[0]).toMatchObject({ id: "5", title: "Yeni", status: "ok" });
    expect(payload.update).toHaveBeenCalledTimes(1);
  });

  it("files unpublish requests as metadata on a still-live campaign", async () => {
    const { req, payload } = makeReq({
      user: { id: 9, role: "growth_maker" },
      body: { collection: "campaigns", action: "requestUnpublish", ids: [4] },
      docs: { 4: { id: 4, title: "Kampanya", _status: "published", unpublishRequest: "none" } },
    });
    await call(req);
    expect(payload.update.mock.calls[0][0].data).toMatchObject({ _status: "published", unpublishRequest: "pending", unpublishRequestedBy: 9 });
  });

  it("deletes drafts by id through the normal delete", async () => {
    const { req, payload } = makeReq({
      user: { id: 1, role: "new_vertical_maker" },
      body: { collection: "blog-posts", action: "deleteDraft", ids: [1, 2] },
      docs: { 1: { id: 1, title: "Taslak", _status: "draft" }, 2: { id: 2, title: "Canlı", _status: "published" } },
    });
    const { body } = await call(req);
    expect(body.results.map((r) => r.status)).toEqual(["ok", "skipped"]);
    expect(payload.delete).toHaveBeenCalledTimes(1);
    expect(payload.delete.mock.calls[0][0]).toMatchObject({ id: "1", overrideAccess: false, overrideLock: false });
  });

  it("reports a record it can't read as not found, without touching it", async () => {
    const { req, payload } = makeReq({ body: { collection: "blog-posts", action: "unpublish", ids: [404] } });
    const { body } = await call(req);
    expect(body.results[0].status).toBe("failed");
    expect(body.results[0].message).toContain("bulunamadı");
    expect(payload.update).not.toHaveBeenCalled();
  });
});

describe("POST /api/bulk-actions — audit", () => {
  it("writes one bulk summary listing every record, plus a denied entry for each refusal", async () => {
    const { req } = makeReq({
      body: { collection: "blog-posts", action: "publish", ids: [1, 2], reviewConfirmed: true },
      docs: { 1: { id: 1, title: "Bir", _status: "draft" }, 2: { id: 2, title: "İki", _status: "draft" } },
      failOn: { 2: Object.assign(new Error("İzniniz yok."), { status: 403 }) },
    });
    await call(req);
    const entries = vi.mocked(writeAuditLog).mock.calls.map(([, entry]) => entry);
    const denied = entries.filter((e) => e.action === "denied");
    expect(denied).toHaveLength(1);
    expect(denied[0]).toMatchObject({ collectionSlug: "blog-posts", documentId: "2" });
    const summary = entries.find((e) => e.action === "bulk");
    expect(summary?.summary).toBe(
      "blog-posts: toplu yayınlama — 2 kayıt: 1 başarılı, 0 atlandı, 1 başarısız — kullanıcı seçili kayıtların her birini incelediğini ve yayına alınmasını onayladığını beyan etti"
    );
    expect(summary?.changes).toEqual([
      { field: "1 — Bir", before: "taslak", after: "başarılı" },
      { field: "2 — İki", before: "taslak", after: "başarısız: İzniniz yok." },
    ]);
  });
});
