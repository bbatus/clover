import type { CollectionConfig, Endpoint } from "payload";
import { authenticated, hasValidPreviewSecret } from "@/access/authenticated";
import { writeAuditLog } from "@/hooks/audit";

/**
 * Kırık link raporu (18.09.2026) — the "404 alan adresler" half of
 * /admin/broken-links. The site's 404 page reports the address a visitor
 * asked for and the page that sent them there (vodafonepaycomtr-site
 * `api/not-found` → here, server-to-server with PREVIEW_SECRET). One row per
 * address with a counter, so a broken link on a live page shows up as a
 * growing number with its referring page next to it.
 *
 * Guarded against noise and abuse: only the site can write (secret), paths
 * are normalised and capped, scanner probes (file extensions, wp-*, .env…)
 * are dropped on the site side AND here, and once MAX_ROWS distinct addresses
 * exist no new ones are added (existing counters still grow).
 */

export const MAX_ROWS = 5000;
const MAX_PATH = 300;

/** Paths worth recording: site pages, not asset/scanner noise. */
export function normaliseNotFoundPath(raw: unknown): string | null {
  if (typeof raw !== "string") return null;
  const path = raw.split(/[?#]/)[0].trim();
  if (!path.startsWith("/") || path.startsWith("//") || path.length > MAX_PATH) return null;
  if (/^\/(_next|api|admin)(\/|$)/.test(path)) return null;
  if (/\.[a-z0-9]{1,5}$/i.test(path)) return null; // .php, .env, .png, .xml …
  if (/(^|\/)(wp-|wordpress|cgi-bin|\.git|\.well-known)/i.test(path)) return null;
  const cleaned = path.length > 1 ? path.replace(/\/+$/, "") : path;
  try {
    return decodeURIComponent(cleaned);
  } catch {
    return cleaned;
  }
}

/**
 * The referring page as origin + path only. 18.09.2026 review: the raw
 * Referer was stored verbatim, so a visitor arriving from another site kept
 * that site's query string here (e-mail campaign ids, search terms, at worst
 * someone's e-mail address or a token), shown to every CMS user. Only http(s)
 * URLs are kept; anything else is dropped rather than stored as text.
 */
export function referrerPath(raw: unknown): string | undefined {
  if (typeof raw !== "string" || !raw) return undefined;
  try {
    const u = new URL(raw);
    if (u.protocol !== "http:" && u.protocol !== "https:") return undefined;
    return `${u.origin}${u.pathname}`.slice(0, 500);
  } catch {
    return undefined;
  }
}

const recordEndpoint: Endpoint = {
  path: "/record",
  method: "post",
  handler: async (req) => {
    if (!hasValidPreviewSecret(req)) return Response.json({ error: "Unauthorized" }, { status: 401 });
    let body: Record<string, unknown> = {};
    try {
      if (req.json) body = await req.json();
    } catch {
      return Response.json({ error: "Bad body" }, { status: 400 });
    }
    const path = normaliseNotFoundPath(body.path);
    if (!path) return new Response(null, { status: 204 });
    const referrer = referrerPath(body.referrer);
    const now = new Date().toISOString();

    const { docs } = await req.payload.find({
      collection: "not-found-hits",
      where: { path: { equals: path } },
      limit: 1,
      depth: 0,
      overrideAccess: true,
    });
    const existing = docs[0] as { id: string | number; count?: number } | undefined;
    if (existing) {
      await req.payload.update({
        collection: "not-found-hits",
        id: existing.id,
        overrideAccess: true,
        data: { count: (existing.count ?? 0) + 1, lastSeenAt: now, ...(referrer ? { lastReferrer: referrer } : {}) },
      });
      return new Response(null, { status: 204 });
    }
    const { totalDocs } = await req.payload.count({ collection: "not-found-hits", overrideAccess: true });
    if (totalDocs >= MAX_ROWS) {
      // 18.09.2026 review: the cap used to be permanent — once a scanner (or
      // plain time) filled it with one-off addresses, no new 404 was ever
      // recorded again and nothing could delete rows. Now the stalest
      // single-hit, not-ignored address makes room; addresses seen more than
      // once, and ones an editor marked, are never evicted this way.
      const { docs: stale } = await req.payload.find({
        collection: "not-found-hits",
        where: { and: [{ count: { less_than_equal: 1 } }, { ignored: { not_equals: true } }] },
        sort: "lastSeenAt",
        limit: 1,
        depth: 0,
        overrideAccess: true,
      });
      if (!stale[0]) return new Response(null, { status: 204 });
      await req.payload.delete({ collection: "not-found-hits", id: (stale[0] as { id: string | number }).id, overrideAccess: true });
    }
    try {
      await req.payload.create({
        collection: "not-found-hits",
        overrideAccess: true,
        data: { path, count: 1, firstSeenAt: now, lastSeenAt: now, lastReferrer: referrer },
      });
    } catch {
      // Two simultaneous first hits on the same path: the unique index kept one row.
    }
    return new Response(null, { status: 204 });
  },
};

/** "Yok say" — hide an address that is expected to 404 (or has been fixed). Reversible. */
const ignoreEndpoint: Endpoint = {
  path: "/:id/ignore",
  method: "post",
  handler: async (req) => {
    if (!req.user?.id) return Response.json({ errors: [{ message: "Giriş yapmalısınız." }] }, { status: 401 });
    const id = req.routeParams?.id as string | undefined;
    let ignored = true;
    try {
      if (req.json) ignored = ((await req.json()) as { ignored?: boolean }).ignored !== false;
    } catch {
      ignored = true;
    }
    if (!id) return Response.json({ errors: [{ message: "id" }] }, { status: 400 });
    const row = (await req.payload.update({ collection: "not-found-hits", id, overrideAccess: true, data: { ignored } })) as { path?: string };
    await writeAuditLog(req, {
      action: "update",
      collectionSlug: "not-found-hits",
      documentId: String(id),
      summary: `not-found-hits: "${row.path ?? id}" ${ignored ? "yok sayıldı" : "yeniden listeye alındı"}`,
    });
    return Response.json({ ok: true });
  },
};

export const NotFoundHits: CollectionConfig = {
  slug: "not-found-hits",
  labels: {
    singular: { tr: "404 Kaydı", en: "404 Hit" },
    plural: { tr: "404 Kayıtları", en: "404 Hits" },
  },
  admin: {
    hidden: true, // shown inside Kırık Linkler (/admin/broken-links)
    useAsTitle: "path",
    defaultColumns: ["path", "count", "lastSeenAt", "lastReferrer", "ignored"],
  },
  access: {
    read: authenticated,
    create: () => false,
    update: () => false,
    delete: () => false,
  },
  endpoints: [recordEndpoint, ignoreEndpoint],
  fields: [
    { name: "path", type: "text", required: true, unique: true, index: true, label: { tr: "Adres", en: "Address" } },
    { name: "count", type: "number", defaultValue: 1, label: { tr: "Sayı", en: "Count" } },
    { name: "firstSeenAt", type: "date", label: { tr: "İlk Görülme", en: "First Seen" } },
    { name: "lastSeenAt", type: "date", index: true, label: { tr: "Son Görülme", en: "Last Seen" } },
    { name: "lastReferrer", type: "text", label: { tr: "Geldiği Sayfa", en: "Referring Page" } },
    { name: "ignored", type: "checkbox", defaultValue: false, label: { tr: "Yok Sayıldı", en: "Ignored" } },
  ],
};
