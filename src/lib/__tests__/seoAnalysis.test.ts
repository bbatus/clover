import { describe, expect, it } from "vitest";
import { altFromFilename, analyzeSeo, isWeakAlt, lexicalToPlainText, lexicalUploadIds, truncate } from "@/lib/seoAnalysis";

const base = { pathPrefix: "/kampanyalar/", descriptionFallback: "description" as const };
const byId = (r: ReturnType<typeof analyzeSeo>, id: string) => r.checks.find((c) => c.id === id);

describe("analyzeSeo — what the site will actually emit", () => {
  it("falls back to `${title} | Vodafone Pay` and the campaign description, like generateMetadata", () => {
    const r = analyzeSeo({ ...base, title: "Yaz Kampanyası", slug: "yaz-kampanyasi", description: "Açıklama" });
    expect(r.title).toBe("Yaz Kampanyası | Vodafone Pay");
    expect(r.description).toBe("Açıklama");
    expect(r.url).toBe("https://www.vodafonepay.com.tr/kampanyalar/yaz-kampanyasi");
    expect(byId(r, "titleFallback")?.level).toBe("info");
    expect(byId(r, "descriptionFallback")?.level).toBe("info");
  });

  it("uses the blog body's first 155 characters when there is no SEO description", () => {
    const body = { root: { children: [{ children: [{ text: "a".repeat(200) }] }] } };
    const r = analyzeSeo({ pathPrefix: "/blog/", descriptionFallback: "body", title: "T", body });
    expect(r.description).toHaveLength(156); // 155 + "…"
  });

  it("warns when a page would use its own title as description", () => {
    const r = analyzeSeo({ pathPrefix: "/", descriptionFallback: "title", title: "Anında Bakiye", slug: "aninda-bakiye" });
    expect(r.description).toBe("Anında Bakiye");
    expect(byId(r, "descriptionFallback")?.level).toBe("warn");
  });

  it("serves the homepage at / with the site's own homepage defaults", () => {
    const r = analyzeSeo({ pathPrefix: "/", descriptionFallback: "title", title: "Anasayfa", slug: "anasayfa", isHomepage: true });
    expect(r.url).toBe("https://www.vodafonepay.com.tr/");
    expect(r.title).toBe("Vodafone Pay | Yeni Nesil Mobil Cüzdan");
    expect(r.description).toMatch(/^Vodafone Pay ile cüzdanınıza/);
    expect(byId(r, "descriptionFallback")).toMatchObject({ level: "info", values: { source: "homepage" } });
    expect(byId(r, "slug")).toBeUndefined();
  });

  it("scores three or more warnings as poor", () => {
    const r = analyzeSeo({ ...base, seoTitle: "x".repeat(90), seoDescription: "kısa", seoKeywords: "kart", slug: "a" });
    expect(r.checks.filter((c) => c.level === "warn").length).toBeGreaterThanOrEqual(2);
    expect(r.score).toBe("poor");
  });
});

describe("analyzeSeo — lengths", () => {
  it("scores title and description lengths against Google's cut-off", () => {
    const good = analyzeSeo({ ...base, seoTitle: "QR ile ödemede yüzde yirmi indirim kampanyası", seoDescription: "x".repeat(120), slug: "a" });
    expect(byId(good, "titleLength")?.level).toBe("good");
    expect(byId(good, "descriptionLength")?.level).toBe("good");
    const long = analyzeSeo({ ...base, seoTitle: "x".repeat(70), seoDescription: "x".repeat(200), slug: "a" });
    expect(byId(long, "titleLength")?.level).toBe("warn");
    expect(byId(long, "descriptionLength")?.level).toBe("warn");
    const empty = analyzeSeo({ ...base, slug: "a" });
    expect(byId(empty, "titleLength")?.level).toBe("bad");
    expect(empty.score).toBe("poor");
  });
});

describe("analyzeSeo — focus keyword (first of seoKeywords)", () => {
  it("matches Turkish text case- and accent-insensitively in title, description and address", () => {
    const r = analyzeSeo({
      ...base,
      seoTitle: "QR İLE ÖDEME Fırsatı",
      seoDescription: "Qr ile ödeme yapanlara indirim.",
      seoKeywords: "qr ile ödeme, indirim",
      slug: "qr-ile-odeme-firsati",
    });
    expect(byId(r, "keyword")).toMatchObject({ level: "good", values: { inTitle: 1, inDescription: 1, inSlug: 1 } });
  });

  it("warns when the keyword is only in some places, fails when nowhere", () => {
    const some = analyzeSeo({ ...base, seoTitle: "Kart kampanyası", seoDescription: "Başka bir şey", seoKeywords: "kart", slug: "x" });
    expect(byId(some, "keyword")?.level).toBe("warn");
    const none = analyzeSeo({ ...base, seoTitle: "A", seoDescription: "B", seoKeywords: "fatura", slug: "x" });
    expect(byId(none, "keyword")?.level).toBe("bad");
  });
});

describe("analyzeSeo — images and alt text", () => {
  it("flags alt text that Media.ts derived from the file name", () => {
    expect(altFromFilename("ekran-resmi_2026.png")).toBe("Ekran resmi 2026");
    expect(isWeakAlt({ alt: "Ekran resmi 2026", filename: "ekran-resmi_2026.png" })).toBe(true);
    expect(isWeakAlt({ alt: "QR kodu okutan kullanıcı", filename: "ekran-resmi_2026.png" })).toBe(false);
    const r = analyzeSeo({ ...base, slug: "a", image: { alt: "Ekran resmi 2026", filename: "ekran-resmi_2026.png", width: 600, height: 300 } });
    expect(byId(r, "imageAlt")?.level).toBe("warn");
    expect(byId(r, "imageSize")?.level).toBe("warn");
  });

  it("counts weak alt texts among images inside the rich text", () => {
    const r = analyzeSeo({
      ...base,
      slug: "a",
      inlineImages: [{ alt: "Açıklayıcı metin", filename: "a.png" }, { alt: "B", filename: "b.png" }],
    });
    expect(byId(r, "inlineAlt")).toMatchObject({ level: "warn", values: { weak: 1, total: 2 } });
  });

  it("finds upload ids in Lexical JSON, whether the value is an id or a populated doc", () => {
    const doc = { root: { children: [{ type: "upload", relationTo: "media", value: 7 }, { children: [{ type: "upload", relationTo: "media", value: { id: 9 } }] }] } };
    expect(lexicalUploadIds(doc)).toEqual([7, 9]);
  });
});

describe("analyzeSeo — duplicates and helpers", () => {
  it("warns when another record uses the same SEO title", () => {
    const r = analyzeSeo({ ...base, seoTitle: "Aynı", slug: "a", duplicateTitleCount: 2 });
    expect(byId(r, "duplicateTitle")).toMatchObject({ level: "warn", values: { count: 2 } });
  });

  it("truncates with an ellipsis and flattens Lexical text", () => {
    expect(truncate("abcdef", 4)).toBe("abc…");
    expect(lexicalToPlainText({ root: { children: [{ children: [{ text: "Merhaba" }, { text: "dünya" }] }] } })).toBe("Merhaba dünya");
  });
});
