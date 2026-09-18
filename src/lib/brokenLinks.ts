import type { Endpoint, Payload } from "payload";
import { extractLinks, readableField, type FoundLink } from "@/lib/linkScan";

/**
 * Kırık link raporu (18.09.2026, product ekibine önerilen 4 geliştirmenin
 * 3.sü) — the "İçerikteki kırık linkler" half of /admin/broken-links.
 *
 * Collects every link from what visitors can actually see (published
 * versions only) and asks the SITE itself whether each internal address
 * resolves — the site's real routing, not a re-implementation of it, so a
 * deleted campaign, an archived blog post or a mistyped path shows up exactly
 * as a visitor would hit it. The request goes to the site's in-cluster address
 * (the origin of SITE_REVALIDATE_URL on OpenShift), never through the public
 * route. External links are only checked when asked: the CMS pod may have no
 * internet egress, and every failure there would be a false alarm.
 */

type Source = { collection: string; titleField: string; drafts: boolean };

const SOURCES: Source[] = [
  { collection: "nav-links", titleField: "label", drafts: true },
  { collection: "campaigns", titleField: "title", drafts: true },
  { collection: "blog-posts", titleField: "title", drafts: true },
  { collection: "pages", titleField: "title", drafts: true },
  { collection: "faq-items", titleField: "question", drafts: true },
  { collection: "announcements", titleField: "title", drafts: true },
  { collection: "legal-pages", titleField: "title", drafts: true },
];
const GLOBAL_SOURCES = [
  { slug: "footer-settings", title: { tr: "Footer Yönetimi", en: "Footer Management" } },
  { slug: "contact-info", title: { tr: "İletişim Bilgileri", en: "Contact Info" } },
];

export type LinkSourceRef = { collection: string; id?: string; global?: string; title: string; field: string; adminUrl: string };
export type BrokenReason = "not-found" | "server-error" | "unreachable" | "unpublished" | "deleted" | "relative";
export type BrokenLink = { target: string; type: FoundLink["kind"]; status?: number; reason: BrokenReason; sources: LinkSourceRef[] };
export type ScanResult = {
  checkedAt: string;
  siteOrigin: string;
  external: boolean;
  counts: { links: number; internal: number; external: number; broken: number };
  broken: BrokenLink[];
};

export function siteOriginForChecks(): string {
  const explicit = process.env.SITE_INTERNAL_URL;
  if (explicit) return explicit.replace(/\/+$/, "");
  try {
    if (process.env.SITE_REVALIDATE_URL) return new URL(process.env.SITE_REVALIDATE_URL).origin;
  } catch {
    // fall through
  }
  return (process.env.SITE_URL || "http://localhost:3000").replace(/\/+$/, "");
}

function publicSiteHosts(): string[] {
  try {
    return process.env.SITE_URL ? [new URL(process.env.SITE_URL).host.toLowerCase()] : [];
  } catch {
    return [];
  }
}

type Checked = { ok: boolean; status?: number; reason?: BrokenReason };

async function checkUrl(url: string, fetchImpl: typeof fetch, timeoutMs: number): Promise<Checked> {
  try {
    const res = await fetchImpl(url, {
      method: "GET",
      redirect: "manual",
      headers: { "user-agent": "Clover-LinkCheck/1.0", "x-link-check": "1" },
      signal: AbortSignal.timeout(timeoutMs),
    });
    if (res.status < 400) return { ok: true, status: res.status };
    // Sites that refuse automated requests (LinkedIn answers 999, others 401/403/405/429)
    // can't be verified this way — not evidence of a broken link, so not reported.
    if ([401, 403, 405, 429, 999].includes(res.status)) return { ok: true, status: res.status };
    if (res.status === 404 || res.status === 410) return { ok: false, status: res.status, reason: "not-found" };
    return { ok: false, status: res.status, reason: res.status >= 500 ? "server-error" : "not-found" };
  } catch {
    return { ok: false, reason: "unreachable" };
  }
}

async function pool<T, R>(items: T[], size: number, fn: (item: T) => Promise<R>): Promise<R[]> {
  const results: R[] = new Array(items.length);
  let next = 0;
  const workers = Array.from({ length: Math.min(size, items.length) }, async () => {
    while (next < items.length) {
      const i = next++;
      results[i] = await fn(items[i]);
    }
  });
  await Promise.all(workers);
  return results;
}

export async function scanBrokenLinks(
  payload: Payload,
  options: { external?: boolean; locale?: "tr" | "en"; fetchImpl?: typeof fetch; timeoutMs?: number } = {}
): Promise<ScanResult> {
  const locale = options.locale ?? "tr";
  const fetchImpl = options.fetchImpl ?? fetch;
  const timeoutMs = options.timeoutMs ?? 8000;
  const siteOrigin = siteOriginForChecks();
  const extraHosts = publicSiteHosts();

  // target key → where it appears
  const occurrences = new Map<string, { link: FoundLink; sources: LinkSourceRef[] }>();
  const add = (link: FoundLink, source: Omit<LinkSourceRef, "field">) => {
    const key =
      link.kind === "internal" ? `internal:${link.path}` : link.kind === "external" ? `external:${link.url}` : link.kind === "doc" ? `doc:${link.relationTo}/${link.id}` : `invalid:${link.raw}`;
    const entry = occurrences.get(key) ?? { link, sources: [] };
    entry.sources.push({ ...source, field: readableField(link.field) });
    occurrences.set(key, entry);
  };

  let total = 0;
  for (const src of SOURCES) {
    const { docs } = await payload.find({
      collection: src.collection as never,
      depth: 0,
      limit: 2000,
      pagination: false,
      overrideAccess: true,
      ...(src.drafts ? { where: { _status: { equals: "published" } } } : {}),
    });
    for (const doc of docs as unknown as Record<string, unknown>[]) {
      const links = extractLinks(doc, extraHosts);
      total += links.length;
      const title = String(doc[src.titleField] ?? doc.id);
      links.forEach((link) =>
        add(link, { collection: src.collection, id: String(doc.id), title, adminUrl: `/admin/collections/${src.collection}/${doc.id}` })
      );
    }
  }
  for (const g of GLOBAL_SOURCES) {
    try {
      const doc = await payload.findGlobal({ slug: g.slug as never, depth: 0, overrideAccess: true });
      const links = extractLinks(doc, extraHosts);
      total += links.length;
      links.forEach((link) => add(link, { collection: g.slug, global: g.slug, title: g.title[locale], adminUrl: `/admin/globals/${g.slug}` }));
    } catch {
      // A global that doesn't exist yet has no links.
    }
  }

  const entries = [...occurrences.values()];
  const broken: BrokenLink[] = [];

  const internal = entries.filter((e) => e.link.kind === "internal");
  const external = entries.filter((e) => e.link.kind === "external");
  const internalResults = await pool(internal, 6, (e) =>
    checkUrl(`${siteOrigin}${(e.link as Extract<FoundLink, { kind: "internal" }>).path}`, fetchImpl, timeoutMs)
  );
  internal.forEach((e, i) => {
    const r = internalResults[i];
    if (!r.ok) broken.push({ target: (e.link as Extract<FoundLink, { kind: "internal" }>).path, type: "internal", status: r.status, reason: r.reason!, sources: e.sources });
  });

  if (options.external) {
    const externalResults = await pool(external, 6, (e) => checkUrl((e.link as Extract<FoundLink, { kind: "external" }>).url, fetchImpl, timeoutMs));
    external.forEach((e, i) => {
      const r = externalResults[i];
      if (!r.ok) broken.push({ target: (e.link as Extract<FoundLink, { kind: "external" }>).url, type: "external", status: r.status, reason: r.reason!, sources: e.sources });
    });
  }

  for (const e of entries.filter((x) => x.link.kind === "doc")) {
    const link = e.link as Extract<FoundLink, { kind: "doc" }>;
    let reason: BrokenReason | null = null;
    try {
      const target = (await payload.findByID({ collection: link.relationTo as never, id: link.id, depth: 0, overrideAccess: true })) as {
        _status?: string;
      };
      if (target._status && target._status !== "published") reason = "unpublished";
    } catch {
      reason = "deleted";
    }
    if (reason) broken.push({ target: link.raw, type: "doc", reason, sources: e.sources });
  }

  for (const e of entries.filter((x) => x.link.kind === "invalid")) {
    broken.push({ target: e.link.raw, type: "invalid", reason: "relative", sources: e.sources });
  }

  return {
    checkedAt: new Date().toISOString(),
    siteOrigin,
    external: Boolean(options.external),
    counts: { links: total, internal: internal.length, external: external.length, broken: broken.length },
    broken,
  };
}

export const brokenLinksScanEndpoint: Endpoint = {
  path: "/broken-links/scan",
  method: "get",
  handler: async (req) => {
    if (!req.user?.id) {
      return Response.json({ errors: [{ message: req.i18n?.language === "en" ? "You must be logged in." : "Giriş yapmalısınız." }] }, { status: 401 });
    }
    const external = new URL(req.url ?? "http://x").searchParams.get("external") === "1";
    const result = await scanBrokenLinks(req.payload, { external, locale: req.i18n?.language === "en" ? "en" : "tr" });
    return Response.json(result);
  },
};
