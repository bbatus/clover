import { parse } from "qs-esm";
import { getPayload, type CollectionSlug, type SanitizedConfig, type Where } from "payload";
import { DRAFT_ENABLED_COLLECTIONS } from "@/lib/collectionLabels";

/**
 * 19.09.2026 — geri dönüşüm kutusu, the two requests Payload's trash screens
 * send in bulk form: "Geri Yükle" (restore, one record or many) is a
 * `PATCH /api/<slug>?trash=true&where=…` with `{ deletedAt: null }`, and
 * "Çöpü Boşalt" / permanent delete from the Çöp list is a
 * `DELETE /api/<slug>?trash=true&where=…`.
 *
 * Payload refuses both on our draft-enabled collections before any hook
 * runs: they carry `disableBulkEdit`/`disableBulkDelete` (18.09.2026, so its
 * own bulk Edit/Publish/Delete — which know nothing of maker→checker — never
 * appear). Turning those flags off would bring the unwanted buttons back, so
 * instead these two request shapes, and only these, are carried out here
 * record by record through the Local API as the signed-in user: access,
 * the maker→checker hooks, the trash rules (access/trash.ts), revalidation
 * and the audit log all run exactly as for a single-record request.
 *
 * Restores always come back as drafts: Payload's "restore as published"
 * checkbox is hidden (custom.css) and the request refused here, so a
 * restored record goes live only through the normal approval.
 */

export type TrashBulkRequest =
  | { kind: "restore"; collection: CollectionSlug; where: Where }
  | { kind: "purge"; collection: CollectionSlug; where: Where }
  | { kind: "restore-published"; collection: CollectionSlug };

const MAX_RECORDS = 500;

/** Which trash request this is, if any — pure, so it is unit-tested without a server. */
export function classifyTrashBulk(method: string, url: URL, body: unknown = null): TrashBulkRequest | null {
  const match = /^\/api\/([a-z0-9-]+)\/?$/.exec(url.pathname);
  if (!match || !DRAFT_ENABLED_COLLECTIONS.has(match[1])) return null;
  const collection = match[1] as CollectionSlug;
  const query = parse(url.search.replace(/^\?/, ""), { depth: 10 }) as { trash?: string; where?: Where };
  if (!query.where || typeof query.where !== "object") return null;

  if (method === "DELETE") {
    return query.trash === "true" ? { kind: "purge", collection, where: query.where } : null;
  }
  if (method === "PATCH" && body && typeof body === "object") {
    const data = body as Record<string, unknown>;
    const keys = Object.keys(data);
    if (!("deletedAt" in data) || data.deletedAt !== null || keys.some((k) => k !== "deletedAt" && k !== "_status")) return null;
    if (data._status === "published") return { kind: "restore-published", collection };
    return { kind: "restore", collection, where: query.where };
  }
  return null;
}

type Result = { status: number; body: Record<string, unknown> };

export async function runTrashBulk(config: Promise<SanitizedConfig> | SanitizedConfig, request: TrashBulkRequest, headers: Headers): Promise<Result> {
  const english = (headers.get("accept-language") ?? "").toLowerCase().startsWith("en");
  if (request.kind === "restore-published") {
    return {
      status: 403,
      body: {
        errors: [
          {
            message: english
              ? "A restored record comes back as a draft; it goes live through the normal approval."
              : "Geri yüklenen kayıt taslak olarak döner; yayına onay akışıyla çıkar.",
          },
        ],
      },
    };
  }

  const payload = await getPayload({ config });
  const { user } = await payload.auth({ headers });
  if (!user) return { status: 401, body: { errors: [{ message: english ? "Please sign in." : "Giriş yapmalısınız." }] } };

  // Only records that really are in the trash, whatever the list filter says.
  const where: Where = { and: [request.where, { deletedAt: { exists: true } }] };
  const found = await payload.find({
    collection: request.collection,
    where,
    trash: true,
    overrideAccess: false,
    user,
    depth: 0,
    limit: MAX_RECORDS,
    pagination: false,
  });

  const docs: unknown[] = [];
  const errors: { id: string | number; message: string }[] = [];
  for (const doc of found.docs as { id: string | number }[]) {
    try {
      if (request.kind === "restore") {
        docs.push(
          await payload.update({
            collection: request.collection,
            id: doc.id,
            data: { deletedAt: null, _status: "draft" } as never,
            trash: true,
            overrideAccess: false,
            user,
            depth: 0,
          })
        );
      } else {
        docs.push(await payload.delete({ collection: request.collection, id: doc.id, trash: true, overrideAccess: false, user, depth: 0 }));
      }
    } catch (err) {
      errors.push({ id: doc.id, message: err instanceof Error ? err.message : String(err) });
    }
  }

  const verb = request.kind === "restore" ? (english ? "restored" : "geri yüklendi") : english ? "deleted permanently" : "kalıcı olarak silindi";
  const message = english ? `${docs.length} record(s) ${verb}.` : `${docs.length} kayıt ${verb}.`;
  if (docs.length === 0 && errors.length > 0) {
    return { status: 403, body: { docs, errors: errors.map((e) => ({ message: e.message, id: e.id })), message: errors[0].message } };
  }
  return { status: 200, body: { docs, errors, message } };
}

/** Wraps a Payload REST handler so the two trash requests above are carried out here and everything else passes through untouched. */
export function withTrashBulk<C>(
  handler: (req: Request, ctx: C) => Promise<Response>,
  config: Promise<SanitizedConfig> | SanitizedConfig
): (req: Request, ctx: C) => Promise<Response> {
  return async (req, ctx) => {
    if (req.method !== "PATCH" && req.method !== "DELETE") return handler(req, ctx);
    const url = new URL(req.url);
    let body: unknown = null;
    if (req.method === "PATCH") {
      body = await req
        .clone()
        .json()
        .catch(() => null);
    }
    const request = classifyTrashBulk(req.method, url, body);
    if (!request) return handler(req, ctx);
    const result = await runTrashBulk(config, request, req.headers);
    return Response.json(result.body, { status: result.status });
  };
}
