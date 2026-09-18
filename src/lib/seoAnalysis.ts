/**
 * SEO asistanı (18.09.2026) — the checks behind the Yoast-style panel on
 * Kampanyalar / Blog Yazıları / Sayfalar. Pure functions, no "payload"
 * import, so the client component and the tests share one implementation.
 *
 * The title/description it scores are the ones the SITE will actually emit,
 * mirroring vodafonepaycomtr-site `generateMetadata` for each route:
 * - title: seoTitle, else `${title} | Vodafone Pay`
 * - description: seoDescription, else campaign description / blog body's
 *   first 155 characters / (pages) the page title
 * - the homepage document instead falls back to the site's fixed homepage
 *   title and description (Sayfa Meta "/" can override those; not read here)
 */

export const SITE_ORIGIN = "https://www.vodafonepay.com.tr";
export const TITLE_SUFFIX = " | Vodafone Pay";
/** What `/` shows when neither the homepage document nor Sayfa Meta "/" sets one (vodafonepaycomtr-site lib/metadata.ts). */
export const HOMEPAGE_DEFAULT_TITLE = "Vodafone Pay | Yeni Nesil Mobil Cüzdan";
export const HOMEPAGE_DEFAULT_DESCRIPTION =
  "Vodafone Pay ile cüzdanınıza bakış açınız kökten değişiyor, hazır mısınız? Vodafone Pay hakkında detaylı bilgi almak için tıklayın.";

/** Google shows roughly this much before cutting with "…" (character approximation of ~580px). */
export const TITLE_MAX = 60;
export const TITLE_MIN = 30;
export const DESCRIPTION_MAX = 160;
export const DESCRIPTION_MIN = 70;
export const SLUG_MAX = 75;
/** Facebook/LinkedIn/WhatsApp render large cards from 1200×630 up. */
export const SOCIAL_MIN_WIDTH = 1200;
export const SOCIAL_MIN_HEIGHT = 630;

export type DescriptionFallback = "description" | "body" | "title";

export type SeoInput = {
  title?: string;
  seoTitle?: string;
  seoDescription?: string;
  seoKeywords?: string;
  slug?: string;
  pathPrefix: string;
  isHomepage?: boolean;
  descriptionFallback: DescriptionFallback;
  /** The collection's own description field (campaigns). */
  description?: string;
  /** Rich text body (blog) — Lexical JSON. */
  body?: unknown;
  image?: { alt?: string; filename?: string; width?: number; height?: number } | null;
  /** Images placed inside the rich text, with their alt texts. */
  inlineImages?: { alt?: string; filename?: string }[];
  duplicateTitleCount?: number;
};

export type CheckLevel = "good" | "warn" | "bad" | "info";
export type CheckId =
  | "titleLength"
  | "titleFallback"
  | "descriptionLength"
  | "descriptionFallback"
  | "keyword"
  | "slug"
  | "image"
  | "imageAlt"
  | "imageSize"
  | "inlineAlt"
  | "duplicateTitle";

export type Check = { id: CheckId; level: CheckLevel; values?: Record<string, string | number> };

export type SeoResult = {
  title: string;
  description: string;
  url: string;
  checks: Check[];
  score: "good" | "ok" | "poor";
};

const clean = (v: unknown): string => (typeof v === "string" ? v.replace(/\s+/g, " ").trim() : "");

/** Plain text of a Lexical document, like the site's richTextToPlainText. */
export function lexicalToPlainText(value: unknown, max?: number): string {
  const out: string[] = [];
  const walk = (node: unknown) => {
    if (!node || typeof node !== "object") return;
    const n = node as { text?: unknown; children?: unknown[]; root?: unknown };
    if (typeof n.text === "string") out.push(n.text);
    if (n.root) walk(n.root);
    if (Array.isArray(n.children)) n.children.forEach(walk);
  };
  walk(value);
  const text = out.join(" ").replace(/\s+/g, " ").trim();
  if (max === undefined || text.length <= max) return text;
  return text.slice(0, max).trimEnd() + "…";
}

/** Ids of images placed inside a Lexical document (upload nodes). */
export function lexicalUploadIds(value: unknown): (string | number)[] {
  const ids: (string | number)[] = [];
  const walk = (node: unknown) => {
    if (!node || typeof node !== "object") return;
    const n = node as { type?: string; relationTo?: string; value?: unknown; children?: unknown[]; root?: unknown };
    if (n.type === "upload" && n.relationTo === "media") {
      const v = n.value as { id?: string | number } | string | number | undefined;
      const id = typeof v === "object" && v ? v.id : v;
      if (id !== undefined && id !== null && id !== "") ids.push(id as string | number);
    }
    if (n.root) walk(n.root);
    if (Array.isArray(n.children)) n.children.forEach(walk);
  };
  walk(value);
  return ids;
}

/** The alt text Media.ts writes when the editor leaves it empty — i.e. not a real description. */
export function altFromFilename(filename: string | undefined): string {
  const derived = (filename ?? "")
    .replace(/\.[^.]+$/, "")
    .replace(/[-_]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  return derived ? derived.charAt(0).toLocaleUpperCase("tr-TR") + derived.slice(1) : "";
}

export function isWeakAlt(image: { alt?: string; filename?: string }): boolean {
  const alt = clean(image.alt);
  if (!alt) return true;
  return alt === altFromFilename(image.filename);
}

const fold = (s: string) =>
  s
    .toLocaleLowerCase("tr-TR")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/ı/g, "i");

export function truncate(text: string, max: number): string {
  return text.length <= max ? text : text.slice(0, max - 1).trimEnd() + "…";
}

export function analyzeSeo(input: SeoInput): SeoResult {
  const baseTitle = clean(input.title);
  const seoTitle = clean(input.seoTitle);
  const fallbackTitle = input.isHomepage ? HOMEPAGE_DEFAULT_TITLE : baseTitle ? `${baseTitle}${TITLE_SUFFIX}` : "";
  const title = seoTitle || fallbackTitle;

  const seoDescription = clean(input.seoDescription);
  let fallbackDescription = "";
  if (input.isHomepage) fallbackDescription = HOMEPAGE_DEFAULT_DESCRIPTION;
  else if (input.descriptionFallback === "description") fallbackDescription = clean(input.description);
  else if (input.descriptionFallback === "body") fallbackDescription = lexicalToPlainText(input.body, 155);
  else fallbackDescription = baseTitle;
  const description = seoDescription || fallbackDescription;

  const slug = clean(input.slug);
  const path = input.isHomepage ? "/" : `${input.pathPrefix}${slug}`;
  const url = `${SITE_ORIGIN}${path}`;

  const checks: Check[] = [];

  const tl = title.length;
  checks.push({
    id: "titleLength",
    level: tl === 0 ? "bad" : tl > TITLE_MAX || tl < TITLE_MIN ? "warn" : "good",
    values: { length: tl, min: TITLE_MIN, max: TITLE_MAX },
  });
  if (!seoTitle) checks.push({ id: "titleFallback", level: "info", values: { source: input.isHomepage ? "homepage" : "title" } });

  const dl = description.length;
  checks.push({
    id: "descriptionLength",
    level: dl === 0 ? "bad" : dl > DESCRIPTION_MAX || dl < DESCRIPTION_MIN ? "warn" : "good",
    values: { length: dl, min: DESCRIPTION_MIN, max: DESCRIPTION_MAX },
  });
  if (!seoDescription) {
    checks.push({
      id: "descriptionFallback",
      // A page's own title standing in as its description is a real problem, not just a note.
      level: input.descriptionFallback === "title" && !input.isHomepage ? "warn" : "info",
      values: { source: input.isHomepage ? "homepage" : input.descriptionFallback },
    });
  }

  const keyword = clean(input.seoKeywords).split(",").map((k) => k.trim()).filter(Boolean)[0];
  if (!keyword) {
    checks.push({ id: "keyword", level: "info", values: { state: "none" } });
  } else {
    const k = fold(keyword);
    const inTitle = fold(title).includes(k);
    const inDescription = fold(description).includes(k);
    const inSlug = fold(slug.replace(/-/g, " ")).includes(k);
    const hits = [inTitle, inDescription, inSlug].filter(Boolean).length;
    checks.push({
      id: "keyword",
      level: inTitle && inDescription ? "good" : hits > 0 ? "warn" : "bad",
      values: {
        keyword,
        state: "set",
        inTitle: inTitle ? 1 : 0,
        inDescription: inDescription ? 1 : 0,
        inSlug: inSlug ? 1 : 0,
      },
    });
  }

  if (!input.isHomepage) {
    const slugOk = slug.length > 0 && slug.length <= SLUG_MAX && /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug);
    checks.push({ id: "slug", level: slugOk ? "good" : "warn", values: { length: slug.length, max: SLUG_MAX } });
  }

  if (!input.image) {
    checks.push({ id: "image", level: input.descriptionFallback === "title" ? "info" : "warn" });
  } else {
    checks.push({
      id: "imageAlt",
      level: isWeakAlt(input.image) ? "warn" : "good",
      values: { alt: clean(input.image.alt) },
    });
    const w = input.image.width ?? 0;
    const h = input.image.height ?? 0;
    if (w && h) {
      checks.push({
        id: "imageSize",
        level: w >= SOCIAL_MIN_WIDTH && h >= SOCIAL_MIN_HEIGHT ? "good" : "warn",
        values: { width: w, height: h, minWidth: SOCIAL_MIN_WIDTH, minHeight: SOCIAL_MIN_HEIGHT },
      });
    }
  }

  const inline = input.inlineImages ?? [];
  if (inline.length > 0) {
    const weak = inline.filter(isWeakAlt).length;
    checks.push({ id: "inlineAlt", level: weak === 0 ? "good" : "warn", values: { weak, total: inline.length } });
  }

  if (seoTitle && input.duplicateTitleCount !== undefined) {
    checks.push({
      id: "duplicateTitle",
      level: input.duplicateTitleCount > 0 ? "warn" : "good",
      values: { count: input.duplicateTitleCount },
    });
  }

  const bad = checks.filter((c) => c.level === "bad").length;
  const warn = checks.filter((c) => c.level === "warn").length;
  // Yoast-like: any failed check, or three or more warnings, is "poor".
  const score = bad > 0 || warn >= 3 ? "poor" : warn > 0 ? "ok" : "good";

  return { title, description, url, checks, score };
}
