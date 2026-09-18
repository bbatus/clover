import { lookup } from "node:dns/promises";
import { isIP } from "node:net";
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

const SCAN_PAGE_SIZE = 500;

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
export type BrokenReason = "not-found" | "server-error" | "unreachable" | "private-address" | "unpublished" | "deleted" | "relative";
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

/**
 * 18.09.2026 review — SSRF guard for the optional external check. The URLs
 * come from CMS content, which every editor role can write, and the fetch
 * runs from inside the cluster (the CMS NetworkPolicy's egress is still `{}`,
 * see k8s/networkpolicy.yaml). Without this, putting
 * `http://169.254.169.254/…`, `http://10.x.x.x:5432` or a Service name in a
 * link and pressing "Taramayı başlat" made the CMS pod probe that address and
 * report back whether it answered — a port scanner for the internal network.
 * Addresses that resolve to loopback, private, link-local, CGNAT, ULA,
 * multicast or reserved ranges are not fetched; they are reported as
 * "private-address", which is also true from a visitor's point of view: a
 * public page cannot usefully link there. (The site's own internal address is
 * a different path — internal links are asked of SITE_INTERNAL_URL, which is
 * configuration, not content.) Resolve-then-fetch leaves a DNS-rebinding
 * window; closing it fully needs a pinned-IP dispatcher, noted in tasks.md.
 */
export function isPrivateAddress(ip: string): boolean {
  const v4 = ip.startsWith("::ffff:") ? ip.slice(7) : ip;
  if (isIP(v4) === 4) {
    const [a, b] = v4.split(".").map(Number);
    return (
      a === 0 ||
      a === 10 ||
      a === 127 ||
      (a === 100 && b >= 64 && b <= 127) ||
      (a === 169 && b === 254) ||
      (a === 172 && b >= 16 && b <= 31) ||
      (a === 192 && b === 168) ||
      (a === 192 && b === 0) ||
      (a === 198 && (b === 18 || b === 19)) ||
      a >= 224
    );
  }
  if (isIP(ip) === 6) {
    const x = ip.toLowerCase();
    return x === "::" || x === "::1" || /^f[cd]/.test(x) || /^fe[89ab]/.test(x) || x.startsWith("ff") || x.startsWith("64:ff9b:");
  }
  return true; // not an address at all: refuse rather than guess
}

type Resolver = (host: string) => Promise<string[]>;
const resolveAll: Resolver = async (host) => (await lookup(host, { all: true, verbatim: true })).map((r) => r.address);

/** True when every address the URL's host resolves to is public. */
export async function isPublicHttpTarget(url: string, resolve: Resolver = resolveAll): Promise<boolean> {
  let u: URL;
  try {
    u = new URL(url);
  } catch {
    return false;
  }
  if (u.protocol !== "http:" && u.protocol !== "https:") return false;
  const host = u.hostname.replace(/^\[|\]$/g, "");
  if (!host || host === "localhost" || host.endsWith(".localhost")) return false;
  if (isIP(host)) return !isPrivateAddress(host);
  try {
    const addresses = await resolve(host);
    return addresses.length > 0 && addresses.every((a) => !isPrivateAddress(a));
  } catch {
    return false;
  }
}

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
  options: { external?: boolean; locale?: "tr" | "en"; fetchImpl?: typeof fetch; timeoutMs?: number; resolve?: Resolver } = {}
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
    // Paged rather than one `limit: 2000` read: past 2000 records a
    // collection's tail used to be skipped silently (with `pagination: false`
    // Payload still applies the limit) and the report said "no broken links".
    const docs: Record<string, unknown>[] = [];
    for (let page = 1; ; page++) {
      const res = await payload.find({
        collection: src.collection as never,
        depth: 0,
        limit: SCAN_PAGE_SIZE,
        page,
        sort: "id",
        overrideAccess: true,
        ...(src.drafts ? { where: { _status: { equals: "published" } } } : {}),
      });
      docs.push(...(res.docs as unknown as Record<string, unknown>[]));
      if (!res.hasNextPage) break;
    }
    for (const doc of docs) {
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
    const externalResults = await pool(external, 6, async (e): Promise<Checked> => {
      const url = (e.link as Extract<FoundLink, { kind: "external" }>).url;
      if (!(await isPublicHttpTarget(url, options.resolve))) return { ok: false, reason: "private-address" };
      return checkUrl(url, fetchImpl, timeoutMs);
    });
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

let scanRunning = false;

export const brokenLinksScanEndpoint: Endpoint = {
  path: "/broken-links/scan",
  method: "get",
  handler: async (req) => {
    if (!req.user?.id) {
      return Response.json({ errors: [{ message: req.i18n?.language === "en" ? "You must be logged in." : "Giriş yapmalısınız." }] }, { status: 401 });
    }
    // One scan at a time per pod: a scan fires a request at the site for every
    // distinct address, and several editors (or a double click) would multiply that.
    if (scanRunning) {
      return Response.json(
        { errors: [{ message: req.i18n?.language === "en" ? "A scan is already running. Try again in a moment." : "Şu anda bir tarama sürüyor. Birazdan tekrar deneyin." }] },
        { status: 429 }
      );
    }
    const external = new URL(req.url ?? "http://x").searchParams.get("external") === "1";
    scanRunning = true;
    try {
      const result = await scanBrokenLinks(req.payload, { external, locale: req.i18n?.language === "en" ? "en" : "tr" });
      return Response.json(result);
    } finally {
      scanRunning = false;
    }
  },
};
