"use client";

import { useEffect, useMemo, useState } from "react";
import { useDocumentInfo, useFormFields } from "@payloadcms/ui";
import { useAdminLocale } from "./useAdminLocale";
import { VfSpinner } from "./AdminStates";
import {
  analyzeSeo,
  lexicalUploadIds,
  truncate,
  DESCRIPTION_MAX,
  TITLE_MAX,
  type Check,
  type DescriptionFallback,
} from "@/lib/seoAnalysis";

/**
 * SEO asistanı (18.09.2026, product ekibi önerisi — WordPress Yoast benzeri).
 * Sits in the sidebar of Kampanyalar / Blog Yazıları / Sayfalar and updates
 * as the editor types, before anything is saved: what Google and a shared
 * link will show, and what to fix. It only advises — nothing here blocks a
 * save or a publish.
 *
 * Reads the live form state; fetches only what the form doesn't hold (the
 * chosen image's alt text and size, images inside the rich text, and whether
 * another record already uses the same SEO title).
 */

type Props = {
  collection: string;
  pathPrefix: string;
  descriptionField?: string;
  bodyFields?: string[];
  imageField: string;
  descriptionFallback: DescriptionFallback;
};

type Media = { id: string | number; alt?: string; filename?: string; width?: number; height?: number; url?: string; sizes?: Record<string, { url?: string | null }> };

const STRINGS = {
  tr: {
    title: "SEO asistanı",
    score: { good: "İyi", ok: "Geliştirilebilir", poor: "Zayıf" },
    google: "Google'da görünüm",
    social: "Paylaşıldığında görünüm",
    noImage: "Görsel yok — sitenin varsayılan paylaşım görseli kullanılır",
    imageLoading: "Görsel yükleniyor",
    checks: "Kontroller",
    advisory: "Bu panel yalnızca öneri verir; kaydetmeyi ya da yayınlamayı engellemez.",
    msg: {
      titleLength: (v: Record<string, string | number>) =>
        Number(v.length) === 0
          ? "Başlık boş."
          : Number(v.length) > Number(v.max)
            ? `Başlık ${v.length} karakter — Google ~${v.max} karakterden sonrasını "…" ile keser. Kısaltın.`
            : Number(v.length) < Number(v.min)
              ? `Başlık ${v.length} karakter — kısa. ${v.min}–${v.max} arası önerilir.`
              : `Başlık uzunluğu iyi (${v.length} karakter).`,
      titleFallback: (v: Record<string, string | number>) =>
        v.source === "pageMeta"
          ? "SEO Başlığı boş: bu adres için Sayfa Meta Bilgileri'ndeki başlık kullanılacak."
          : v.source === "homepage"
          ? "SEO Başlığı boş: sitenin varsayılan anasayfa başlığı kullanılacak."
          : "SEO Başlığı boş: sayfa başlığının sonuna \" | Vodafone Pay\" eklenerek kullanılacak.",
      descriptionLength: (v: Record<string, string | number>) =>
        Number(v.length) === 0
          ? "Açıklama boş — Google sayfadan kendi seçtiği bir metni gösterir."
          : Number(v.length) > Number(v.max)
            ? `Açıklama ${v.length} karakter — ~${v.max} karakterden sonrası kesilir.`
            : Number(v.length) < Number(v.min)
              ? `Açıklama ${v.length} karakter — kısa. ${v.min}–${v.max} arası önerilir.`
              : `Açıklama uzunluğu iyi (${v.length} karakter).`,
      descriptionFallback: (v: Record<string, string | number>) =>
        v.source === "pageMeta"
          ? "SEO Açıklaması boş: bu adres için Sayfa Meta Bilgileri'ndeki açıklama kullanılacak."
          : v.source === "homepage"
          ? "SEO Açıklaması boş: sitenin varsayılan anasayfa açıklaması kullanılacak."
          : v.source === "title"
          ? "SEO Açıklaması boş: sayfanın başlığı açıklama olarak kullanılacak. Sayfayı anlatan 1–2 cümle yazın."
          : v.source === "body"
            ? "SEO Açıklaması boş: yazının ilk 155 karakteri kullanılacak."
            : "SEO Açıklaması boş: kampanyanın 'Açıklama' alanı kullanılacak.",
      keyword: (v: Record<string, string | number>) => {
        if (v.state === "none") return "Anahtar kelime girilmemiş. İlk anahtar kelime başlık, açıklama ve adreste aranır.";
        const where = [v.inTitle ? "başlıkta" : null, v.inDescription ? "açıklamada" : null, v.inSlug ? "adreste" : null].filter(Boolean);
        const missing = [!v.inTitle ? "başlıkta" : null, !v.inDescription ? "açıklamada" : null].filter(Boolean);
        if (where.length === 0) return `"${v.keyword}" başlıkta, açıklamada ve adreste geçmiyor.`;
        return missing.length ? `"${v.keyword}" ${where.join(", ")} geçiyor; ${missing.join(" ve ")} geçmiyor.` : `"${v.keyword}" ${where.join(", ")} geçiyor.`;
      },
      slug: (v: Record<string, string | number>) =>
        Number(v.length) === 0
          ? "Sayfa adresi henüz oluşmadı (başlık girilince otomatik oluşur)."
          : Number(v.length) > Number(v.max)
            ? `Adres ${v.length} karakter — uzun. ${v.max} karakterin altı önerilir.`
            : "Adres kısa ve okunaklı.",
      image: () => "Görsel seçilmemiş — paylaşımlarda sitenin varsayılan görseli çıkar.",
      imageAlt: (v: Record<string, string | number>) =>
        v.alt ? `Görselin alternatif metni: "${v.alt}".` : "Görselin alternatif metni yok.",
      imageAltWeak: () => "Görselin alternatif metni dosya adından otomatik üretilmiş — görselin ne gösterdiğini anlatan bir metin yazın (Medya kütüphanesi).",
      imageSize: (v: Record<string, string | number>) =>
        `Paylaşım görseli ${v.width}×${v.height} px${
          Number(v.width) < Number(v.minWidth) || Number(v.height) < Number(v.minHeight)
            ? ` — büyük kart için en az ${v.minWidth}×${v.minHeight} px önerilir.`
            : " — büyük paylaşım kartı için uygun."
        }`,
      inlineAlt: (v: Record<string, string | number>) =>
        Number(v.weak) === 0
          ? `İçerikteki ${v.total} görselin hepsinin açıklayıcı alternatif metni var.`
          : `İçerikteki ${v.total} görselden ${v.weak} tanesinin alternatif metni yok ya da dosya adından üretilmiş.`,
      duplicateTitle: (v: Record<string, string | number>) =>
        Number(v.count) > 0 ? `Bu SEO başlığı ${v.count} başka kayıtta da kullanılıyor — her sayfanın başlığı farklı olmalı.` : "SEO başlığı benzersiz.",
    },
  },
  en: {
    title: "SEO assistant",
    score: { good: "Good", ok: "Needs work", poor: "Poor" },
    google: "In Google",
    social: "When shared",
    noImage: "No image — the site's default share image is used",
    imageLoading: "Loading image",
    checks: "Checks",
    advisory: "This panel only advises; it never blocks saving or publishing.",
    msg: {
      titleLength: (v: Record<string, string | number>) =>
        Number(v.length) === 0
          ? "The title is empty."
          : Number(v.length) > Number(v.max)
            ? `Title is ${v.length} characters — Google cuts after ~${v.max} with "…". Shorten it.`
            : Number(v.length) < Number(v.min)
              ? `Title is ${v.length} characters — short. ${v.min}–${v.max} recommended.`
              : `Title length is good (${v.length} characters).`,
      titleFallback: (v: Record<string, string | number>) =>
        v.source === "pageMeta"
          ? "SEO Title is empty: the title from Page Meta for this address is used."
          : v.source === "homepage"
          ? "SEO Title is empty: the site's default homepage title is used."
          : "SEO Title is empty: the page title plus \" | Vodafone Pay\" is used.",
      descriptionLength: (v: Record<string, string | number>) =>
        Number(v.length) === 0
          ? "The description is empty — Google shows text of its own choosing."
          : Number(v.length) > Number(v.max)
            ? `Description is ${v.length} characters — cut after ~${v.max}.`
            : Number(v.length) < Number(v.min)
              ? `Description is ${v.length} characters — short. ${v.min}–${v.max} recommended.`
              : `Description length is good (${v.length} characters).`,
      descriptionFallback: (v: Record<string, string | number>) =>
        v.source === "pageMeta"
          ? "SEO Description is empty: the description from Page Meta for this address is used."
          : v.source === "homepage"
          ? "SEO Description is empty: the site's default homepage description is used."
          : v.source === "title"
          ? "SEO Description is empty: the page title is used as the description. Write 1–2 sentences about the page."
          : v.source === "body"
            ? "SEO Description is empty: the first 155 characters of the post are used."
            : "SEO Description is empty: the campaign's Description field is used.",
      keyword: (v: Record<string, string | number>) => {
        if (v.state === "none") return "No keyword set. The first keyword is looked for in the title, description and address.";
        const where = [v.inTitle ? "title" : null, v.inDescription ? "description" : null, v.inSlug ? "address" : null].filter(Boolean);
        const missing = [!v.inTitle ? "title" : null, !v.inDescription ? "description" : null].filter(Boolean);
        if (where.length === 0) return `"${v.keyword}" appears in neither the title, the description nor the address.`;
        return missing.length ? `"${v.keyword}" is in the ${where.join(", ")}; not in the ${missing.join(" or ")}.` : `"${v.keyword}" is in the ${where.join(", ")}.`;
      },
      slug: (v: Record<string, string | number>) =>
        Number(v.length) === 0
          ? "No address yet (created automatically from the title)."
          : Number(v.length) > Number(v.max)
            ? `Address is ${v.length} characters — long. Under ${v.max} recommended.`
            : "Address is short and readable.",
      image: () => "No image chosen — shares show the site's default image.",
      imageAlt: (v: Record<string, string | number>) => (v.alt ? `Image alt text: "${v.alt}".` : "The image has no alt text."),
      imageAltWeak: () => "The image's alt text was generated from its file name — write what the image shows (Media library).",
      imageSize: (v: Record<string, string | number>) =>
        `Share image is ${v.width}×${v.height} px${
          Number(v.width) < Number(v.minWidth) || Number(v.height) < Number(v.minHeight)
            ? ` — at least ${v.minWidth}×${v.minHeight} px recommended for a large card.`
            : " — fine for a large share card."
        }`,
      inlineAlt: (v: Record<string, string | number>) =>
        Number(v.weak) === 0
          ? `All ${v.total} images in the content have descriptive alt text.`
          : `${v.weak} of ${v.total} images in the content have missing or file-name alt text.`,
      duplicateTitle: (v: Record<string, string | number>) =>
        Number(v.count) > 0 ? `This SEO title is also used on ${v.count} other record(s) — each page needs its own.` : "SEO title is unique.",
    },
  },
} as const;

function useField<T>(path: string): T | undefined {
  return useFormFields(([fields]) => fields?.[path]?.value as T | undefined);
}

function idOf(value: unknown): string | number | undefined {
  if (value && typeof value === "object" && "id" in (value as Record<string, unknown>)) return (value as { id: string | number }).id;
  if (typeof value === "string" || typeof value === "number") return value === "" ? undefined : value;
  return undefined;
}

async function fetchMedia(ids: (string | number)[]): Promise<Media[]> {
  if (ids.length === 0) return [];
  const params = new URLSearchParams({ depth: "0", limit: String(ids.length) });
  ids.forEach((id, i) => params.append(`where[id][in][${i}]`, String(id)));
  try {
    const res = await fetch(`/api/media?${params.toString()}`, { credentials: "include" });
    if (!res.ok) return [];
    return ((await res.json()) as { docs: Media[] }).docs;
  } catch {
    return [];
  }
}

export default function SeoAssistant(props: Props) {
  const { collection, pathPrefix, descriptionField, bodyFields = [], imageField, descriptionFallback } = props;
  const locale = useAdminLocale();
  const t = STRINGS[locale] ?? STRINGS.tr;
  const { id } = useDocumentInfo();

  const title = useField<string>("title");
  const seoTitle = useField<string>("seoTitle");
  const seoDescription = useField<string>("seoDescription");
  const seoKeywords = useField<string>("seoKeywords");
  const slug = useField<string>("slug");
  const isHomepage = useField<boolean>("isHomepage");
  const description = useField<string>(descriptionField ?? "__none__");
  const body0 = useField<unknown>(bodyFields[0] ?? "__none__");
  const body1 = useField<unknown>(bodyFields[1] ?? "__none__");
  const imageValue = useField<unknown>(imageField);

  const imageId = idOf(imageValue);
  const inlineIds = useMemo(() => [...lexicalUploadIds(body0), ...lexicalUploadIds(body1)], [body0, body1]);
  const inlineKey = inlineIds.join(",");

  const [image, setImage] = useState<Media | null>(null);
  // Which image id `image` belongs to — until they match, the social card
  // shows a spinner instead of briefly claiming "no image" (19.09.2026).
  const [loadedImageId, setLoadedImageId] = useState<string | number | undefined>(undefined);
  const [inline, setInline] = useState<Media[]>([]);
  const [duplicates, setDuplicates] = useState<number | undefined>(undefined);

  useEffect(() => {
    let cancelled = false;
    if (imageId === undefined) {
      Promise.resolve().then(() => !cancelled && setImage(null));
    } else {
      fetchMedia([imageId]).then((docs) => {
        if (cancelled) return;
        setImage(docs[0] ?? null);
        setLoadedImageId(imageId);
      });
    }
    return () => {
      cancelled = true;
    };
  }, [imageId]);

  useEffect(() => {
    let cancelled = false;
    const ids = inlineKey ? inlineKey.split(",") : [];
    fetchMedia(ids).then((docs) => !cancelled && setInline(docs));
    return () => {
      cancelled = true;
    };
  }, [inlineKey]);

  // Same SEO title on another record of this collection (debounced while typing).
  useEffect(() => {
    let cancelled = false;
    const value = (seoTitle ?? "").trim();
    const timer = setTimeout(async () => {
      if (!value) {
        if (!cancelled) setDuplicates(undefined);
        return;
      }
      const params = new URLSearchParams({ depth: "0", limit: "1", draft: "true" });
      params.append("where[seoTitle][equals]", value);
      if (id !== undefined && id !== null) params.append("where[id][not_equals]", String(id));
      const res = await fetch(`/api/${collection}?${params.toString()}`, { credentials: "include" });
      if (!cancelled && res.ok) setDuplicates(((await res.json()) as { totalDocs: number }).totalDocs);
    }, 600);
    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [collection, id, seoTitle]);

  // Pages only: a published Sayfa Meta Bilgileri row for the same address is
  // the site's second choice after the page's own SEO fields (18.09.2026 review).
  const [pageMeta, setPageMeta] = useState<{ seoTitle?: string; seoDescription?: string } | null>(null);
  const metaPath = collection === "pages" ? (isHomepage ? "/" : slug ? `/${slug}` : "") : "";
  useEffect(() => {
    let cancelled = false;
    if (!metaPath) {
      Promise.resolve().then(() => !cancelled && setPageMeta(null));
      return () => {
        cancelled = true;
      };
    }
    const params = new URLSearchParams({ depth: "0", limit: "1" });
    params.append("where[pageKey][equals]", metaPath);
    params.append("where[_status][equals]", "published");
    fetch(`/api/page-meta?${params.toString()}`, { credentials: "include" })
      .then(async (res) => (res.ok ? (((await res.json()) as { docs: { seoTitle?: string; seoDescription?: string }[] }).docs[0] ?? null) : null))
      .catch(() => null)
      .then((doc) => !cancelled && setPageMeta(doc));
    return () => {
      cancelled = true;
    };
  }, [metaPath]);

  const result = analyzeSeo({
    title,
    seoTitle,
    seoDescription,
    seoKeywords,
    slug,
    pathPrefix,
    isHomepage: Boolean(isHomepage),
    descriptionFallback,
    description,
    body: body0,
    image,
    inlineImages: inline,
    duplicateTitleCount: duplicates,
    pageMeta,
  });

  const breadcrumb = result.url.replace(/^https:\/\/www\./, "").split("/").filter(Boolean).join(" › ");
  // Card-size rendition first; if it fails to load, the original; then the empty state.
  const imageCandidates = [image?.sizes?.card?.url, image?.url].filter((u): u is string => Boolean(u));
  const [failedUrls, setFailedUrls] = useState<string[]>([]);
  const imageUrl = imageCandidates.find((u) => !failedUrls.includes(u));
  const imageLoading = imageId !== undefined && loadedImageId !== imageId;

  const messageFor = (c: Check): string => {
    const v = c.values ?? {};
    if (c.id === "imageAlt" && c.level === "warn") return t.msg.imageAltWeak();
    return (t.msg[c.id] as (v: Record<string, string | number>) => string)(v);
  };

  return (
    <div className="seoa" data-score={result.score}>
      <div className="seoa-head">
        <span className="seoa-title">{t.title}</span>
        <span className={`seoa-score seoa-score--${result.score}`}>
          <span className="seoa-dot" aria-hidden="true" />
          {t.score[result.score]}
        </span>
      </div>

      <section className="seoa-block" aria-label={t.google}>
        <span className="seoa-label">{t.google}</span>
        <div className="seoa-serp">
          <div className="seoa-serp-site">
            <span className="seoa-serp-favicon" aria-hidden="true">V</span>
            <span className="seoa-serp-sitemeta">
              <span className="seoa-serp-name">Vodafone Pay</span>
              <span className="seoa-serp-url">{breadcrumb}</span>
            </span>
          </div>
          <div className="seoa-serp-title">{truncate(result.title || "—", TITLE_MAX)}</div>
          <div className="seoa-serp-desc">{truncate(result.description || "—", DESCRIPTION_MAX)}</div>
        </div>
      </section>

      <section className="seoa-block" aria-label={t.social}>
        <span className="seoa-label">{t.social}</span>
        <div className="seoa-card">
          {imageLoading ? (
            <div className="seoa-card-img seoa-card-img--empty" role="status" aria-label={t.imageLoading}>
              <VfSpinner />
            </div>
          ) : imageUrl ? (
            // eslint-disable-next-line @next/next/no-img-element -- admin-only preview of a CMS media URL
            <img
              className="seoa-card-img"
              src={imageUrl}
              alt=""
              onError={() => setFailedUrls((prev) => (prev.includes(imageUrl) ? prev : [...prev, imageUrl]))}
            />
          ) : (
            <div className="seoa-card-img seoa-card-img--empty">{t.noImage}</div>
          )}
          <div className="seoa-card-text">
            <span className="seoa-card-domain">VODAFONEPAY.COM.TR</span>
            <span className="seoa-card-title">{result.title || "—"}</span>
            <span className="seoa-card-desc">{result.description || "—"}</span>
          </div>
        </div>
      </section>

      <section className="seoa-block" aria-label={t.checks}>
        <span className="seoa-label">{t.checks}</span>
        <ul className="seoa-checks">
          {result.checks.map((c) => (
            <li key={c.id} className={`seoa-check seoa-check--${c.level}`}>
              <span className="seoa-dot" aria-hidden="true" />
              <span>{messageFor(c)}</span>
            </li>
          ))}
        </ul>
        <p className="seoa-note">{t.advisory}</p>
      </section>
    </div>
  );
}
