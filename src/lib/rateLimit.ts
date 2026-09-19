import { createHash, timingSafeEqual } from "node:crypto";

/**
 * 19.09.2026 — API rate limiting for the CMS, shared by every pod.
 *
 * Counters live in Postgres (`clover_ops.rate_limit_buckets`, one row per
 * key, fixed 60-second windows) and are advanced with a single atomic
 * INSERT … ON CONFLICT, so two pods behind the HPA see the same count. The
 * `clover_ops` schema is outside `public` on purpose: Payload's dev schema
 * push only manages `public`, so it never tries to drop this table.
 *
 * Fail-open: if the database can't be reached the request is allowed (and
 * logged) — an outage of the counter must not take the CMS down with it.
 * RATE_LIMIT_DISABLED=true turns it off; RATE_LIMIT_MULTIPLIER scales every
 * limit (e.g. 2 for a load test).
 */

export const WINDOW_SECONDS = 60;

export type Policy = { name: string; limit: number; by: "identity" | "ip" };

type Matchable = { method: string; path: string; authenticated: boolean };

/** Most specific first. Paths are relative to /api. */
export function policyFor({ method, path, authenticated }: Matchable): Policy | null {
  const m = method.toUpperCase();
  if (m === "OPTIONS") return null;
  if (/^\/health\//.test(path)) return null;
  if (m === "POST" && /^\/users\/login\/?$/.test(path)) return { name: "login", limit: 10, by: "ip" };
  if (m === "POST" && /^\/users\/(forgot-password|reset-password|unlock)\/?$/.test(path)) return { name: "account", limit: 5, by: "ip" };
  if (/^\/broken-links\/scan\/?$/.test(path)) return { name: "link-scan", limit: 3, by: "identity" };
  if (m === "POST" && /^\/bulk-actions\/?$/.test(path)) return { name: "bulk", limit: 10, by: "identity" };
  if (m === "POST" && /^\/share-links\/create\/?$/.test(path)) return { name: "share-link", limit: 20, by: "identity" };
  if (/^\/graphql\/?$/.test(path)) return { name: "graphql", limit: authenticated ? 120 : 60, by: "identity" };
  if (m === "GET" || m === "HEAD") return { name: "read", limit: authenticated ? 600 : 300, by: "identity" };
  return { name: "write", limit: 120, by: "identity" };
}

/**
 * The caller's IP. X-Forwarded-For is "client, proxy1, proxy2…" and a client
 * can put anything at the FRONT — reading the first entry would let anyone
 * dodge the limit by sending a fake one per request. Each trusted proxy in
 * front of the pod appends what it saw, so the real client is TRUSTED_PROXY_HOPS
 * entries from the END (default 1: the OpenShift router).
 */
export function clientIp(headers: Headers): string {
  const parts = (headers.get("x-forwarded-for") ?? "")
    .split(",")
    .map((p) => p.trim())
    .filter(Boolean);
  const hops = Math.max(1, Number(process.env.TRUSTED_PROXY_HOPS || 1) || 1);
  if (parts.length > 0) return parts[Math.max(0, parts.length - hops)];
  return headers.get("x-real-ip") || "unknown";
}

/** The session token a request carries (cookie or Authorization), if any. */
export function sessionToken(headers: Headers): string | null {
  const auth = headers.get("authorization");
  if (auth && /^(JWT|Bearer)\s+\S+/i.test(auth)) return auth.split(/\s+/)[1];
  const cookie = headers.get("cookie") ?? "";
  const match = /(?:^|;\s*)payload-token=([^;]+)/.exec(cookie);
  return match ? match[1] : null;
}

function safeEqual(a: string, b: string): boolean {
  const ab = Buffer.from(a);
  const bb = Buffer.from(b);
  return ab.length === bb.length && timingSafeEqual(ab, bb);
}

/**
 * The site's own server-to-server calls (every page render reads the CMS from
 * one pod IP) must not share an anonymous visitor's budget. They prove who
 * they are with a secret both sides already hold.
 */
export function isInternalCall(headers: Headers): boolean {
  const internal = headers.get("x-internal-auth");
  const expectedInternal = process.env.REVALIDATE_SECRET;
  if (internal && expectedInternal && safeEqual(internal, expectedInternal)) return true;
  const preview = headers.get("x-preview-secret");
  const expectedPreview = process.env.PREVIEW_SECRET;
  return Boolean(preview && expectedPreview && safeEqual(preview, expectedPreview));
}

export function bucketKey(policy: Policy, headers: Headers): { key: string; subject: string } {
  const ip = clientIp(headers);
  const token = policy.by === "identity" ? sessionToken(headers) : null;
  if (token) {
    const h = createHash("sha256").update(token).digest("hex").slice(0, 24);
    return { key: `${policy.name}:s:${h}`, subject: `oturum ${h.slice(0, 8)}…` };
  }
  return { key: `${policy.name}:ip:${ip}`, subject: `IP ${ip}` };
}

type Pool = {
  query: (sql: string, params?: unknown[]) => Promise<{ rows: Record<string, unknown>[] }>;
};

export const ENSURE_SQL = `CREATE SCHEMA IF NOT EXISTS clover_ops;
CREATE TABLE IF NOT EXISTS clover_ops.rate_limit_buckets (
  key text PRIMARY KEY,
  window_start timestamptz NOT NULL,
  hits integer NOT NULL
);
CREATE INDEX IF NOT EXISTS rate_limit_buckets_window_idx ON clover_ops.rate_limit_buckets (window_start);`;

const HIT_SQL = `INSERT INTO clover_ops.rate_limit_buckets AS b (key, window_start, hits)
VALUES ($1, now(), 1)
ON CONFLICT (key) DO UPDATE SET
  hits = CASE WHEN b.window_start <= now() - make_interval(secs => $2) THEN 1 ELSE b.hits + 1 END,
  window_start = CASE WHEN b.window_start <= now() - make_interval(secs => $2) THEN now() ELSE b.window_start END
RETURNING hits, EXTRACT(EPOCH FROM (b.window_start + make_interval(secs => $2) - now()))::int AS reset_in`;

export type HitResult = { allowed: boolean; hits: number; limit: number; resetIn: number; firstOverflow: boolean };

/** Counts one request against `key`; returns whether it is within `limit`. */
export async function hit(pool: Pool, key: string, limit: number): Promise<HitResult> {
  const { rows } = await pool.query(HIT_SQL, [key, WINDOW_SECONDS]);
  const hits = Number(rows[0]?.hits ?? 1);
  const resetIn = Math.max(1, Number(rows[0]?.reset_in ?? WINDOW_SECONDS));
  // Housekeeping: now and then drop windows long gone, so the table stays small.
  if (Math.random() < 0.01) {
    pool.query("DELETE FROM clover_ops.rate_limit_buckets WHERE window_start < now() - interval '1 hour'").catch(() => {});
  }
  return { allowed: hits <= limit, hits, limit, resetIn, firstOverflow: hits === limit + 1 };
}

export function effectiveLimit(policy: Policy): number {
  const multiplier = Number(process.env.RATE_LIMIT_MULTIPLIER || 1);
  return Math.max(1, Math.round(policy.limit * (Number.isFinite(multiplier) && multiplier > 0 ? multiplier : 1)));
}

export function tooManyResponse(policy: Policy, result: HitResult, requestId: string, english: boolean): Response {
  const message = english
    ? `Too many requests. Please try again in ${result.resetIn} seconds.`
    : `Çok fazla istek gönderildi. Lütfen ${result.resetIn} saniye sonra tekrar deneyin.`;
  return Response.json(
    { errors: [{ message }] },
    {
      status: 429,
      headers: {
        "Retry-After": String(result.resetIn),
        "X-RateLimit-Limit": String(result.limit),
        "X-RateLimit-Remaining": "0",
        "X-RateLimit-Policy": policy.name,
        "x-request-id": requestId,
      },
    }
  );
}
