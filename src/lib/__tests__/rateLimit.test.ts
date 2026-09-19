import { afterEach, describe, expect, it, vi } from "vitest";
import { bucketKey, clientIp, effectiveLimit, hit, isInternalCall, policyFor, sessionToken, tooManyResponse } from "@/lib/rateLimit";

const h = (init: Record<string, string>) => new Headers(init);

describe("policyFor", () => {
  it("picks the most specific policy", () => {
    expect(policyFor({ method: "POST", path: "/users/login", authenticated: false })).toMatchObject({ name: "login", limit: 10, by: "ip" });
    expect(policyFor({ method: "GET", path: "/broken-links/scan", authenticated: true })?.name).toBe("link-scan");
    expect(policyFor({ method: "POST", path: "/bulk-actions", authenticated: true })?.name).toBe("bulk");
    expect(policyFor({ method: "POST", path: "/share-links/create", authenticated: true })?.name).toBe("share-link");
    expect(policyFor({ method: "POST", path: "/graphql", authenticated: false })).toMatchObject({ name: "graphql", limit: 60 });
    expect(policyFor({ method: "GET", path: "/campaigns", authenticated: false })).toMatchObject({ name: "read", limit: 300 });
    expect(policyFor({ method: "GET", path: "/campaigns", authenticated: true })).toMatchObject({ name: "read", limit: 600 });
    expect(policyFor({ method: "PATCH", path: "/campaigns/1", authenticated: true })).toMatchObject({ name: "write", limit: 120 });
  });

  it("never limits health probes or CORS preflight", () => {
    expect(policyFor({ method: "GET", path: "/health/readiness", authenticated: false })).toBeNull();
    expect(policyFor({ method: "OPTIONS", path: "/campaigns", authenticated: false })).toBeNull();
  });
});

describe("clientIp", () => {
  afterEach(() => vi.unstubAllEnvs());
  it("uses the entry the trusted router appended, not what the client wrote first", () => {
    // attacker sends "X-Forwarded-For: 1.2.3.4", the router appends the real address
    expect(clientIp(h({ "x-forwarded-for": "1.2.3.4, 85.10.20.30" }))).toBe("85.10.20.30");
    expect(clientIp(h({ "x-forwarded-for": "85.10.20.30" }))).toBe("85.10.20.30");
    vi.stubEnv("TRUSTED_PROXY_HOPS", "2");
    expect(clientIp(h({ "x-forwarded-for": "fake, 85.10.20.30, 10.0.0.5" }))).toBe("85.10.20.30");
    expect(clientIp(h({}))).toBe("unknown");
  });
});

describe("identity and internal calls", () => {
  afterEach(() => vi.unstubAllEnvs());
  it("reads the session from the Payload cookie or Authorization header", () => {
    expect(sessionToken(h({ cookie: "a=1; payload-token=abc.def; b=2" }))).toBe("abc.def");
    expect(sessionToken(h({ authorization: "JWT tok" }))).toBe("tok");
    expect(sessionToken(h({}))).toBeNull();
  });

  it("keys a logged-in session by a hash of its token (never the token), others by IP", () => {
    const policy = { name: "read", limit: 600, by: "identity" as const };
    const s = bucketKey(policy, h({ cookie: "payload-token=secret-token", "x-forwarded-for": "9.9.9.9" }));
    expect(s.key).toMatch(/^read:s:[0-9a-f]{24}$/);
    expect(s.key).not.toContain("secret-token");
    expect(bucketKey(policy, h({ "x-forwarded-for": "9.9.9.9" })).key).toBe("read:ip:9.9.9.9");
    // login is always per IP, even with a cookie
    expect(bucketKey({ name: "login", limit: 10, by: "ip" }, h({ cookie: "payload-token=x", "x-forwarded-for": "9.9.9.9" })).key).toBe("login:ip:9.9.9.9");
  });

  it("exempts the site's own server calls only with the right secret", () => {
    vi.stubEnv("REVALIDATE_SECRET", "rev-secret");
    vi.stubEnv("PREVIEW_SECRET", "prev-secret");
    expect(isInternalCall(h({ "x-internal-auth": "rev-secret" }))).toBe(true);
    expect(isInternalCall(h({ "x-preview-secret": "prev-secret" }))).toBe(true);
    expect(isInternalCall(h({ "x-internal-auth": "guess" }))).toBe(false);
    expect(isInternalCall(h({}))).toBe(false);
  });
});

describe("hit (shared Postgres counter)", () => {
  it("allows up to the limit and flags the first overflow once", async () => {
    let n = 0;
    const pool = { query: vi.fn(async (sql: string, ...rest: unknown[]) => (void rest, sql.startsWith("INSERT") ? { rows: [{ hits: ++n, reset_in: 42 }] } : { rows: [] })) };
    const results = [];
    for (let i = 0; i < 4; i++) results.push(await hit(pool as never, "k", 2));
    expect(results.map((r) => r.allowed)).toEqual([true, true, false, false]);
    expect(results.map((r) => r.firstOverflow)).toEqual([false, false, true, false]);
    expect(results[2].resetIn).toBe(42);
    expect((pool.query.mock.calls[0] as unknown[])[1]).toEqual(["k", 60]);
  });
});

describe("responses and tuning", () => {
  afterEach(() => vi.unstubAllEnvs());
  it("answers 429 in Turkish with Retry-After", async () => {
    const res = tooManyResponse({ name: "login", limit: 10, by: "ip" }, { allowed: false, hits: 11, limit: 10, resetIn: 30, firstOverflow: true }, "rid", false);
    expect(res.status).toBe(429);
    expect(res.headers.get("Retry-After")).toBe("30");
    expect(res.headers.get("X-RateLimit-Policy")).toBe("login");
    expect(((await res.json()) as { errors: { message: string }[] }).errors[0].message).toContain("30 saniye");
  });
  it("scales limits with RATE_LIMIT_MULTIPLIER", () => {
    vi.stubEnv("RATE_LIMIT_MULTIPLIER", "2");
    expect(effectiveLimit({ name: "read", limit: 300, by: "identity" })).toBe(600);
    vi.stubEnv("RATE_LIMIT_MULTIPLIER", "nonsense");
    expect(effectiveLimit({ name: "read", limit: 300, by: "identity" })).toBe(300);
  });
});
