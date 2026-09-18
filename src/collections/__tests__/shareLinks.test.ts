import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { hashShareToken, newShareToken, ShareLinks } from "@/collections/ShareLinks";

vi.mock("@/hooks/audit", () => ({ writeAuditLog: vi.fn() }));

type TestEndpoint = { path: string; handler: (req: never) => Promise<Response> };
const endpoint = (path: string): TestEndpoint => (ShareLinks.endpoints as unknown as TestEndpoint[]).find((e) => e.path === path)!;

function req(overrides: Record<string, unknown> = {}) {
  return {
    user: { id: 1, role: "growth_maker" },
    i18n: { language: "tr" },
    headers: new Headers(),
    json: async () => ({}),
    routeParams: {},
    payload: { findByID: vi.fn(), create: vi.fn(), update: vi.fn(), find: vi.fn() },
    ...overrides,
  } as never;
}

describe("share tokens", () => {
  it("are long, URL-safe and stored only as a SHA-256 hash", () => {
    const token = newShareToken();
    expect(token).toMatch(/^[A-Za-z0-9_-]{32}$/);
    expect(newShareToken()).not.toBe(token);
    expect(hashShareToken(token)).toMatch(/^[0-9a-f]{64}$/);
    expect(hashShareToken(token)).not.toContain(token);
  });

  it("cannot be created, edited or deleted through the normal API", () => {
    const access = ShareLinks.access!;
    expect((access.create as () => boolean)()).toBe(false);
    expect((access.update as () => boolean)()).toBe(false);
    expect((access.delete as () => boolean)()).toBe(false);
    const tokenField = ShareLinks.fields.find((f) => "name" in f && f.name === "tokenHash") as { access?: { read?: () => boolean } };
    expect(tokenField.access?.read?.()).toBe(false);
  });
});

describe("POST /share-links/create", () => {
  it("requires a logged-in user", async () => {
    const res = await endpoint("/create").handler(req({ user: undefined }));
    expect(res.status).toBe(401);
  });

  it("rejects durations other than 1, 3 or 7 days and non-shareable collections", async () => {
    const bad = await endpoint("/create").handler(req({ json: async () => ({ collection: "campaigns", id: 1, days: 30 }) }));
    expect(bad.status).toBe(400);
    const users = await endpoint("/create").handler(req({ json: async () => ({ collection: "users", id: 1, days: 1 }) }));
    expect(users.status).toBe(400);
  });

  it("checks the creator can read the document themselves (access not overridden)", async () => {
    const r = req({ json: async () => ({ collection: "campaigns", id: 5, days: 3 }) }) as unknown as { payload: { findByID: ReturnType<typeof vi.fn> } };
    r.payload.findByID.mockRejectedValue(new Error("Forbidden"));
    const res = await endpoint("/create").handler(r as never);
    expect(res.status).toBe(404);
    expect(r.payload.findByID).toHaveBeenCalledWith(expect.objectContaining({ collection: "campaigns", id: 5, draft: true, overrideAccess: false }));
  });

  it("stores the hash, never the token, and returns the link once", async () => {
    const r = req({ json: async () => ({ collection: "blog-posts", id: 4, days: 7, note: "Hukuk" }) }) as unknown as {
      payload: { findByID: ReturnType<typeof vi.fn>; create: ReturnType<typeof vi.fn> };
    };
    r.payload.findByID.mockResolvedValue({ title: "Yazı" });
    r.payload.create.mockResolvedValue({ id: 9 });
    const res = await endpoint("/create").handler(r as never);
    const body = (await res.json()) as { url: string; expiresAt: string };
    const token = body.url.split("/onizleme/")[1];
    const data = r.payload.create.mock.calls[0][0].data;
    expect(data.tokenHash).toBe(hashShareToken(token));
    expect(JSON.stringify(data)).not.toContain(token);
    expect(data).toMatchObject({ targetCollection: "blog-posts", targetId: "4", targetTitle: "Yazı", note: "Hukuk", createdBy: 1 });
    const days = (new Date(body.expiresAt).getTime() - Date.now()) / 86_400_000;
    expect(days).toBeGreaterThan(6.99);
    expect(days).toBeLessThanOrEqual(7);
  });
});

describe("POST /share-links/:id/revoke", () => {
  it("lets the creator revoke, refuses another Growth Maker, allows a Checker", async () => {
    const make = (userId: number, role: string) => {
      const r = req({ user: { id: userId, role }, routeParams: { id: "3" } }) as unknown as {
        payload: { findByID: ReturnType<typeof vi.fn>; update: ReturnType<typeof vi.fn> };
      };
      r.payload.findByID.mockResolvedValue({ createdBy: 7, revokedAt: null, targetTitle: "X" });
      return r;
    };
    const own = make(7, "growth_maker");
    expect((await endpoint("/:id/revoke").handler(own as never)).status).toBe(200);
    expect(own.payload.update).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ revokedBy: 7 }) }));

    const other = make(8, "growth_maker");
    expect((await endpoint("/:id/revoke").handler(other as never)).status).toBe(403);
    expect(other.payload.update).not.toHaveBeenCalled();

    expect((await endpoint("/:id/revoke").handler(make(8, "growth_checker") as never)).status).toBe(200);
  });
});

describe("GET /share-links/resolve/:token", () => {
  const OLD = process.env.PREVIEW_SECRET;
  beforeEach(() => {
    process.env.PREVIEW_SECRET = "s3cret-value";
  });
  afterEach(() => {
    process.env.PREVIEW_SECRET = OLD;
  });
  const token = "A".repeat(32);
  const withSecret = (row: unknown) => {
    const r = req({ headers: new Headers({ "x-preview-secret": "s3cret-value" }), routeParams: { token } }) as unknown as {
      payload: { find: ReturnType<typeof vi.fn>; update: ReturnType<typeof vi.fn> };
    };
    r.payload.find.mockResolvedValue({ docs: row ? [row] : [] });
    return r;
  };

  it("answers 401 without the server-to-server secret", async () => {
    const res = await endpoint("/resolve/:token").handler(req({ routeParams: { token } }));
    expect(res.status).toBe(401);
  });

  it("looks the token up by its hash and counts the view", async () => {
    const r = withSecret({ id: 2, targetCollection: "campaigns", targetId: "27", targetTitle: "Ekim", expiresAt: "2999-01-01T00:00:00Z", viewCount: 4 });
    const res = await endpoint("/resolve/:token").handler(r as never);
    expect(res.status).toBe(200);
    expect(await res.json()).toMatchObject({ state: "active", collection: "campaigns", id: "27" });
    expect(r.payload.find.mock.calls[0][0].where).toEqual({ tokenHash: { equals: hashShareToken(token) } });
    expect(r.payload.update).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ viewCount: 5 }) }));
  });

  it("returns 410 with the reason for an expired or revoked link, without counting it", async () => {
    const expired = withSecret({ id: 2, targetCollection: "campaigns", targetId: "1", expiresAt: "2000-01-01T00:00:00Z" });
    const r1 = await endpoint("/resolve/:token").handler(expired as never);
    expect(r1.status).toBe(410);
    expect(await r1.json()).toEqual({ state: "expired" });
    expect(expired.payload.update).not.toHaveBeenCalled();

    const revoked = withSecret({ id: 2, targetCollection: "campaigns", targetId: "1", expiresAt: "2999-01-01T00:00:00Z", revokedAt: "2026-01-01T00:00:00Z" });
    expect(await (await endpoint("/resolve/:token").handler(revoked as never)).json()).toEqual({ state: "revoked" });
  });

  it("404s an unknown token", async () => {
    expect((await endpoint("/resolve/:token").handler(withSecret(null) as never)).status).toBe(404);
  });
});
