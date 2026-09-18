/**
 * Kırık link raporu (18.09.2026) — pulling every link out of a stored
 * document and sorting it. Pure: no "payload" import, so it is unit-tested
 * directly and the server scan (lib/brokenLinks.ts) only adds the I/O.
 *
 * What counts as a link:
 * - any string field whose name ends in url / href / link / deeplink
 *   (ctaUrl, href, mobileHref, deeplink, linkedinUrl, pressRelationsUrl …)
 * - Lexical rich-text link nodes: custom URLs, and "internal" links that point
 *   at another CMS document (checked separately — the document must exist
 *   and be published)
 */

export const SITE_HOSTS = ["www.vodafonepay.com.tr", "vodafonepay.com.tr"];

export type FoundLink =
  | { kind: "internal"; path: string; raw: string; field: string }
  | { kind: "external"; url: string; raw: string; field: string }
  | { kind: "doc"; relationTo: string; id: string; raw: string; field: string }
  | { kind: "invalid"; raw: string; field: string };

const URL_KEY = /(url|href|link|deeplink)$/i;

/** A same-site absolute URL or a root-relative path, as the path the site serves; null otherwise. */
export function toSitePath(raw: string, extraHosts: string[] = []): string | null {
  const value = raw.trim();
  if (value.startsWith("/") && !value.startsWith("//")) return stripPath(value);
  if (/^https?:\/\//i.test(value)) {
    try {
      const u = new URL(value);
      if ([...SITE_HOSTS, ...extraHosts].includes(u.host.toLowerCase())) return stripPath(u.pathname || "/");
    } catch {
      return null;
    }
  }
  return null;
}

function stripPath(p: string): string {
  const path = p.split(/[?#]/)[0] || "/";
  return path.length > 1 ? path.replace(/\/+$/, "") : path;
}

export function classifyLink(raw: string, field: string, extraHosts: string[] = []): FoundLink | null {
  const value = raw.trim();
  if (!value || value === "#" || value.startsWith("#")) return null;
  if (/^(mailto|tel|sms|javascript):/i.test(value)) return null;
  const sitePath = toSitePath(value, extraHosts);
  if (sitePath !== null) return { kind: "internal", path: sitePath, raw: value, field };
  if (/^https?:\/\//i.test(value)) return { kind: "external", url: value, raw: value, field };
  // App deep links (vodafonepay://…, intent:…) are not web pages — nothing to check.
  if (/^[a-z][a-z0-9+.-]*:/i.test(value)) return null;
  // "kampanyalar" / "www.site.com" without a scheme or leading slash: the browser
  // resolves it relative to the current page, which is almost never what was meant.
  return { kind: "invalid", raw: value, field };
}

/** Every link in a document (depth 0), with the path of the field it came from. */
export function extractLinks(doc: unknown, extraHosts: string[] = []): FoundLink[] {
  const found: FoundLink[] = [];
  const walk = (node: unknown, path: string) => {
    if (Array.isArray(node)) {
      node.forEach((child, i) => walk(child, `${path}[${i}]`));
      return;
    }
    if (!node || typeof node !== "object") return;
    const n = node as Record<string, unknown>;

    if ((n.type === "link" || n.type === "autolink") && n.fields && typeof n.fields === "object") {
      const f = n.fields as { linkType?: string; url?: unknown; doc?: { relationTo?: string; value?: unknown } | null };
      if (f.linkType === "internal" && f.doc?.relationTo) {
        const v = f.doc.value as { id?: unknown } | string | number | undefined;
        const id = typeof v === "object" && v ? v.id : v;
        if (id !== undefined && id !== null && id !== "") {
          found.push({ kind: "doc", relationTo: f.doc.relationTo, id: String(id), raw: `${f.doc.relationTo}/${id}`, field: path });
        }
      } else if (typeof f.url === "string") {
        const link = classifyLink(f.url, path, extraHosts);
        if (link) found.push(link);
      }
    }

    for (const [key, value] of Object.entries(n)) {
      if (key === "fields" && (n.type === "link" || n.type === "autolink")) continue;
      const childPath = path ? `${path}.${key}` : key;
      if (typeof value === "string" && URL_KEY.test(key)) {
        const link = classifyLink(value, childPath, extraHosts);
        if (link) found.push(link);
      } else if (value && typeof value === "object") {
        walk(value, childPath);
      }
    }
  };
  walk(doc, "");
  return found;
}

/** "layout[2].cards[0].ctaUrl" → "layout › cards › ctaUrl" for people. */
export function readableField(path: string): string {
  return path
    .replace(/\[\d+\]/g, "")
    .split(".")
    .filter((part) => part && !["root", "children", "fields"].includes(part))
    .filter((part, i, arr) => arr.indexOf(part) === i)
    .join(" › ");
}
