import type { Endpoint } from "payload";

/**
 * OCP health probes — see docs/OCP-DEVOPS-RUNBOOK.md §6.2 (this project had
 * none; `devops-proje-sablonu`'s deployment.yaml assumes Spring's
 * `/actuator/health/{liveness,readiness}`, which doesn't exist in a Next.js
 * app). Registered as top-level Payload endpoints (not plain Next.js API
 * routes) so the handler gets a real, already-initialized `req.payload` for
 * free — the same pattern `auditExportEndpoint` already uses
 * (`hooks/audit.ts`) — rather than a second, manual `getPayload({config})`
 * bootstrap just for this.
 *
 * Liveness: is the process itself alive — no dependency checks, must answer
 * fast even if the DB is down (a DB outage should make readiness fail, not
 * get the pod killed and restarted, which would make the outage worse).
 *
 * Readiness: can this pod actually serve traffic — the one real check that
 * matters for a CMS is the database, since every admin-panel operation and
 * every one of the site's own reads depends on it. `find({limit: 0})` is a
 * real round trip through Payload's own DB adapter (not a raw `pg` query —
 * `pg` is only a transitive dependency of @payloadcms/db-postgres, not
 * something this app should import directly) — cheap, but a genuine query.
 */
export const livenessEndpoint: Endpoint = {
  path: "/health/liveness",
  method: "get",
  handler: async () => Response.json({ status: "ok" }),
};

export const readinessEndpoint: Endpoint = {
  path: "/health/readiness",
  method: "get",
  handler: async (req) => {
    try {
      await req.payload.find({ collection: "users", limit: 0, depth: 0, overrideAccess: true });
      return Response.json({ status: "ok", db: "ok" });
    } catch (err) {
      const message = err instanceof Error ? err.message : "unknown error";
      return Response.json({ status: "unavailable", db: "unreachable", error: message }, { status: 503 });
    }
  },
};
