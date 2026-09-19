import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const state = vi.hoisted(() => ({ hits: 0, create: vi.fn(async () => ({})), failQuery: false }));
vi.mock("payload", () => ({
  getPayload: vi.fn(async () => ({
    db: {
      pool: {
        query: vi.fn(async (sql: string) => {
          if (state.failQuery && sql.startsWith("INSERT")) throw new Error("db down");
          return sql.startsWith("INSERT") ? { rows: [{ hits: ++state.hits, reset_in: 50 }] } : { rows: [] };
        }),
      },
    },
    create: state.create,
    logger: { warn: vi.fn() },
  })),
}));

import { withApiGuard } from "@/lib/apiGuard";

const handler = vi.fn(async () => new Response("ok", { status: 200 }));
const guarded = withApiGuard(handler, {} as never);
const req = (path: string, init: RequestInit & { headers?: Record<string, string> } = {}) =>
  new Request(`http://cms.local/api${path}`, { method: "POST", ...init, headers: { "x-forwarded-for": "7.7.7.7", "x-request-id": "req-12345678", ...init.headers } });

describe("withApiGuard", () => {
  beforeEach(() => {
    state.hits = 0;
    state.failQuery = false;
    state.create.mockClear();
    handler.mockClear();
    vi.spyOn(console, "log").mockImplementation(() => {});
  });
  afterEach(() => {
    vi.unstubAllEnvs();
    vi.restoreAllMocks();
  });

  it("lets requests through under the limit and tags the response with the request id", async () => {
    const res = await guarded(req("/users/login"), {});
    expect(res.status).toBe(200);
    expect(res.headers.get("x-request-id")).toBe("req-12345678");
    expect(handler).toHaveBeenCalledTimes(1);
  });

  it("refuses the 11th login from one IP with 429, never calls Payload, audits once", async () => {
    for (let i = 0; i < 10; i++) await guarded(req("/users/login"), {});
    const r11 = await guarded(req("/users/login"), {});
    const r12 = await guarded(req("/users/login"), {});
    expect([r11.status, r12.status]).toEqual([429, 429]);
    expect(handler).toHaveBeenCalledTimes(10);
    expect(state.create).toHaveBeenCalledTimes(1);
    expect(state.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ action: "denied", collectionSlug: "api:login", userEmail: "IP 7.7.7.7" }) }));
  });

  it("does not count the site's own calls", async () => {
    vi.stubEnv("REVALIDATE_SECRET", "rev");
    for (let i = 0; i < 15; i++) await guarded(req("/users/login", { headers: { "x-internal-auth": "rev" } }), {});
    expect(state.hits).toBe(0);
    expect(handler).toHaveBeenCalledTimes(15);
  });

  it("fails open when the counter's database is unavailable", async () => {
    state.failQuery = true;
    const res = await guarded(req("/users/login"), {});
    expect(res.status).toBe(200);
  });

  it("can be switched off with RATE_LIMIT_DISABLED", async () => {
    vi.stubEnv("RATE_LIMIT_DISABLED", "true");
    for (let i = 0; i < 12; i++) expect((await guarded(req("/users/login"), {})).status).toBe(200);
  });
});
