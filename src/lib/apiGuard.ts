import { getPayload, type SanitizedConfig } from "payload";
import {
  bucketKey,
  clientIp,
  effectiveLimit,
  ENSURE_SQL,
  hit,
  isInternalCall,
  policyFor,
  sessionToken,
  tooManyResponse,
} from "@/lib/rateLimit";

/**
 * 19.09.2026 — wraps Payload's REST and GraphQL route handlers
 * (app/(payload)/api/…/route.ts) with:
 * 1. the shared rate limit (lib/rateLimit.ts), 429 + audit row on overflow;
 * 2. a JSON access log line carrying the request id set in src/proxy.ts —
 *    written for writes, errors, rate-limit refusals and slow requests (> 1 s);
 *    plain fast reads are skipped to keep the log readable. API_ACCESS_LOG=all
 *    logs every request.
 */

/** Generic over the handler's own context type (REST: { params }, GraphQL: none). */
type Handler<C> = (request: Request, context: C) => Promise<Response> | Response;
type Pool = { query: (sql: string, params?: unknown[]) => Promise<{ rows: Record<string, unknown>[] }> };

let ensured: Promise<boolean> | null = null;

async function poolFor(config: Promise<SanitizedConfig> | SanitizedConfig): Promise<{ pool: Pool | null; payload: Awaited<ReturnType<typeof getPayload>> }> {
  const payload = await getPayload({ config });
  const pool = (payload.db as unknown as { pool?: Pool }).pool ?? null;
  if (pool && !ensured) {
    ensured = pool
      .query(ENSURE_SQL)
      .then(() => true)
      .catch((err) => {
        payload.logger.warn(`[rate-limit] could not create clover_ops.rate_limit_buckets (${err instanceof Error ? err.message : err}); limits are OFF until it exists — run the migration`);
        ensured = null;
        return false;
      });
  }
  return { pool, payload };
}

function log(line: Record<string, unknown>) {
  console.log(JSON.stringify({ time: new Date().toISOString(), service: "clover", ...line }));
}

export function withApiGuard<C>(handler: Handler<C>, config: Promise<SanitizedConfig> | SanitizedConfig, basePath = "/api"): Handler<C> {
  return async (request, context) => {
    const started = Date.now();
    const url = new URL(request.url);
    const path = url.pathname.startsWith(basePath) ? url.pathname.slice(basePath.length) || "/" : url.pathname;
    const requestId = request.headers.get("x-request-id") ?? crypto.randomUUID();
    const method = request.method.toUpperCase();
    const english = (request.headers.get("accept-language") ?? "").toLowerCase().startsWith("en");

    let policyName: string | undefined;
    if (process.env.RATE_LIMIT_DISABLED !== "true" && !isInternalCall(request.headers)) {
      const policy = policyFor({ method, path, authenticated: Boolean(sessionToken(request.headers)) });
      if (policy) {
        policyName = policy.name;
        try {
          const { pool, payload } = await poolFor(config);
          if (pool && (await ensured)) {
            const { key, subject } = bucketKey(policy, request.headers);
            const result = await hit(pool, key, effectiveLimit(policy));
            if (!result.allowed) {
              if (result.firstOverflow) {
                // Once per key per window, so a flood doesn't flood the audit log too.
                payload
                  .create({
                    collection: "audit-logs",
                    overrideAccess: true,
                    data: {
                      userEmail: subject,
                      action: "denied",
                      collectionSlug: `api:${policy.name}`,
                      summary: `API istek sınırı aşıldı (${policy.name}: ${result.limit} istek/dk) — ${method} ${basePath}${path}`,
                      ip: clientIp(request.headers),
                      userAgent: request.headers.get("user-agent")?.slice(0, 300) ?? undefined,
                    },
                  })
                  .catch(() => {});
              }
              log({ level: "warn", msg: "rate-limited", reqId: requestId, method, path: `${basePath}${path}`, policy: policy.name, subject, hits: result.hits, limit: result.limit });
              return tooManyResponse(policy, result, requestId, english);
            }
          }
        } catch (err) {
          log({ level: "error", msg: "rate-limit check failed, allowing request", reqId: requestId, error: err instanceof Error ? err.message : String(err) });
        }
      }
    }

    let response: Response;
    try {
      response = await handler(request, context);
    } catch (err) {
      log({ level: "error", msg: "api handler threw", reqId: requestId, method, path: `${basePath}${path}`, error: err instanceof Error ? err.message : String(err) });
      throw err;
    }
    const ms = Date.now() - started;
    const isRead = method === "GET" || method === "HEAD";
    if (process.env.API_ACCESS_LOG === "all" || !isRead || response.status >= 400 || ms > 1000) {
      log({ level: response.status >= 500 ? "error" : "info", msg: "api", reqId: requestId, method, path: `${basePath}${path}`, status: response.status, ms, policy: policyName });
    }
    try {
      response.headers.set("x-request-id", requestId);
    } catch {
      // Some responses have immutable headers; the proxy already set it.
    }
    return response;
  };
}
