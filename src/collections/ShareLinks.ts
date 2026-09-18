import { createHash, randomBytes } from "node:crypto";
import type { CollectionConfig, Endpoint, PayloadRequest } from "payload";
import { authenticated, hasValidPreviewSecret } from "@/access/authenticated";
import { ROLES } from "@/access/roles";
import { writeAuditLog } from "@/hooks/audit";
import { formatIstanbul } from "@/lib/istanbulTime";

/**
 * 18.09.2026 — paylaşılabilir önizleme linki (product ekibine önerilen 4
 * geliştirmenin 2.si, CLAUDE.md). Lets an editor send someone WITHOUT a CMS
 * account (legal, a marketing manager) a time-limited link that shows ONE
 * campaign / blog post / page exactly as it will look, including unpublished
 * changes.
 *
 * Deliberately NOT the editors' own "Önizle" mechanism: that one turns on
 * Next's draft mode for the whole browser with the shared PREVIEW_SECRET, and
 * its banner embeds that secret in the page. Handing it to an outsider would
 * open every draft on the site. Here:
 * - each link carries its own random token bound to one document; only the
 *   token's SHA-256 is stored, so a database read never yields a working link
 * - links expire (max 7 days) and can be revoked; the plain link is shown once
 * - the site resolves a token server-to-server (PREVIEW_SECRET header) and
 *   renders only that document; it never sets a draft-mode cookie
 * - creating, revoking and every view is written to the audit log
 * - rows can't be created, edited or deleted through the normal API — only
 *   through the endpoints below, which do the checks
 */

export const SHAREABLE_COLLECTIONS = {
  campaigns: { pathPrefix: "/kampanyalar/", label: { tr: "Kampanya", en: "Campaign" } },
  "blog-posts": { pathPrefix: "/blog/", label: { tr: "Blog Yazısı", en: "Blog Post" } },
  pages: { pathPrefix: "/", label: { tr: "Sayfa", en: "Page" } },
} as const;
export type ShareableCollection = keyof typeof SHAREABLE_COLLECTIONS;

export const SHARE_DURATIONS_DAYS = [1, 3, 7] as const;
/** Roles that may revoke anyone's link; everyone may revoke their own. */
const CAN_REVOKE_ANY = new Set<string>([ROLES.NEW_VERTICAL_MAKER, ROLES.NEW_VERTICAL_CHECKER, ROLES.GROWTH_CHECKER]);

export function hashShareToken(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}

export function newShareToken(): string {
  return randomBytes(24).toString("base64url");
}

export function isShareableCollection(value: unknown): value is ShareableCollection {
  return typeof value === "string" && Object.prototype.hasOwnProperty.call(SHAREABLE_COLLECTIONS, value);
}

function siteUrl(): string {
  return (process.env.SITE_URL || "http://localhost:3000").replace(/\/+$/, "");
}

function t(req: PayloadRequest, tr: string, en: string): string {
  return req.i18n?.language === "en" ? en : tr;
}

function fail(message: string, status: number): Response {
  return Response.json({ errors: [{ message }] }, { status });
}

async function readBody(req: PayloadRequest): Promise<Record<string, unknown> | null> {
  try {
    return req.json ? ((await req.json()) as Record<string, unknown>) : {};
  } catch {
    return null;
  }
}

const createEndpoint: Endpoint = {
  path: "/create",
  method: "post",
  handler: async (req) => {
    if (!req.user?.id) return fail(t(req, "Giriş yapmalısınız.", "You must be logged in."), 401);
    const body = await readBody(req);
    if (!body) return fail(t(req, "İstek okunamadı.", "Couldn't read the request."), 400);

    const collection = body.collection;
    const id = body.id;
    const days = Number(body.days);
    const note = typeof body.note === "string" ? body.note.trim().slice(0, 200) : "";
    if (!isShareableCollection(collection) || (typeof id !== "string" && typeof id !== "number")) {
      return fail(t(req, "Bu içerik için önizleme linki oluşturulamaz.", "Preview links can't be made for this content."), 400);
    }
    if (!SHARE_DURATIONS_DAYS.includes(days as (typeof SHARE_DURATIONS_DAYS)[number])) {
      return fail(t(req, "Süre 1, 3 ya da 7 gün olabilir.", "Duration must be 1, 3 or 7 days."), 400);
    }

    // The creator must be able to read the document (drafts included) themselves.
    let doc: { title?: string } | null = null;
    try {
      doc = (await req.payload.findByID({
        collection,
        id,
        draft: true,
        depth: 0,
        overrideAccess: false,
        user: req.user,
      })) as { title?: string };
    } catch {
      doc = null;
    }
    if (!doc) return fail(t(req, "İçerik bulunamadı ya da görme yetkiniz yok.", "Content not found, or you can't view it."), 404);

    const token = newShareToken();
    const expiresAt = new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString();
    const title = doc.title ?? String(id);
    const created = await req.payload.create({
      collection: "share-links",
      overrideAccess: true,
      data: {
        tokenHash: hashShareToken(token),
        targetCollection: collection,
        targetId: String(id),
        targetTitle: title,
        note: note || undefined,
        expiresAt,
        createdBy: req.user.id,
        viewCount: 0,
      },
    });
    await writeAuditLog(req, {
      action: "create",
      collectionSlug: "share-links",
      documentId: String(created.id),
      summary: `share-links: "${title}" için ${days} günlük önizleme linki oluşturuldu (${formatIstanbul(expiresAt)} İstanbul'a kadar)${note ? ` — ${note}` : ""}`,
    });
    return Response.json({ id: created.id, url: `${siteUrl()}/onizleme/${token}`, expiresAt });
  },
};

const revokeEndpoint: Endpoint = {
  path: "/:id/revoke",
  method: "post",
  handler: async (req) => {
    if (!req.user?.id) return fail(t(req, "Giriş yapmalısınız.", "You must be logged in."), 401);
    const id = req.routeParams?.id as string | undefined;
    if (!id) return fail("id", 400);
    type LinkRow = { createdBy?: unknown; revokedAt?: string | null; targetTitle?: string };
    let link: LinkRow | null = null;
    try {
      link = (await req.payload.findByID({ collection: "share-links", id, depth: 0, overrideAccess: true })) as unknown as LinkRow;
    } catch {
      link = null;
    }
    if (!link) return fail(t(req, "Link bulunamadı.", "Link not found."), 404);
    const ownerId = typeof link.createdBy === "object" && link.createdBy ? (link.createdBy as { id: unknown }).id : link.createdBy;
    const role = (req.user as { role?: string }).role ?? "";
    if (String(ownerId) !== String(req.user.id) && !CAN_REVOKE_ANY.has(role)) {
      return fail(t(req, "Bu linki yalnızca oluşturan kişi ya da bir Checker iptal edebilir.", "Only the creator or a Checker can revoke this link."), 403);
    }
    if (!link.revokedAt) {
      await req.payload.update({
        collection: "share-links",
        id,
        overrideAccess: true,
        data: { revokedAt: new Date().toISOString(), revokedBy: req.user.id },
      });
      await writeAuditLog(req, {
        action: "update",
        collectionSlug: "share-links",
        documentId: String(id),
        summary: `share-links: "${link.targetTitle ?? id}" önizleme linki iptal edildi`,
      });
    }
    return Response.json({ ok: true });
  },
};

/**
 * Server-to-server only: the site calls this with PREVIEW_SECRET to turn a
 * token into "which document". A browser can't use it — without the secret it
 * answers 401 whatever the token.
 */
const resolveEndpoint: Endpoint = {
  path: "/resolve/:token",
  method: "get",
  handler: async (req) => {
    if (!hasValidPreviewSecret(req)) return fail("Unauthorized", 401);
    const token = req.routeParams?.token as string | undefined;
    if (!token || token.length < 20 || token.length > 100) return fail("Not found", 404);

    const { docs } = await req.payload.find({
      collection: "share-links",
      where: { tokenHash: { equals: hashShareToken(token) } },
      depth: 0,
      limit: 1,
      overrideAccess: true,
    });
    const link = docs[0] as
      | { id: string | number; targetCollection: string; targetId: string; targetTitle?: string; expiresAt: string; revokedAt?: string | null; viewCount?: number }
      | undefined;
    if (!link) return fail("Not found", 404);
    const state = link.revokedAt ? "revoked" : new Date(link.expiresAt).getTime() <= Date.now() ? "expired" : "active";
    if (state !== "active") return Response.json({ state }, { status: 410 });

    await req.payload.update({
      collection: "share-links",
      id: link.id,
      overrideAccess: true,
      data: { viewCount: (link.viewCount ?? 0) + 1, lastViewedAt: new Date().toISOString() },
    });
    await writeAuditLog(req, {
      action: "update",
      collectionSlug: "share-links",
      documentId: String(link.id),
      summary: `share-links: "${link.targetTitle ?? link.targetId}" önizleme linki açıldı`,
      actorEmail: "önizleme linki ziyaretçisi",
      actorRole: "anonymous",
    });
    return Response.json({
      state,
      collection: link.targetCollection,
      id: link.targetId,
      title: link.targetTitle,
      expiresAt: link.expiresAt,
    });
  },
};

export const ShareLinks: CollectionConfig = {
  slug: "share-links",
  labels: {
    singular: { tr: "Önizleme Linki", en: "Preview Link" },
    plural: { tr: "Önizleme Linkleri", en: "Preview Links" },
  },
  admin: {
    hideAPIURL: true,
    group: { tr: "Sistem", en: "System" },
    useAsTitle: "targetTitle",
    defaultColumns: ["targetTitle", "targetCollection", "note", "expiresAt", "viewCount", "revokedAt", "createdBy"],
    description: {
      tr: "CMS hesabı olmayan kişilerle paylaşılan süreli taslak önizleme linkleri. Linkler içerik ekranlarının yan panelindeki 'Önizleme linki paylaş' bölümünden oluşturulur ve iptal edilir; buradaki liste denetim içindir.",
      en: "Time-limited draft preview links shared with people who have no CMS account. They are created and revoked from the 'Share a preview link' panel on each content screen; this list is for oversight.",
    },
  },
  access: {
    read: authenticated,
    create: () => false,
    update: () => false,
    delete: () => false,
  },
  endpoints: [createEndpoint, revokeEndpoint, resolveEndpoint],
  fields: [
    // Never readable through the API — only the resolve endpoint compares it.
    { name: "tokenHash", type: "text", required: true, unique: true, index: true, access: { read: () => false }, admin: { hidden: true } },
    {
      name: "targetCollection",
      type: "select",
      required: true,
      label: { tr: "İçerik Türü", en: "Content Type" },
      options: Object.entries(SHAREABLE_COLLECTIONS).map(([value, v]) => ({ value, label: v.label })),
    },
    { name: "targetId", type: "text", required: true, index: true, label: { tr: "İçerik ID", en: "Content ID" } },
    { name: "targetTitle", type: "text", label: { tr: "İçerik", en: "Content" } },
    { name: "note", type: "text", label: { tr: "Kime / neden", en: "For whom / why" } },
    {
      name: "expiresAt",
      type: "date",
      required: true,
      label: { tr: "Geçerlilik Sonu", en: "Expires" },
      admin: { date: { pickerAppearance: "dayAndTime", displayFormat: "dd.MM.yyyy HH:mm" } },
    },
    { name: "createdBy", type: "relationship", relationTo: "users", label: { tr: "Oluşturan", en: "Created By" } },
    { name: "viewCount", type: "number", defaultValue: 0, label: { tr: "Görüntülenme", en: "Views" } },
    {
      name: "lastViewedAt",
      type: "date",
      label: { tr: "Son Görüntülenme", en: "Last Viewed" },
      admin: { date: { pickerAppearance: "dayAndTime", displayFormat: "dd.MM.yyyy HH:mm" } },
    },
    {
      name: "revokedAt",
      type: "date",
      label: { tr: "İptal Zamanı", en: "Revoked At" },
      admin: { date: { pickerAppearance: "dayAndTime", displayFormat: "dd.MM.yyyy HH:mm" } },
    },
    { name: "revokedBy", type: "relationship", relationTo: "users", label: { tr: "İptal Eden", en: "Revoked By" } },
  ],
};
