import type { Field } from "payload";

/**
 * RFP §3.2.6 ("meta tags: title/description/keywords"). Google has not used
 * this tag for ranking since 2009 — it carries no real SEO value
 * (RFP-OPEN-ITEMS §2's original reasoning for omitting it entirely) — added
 * anyway per the RFP's literal wording once revisited. Shared across every
 * collection with SEO fields (Campaigns/BlogPosts/PageMeta/Pages) instead of
 * repeating the same field object 4 times.
 */
export const seoKeywordsField: Field = {
  name: "seoKeywords",
  type: "text",
  label: { tr: "SEO Anahtar Kelimeleri", en: "SEO Keywords" },
  admin: {
    description: {
      tr: "Virgülle ayrılmış anahtar kelimeler (ör: mobil ödeme, sanal kart, faturaya yansıt). Not: Google 2009'dan beri bu etiketi sıralamada kullanmıyor — gerçek SEO etkisi yok. İlk kelime SEO asistanında odak anahtar kelime olarak kullanılır: başlıkta, açıklamada ve adreste geçip geçmediği kontrol edilir.",
      en: "Comma-separated keywords (e.g. mobile payment, virtual card). Note: Google hasn't used this tag for ranking since 2009 — no real SEO impact. The first keyword is the SEO assistant's focus keyword: it checks whether it appears in the title, description and address.",
    },
  },
};

/**
 * 18.09.2026 — SEO asistanı (components/SeoAssistant.tsx): a sidebar panel
 * that scores the title/description the site will emit and previews them in
 * Google and as a shared link. One factory so the three collections using it
 * only differ in where the site serves them and what stands in for an empty
 * SEO description.
 */
export function seoAssistantField(clientProps: {
  collection: string;
  pathPrefix: string;
  imageField: string;
  descriptionFallback: "description" | "body" | "title";
  descriptionField?: string;
  bodyFields?: string[];
}): Field {
  return {
    name: "seoAssistant",
    type: "ui",
    admin: {
      position: "sidebar",
      components: { Field: { path: "/components/SeoAssistant#default", clientProps } },
    },
  };
}
