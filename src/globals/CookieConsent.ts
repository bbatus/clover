import type { Field, GlobalConfig } from "payload";
import { revalidateGlobalTag } from "@/hooks/revalidate";
import { auditGlobalAfterChange } from "@/hooks/audit";
import { authenticated } from "@/access/authenticated";
import { denyMakerEditPublishedGlobal, denyMakerPublishGlobal, standardReadWrite } from "@/access/roles";
import { COOKIE_CATEGORY_KEYS, validateCookieCategories } from "@/lib/cookieConsentDefaults";

/**
 * 19.09.2026 — Çerez Bandı. Kullanıcı: "canlı sitede nasılsa bunu CMS'ten
 * yapabilmeli, stil ve yapı bakımından aynı." vodafonepay.com.tr has no
 * banner yet, so the reference is Vodafone Türkiye's own (vodafone.com.tr,
 * OneTrust): a centred window with a title, the policy text, "Reddet" and
 * "buraya tıklayabilirsiniz" links and a red "Çerezleri kabul et" button; the
 * link opens a "Gizliliğiniz" settings window with one row per category.
 *
 * Every visible word is edited here; the layout is fixed on the site
 * (vodafonepaycomtr-site `CookieConsent.tsx`). Maker→checker like SeoFiles: a
 * legal text going live unreviewed is exactly what the approval flow is for.
 * An empty field falls back to the site's copy of the starting text
 * (lib/cookieConsentDefaults.ts, inserted as data by migration §17).
 *
 * `policyVersion`: visitors' choices are stored with the version they agreed
 * to; raising it after a material change to the policy asks everyone again.
 */

const CATEGORY_LABELS: Record<(typeof COOKIE_CATEGORY_KEYS)[number], { tr: string; en: string }> = {
  necessary: { tr: "Zorunlu (kapatılamaz)", en: "Necessary (always on)" },
  performance: { tr: "Performans (Analitik)", en: "Performance (Analytics)" },
  functional: { tr: "İşlevsel", en: "Functional" },
  marketing: { tr: "Reklam/Pazarlama", en: "Advertising/Marketing" },
};

const text = (name: string, tr: string, en: string, description?: { tr: string; en: string }): Field => ({
  name,
  type: "text",
  label: { tr, en },
  ...(description ? { admin: { description } } : {}),
});

const area = (name: string, tr: string, en: string, rows: number, description?: { tr: string; en: string }): Field => ({
  name,
  type: "textarea",
  label: { tr, en },
  admin: { rows, ...(description ? { description } : {}) },
});

export const CookieConsent: GlobalConfig = {
  slug: "cookie-consent",
  label: { tr: "Çerez Bandı", en: "Cookie Banner" },
  admin: {
    hideAPIURL: true,
    group: { tr: "Site Yapısı", en: "Site Structure" },
    description: {
      tr: "Sitenin ilk açılışında çıkan çerez izni penceresi ve 'Gizliliğiniz' ayarlar penceresi. Tasarım sabittir (Vodafone Türkiye çerez bandı); buradan metinler ve kategoriler yönetilir. Değişiklikler onaydan (yayınla) sonra sitede görünür.",
      en: "The cookie consent window shown on a visitor's first visit and its 'Your privacy' settings window. The design is fixed (Vodafone Türkiye cookie banner); texts and categories are managed here. Changes show on the site once approved (published).",
    },
    components: {
      elements: {
        beforeDocumentControls: [{ path: "/components/HelpButton#default", clientProps: { collection: "cookie-consent" } }],
        PublishButton: "/components/MakerAwarePublishButton#default",
        SaveDraftButton: "/components/SaveOrSubmitButton#default",
      },
    },
  },
  versions: {
    drafts: true,
  },
  access: {
    read: () => true,
    readVersions: authenticated,
    update: standardReadWrite,
  },
  fields: [
    {
      type: "tabs",
      tabs: [
        {
          label: { tr: "Bant", en: "Banner" },
          fields: [
            {
              name: "enabled",
              type: "checkbox",
              defaultValue: true,
              label: { tr: "Bant sitede gösterilsin", en: "Show the banner on the site" },
              admin: {
                description: {
                  tr: "Kapatılırsa bant hiç çıkmaz ve isteğe bağlı çerezler için izin alınmamış sayılır (yalnız zorunlu çerezler).",
                  en: "When off, the banner never appears and optional cookies count as not consented (necessary cookies only).",
                },
              },
            },
            text("title", "Başlık", "Title"),
            {
              type: "row",
              fields: [
                text("policyLinkLabel", "Politika linki metni", "Policy link text", {
                  tr: "Metnin başındaki altı çizili link, ör. 'Çerez Politikamız'.",
                  en: "The underlined link at the start of the text, e.g. 'Çerez Politikamız'.",
                }),
                text("policyLinkUrl", "Politika linki adresi", "Policy link address", {
                  tr: "Ör. /cerez-politikasi",
                  en: "E.g. /cerez-politikasi",
                }),
              ],
            },
            area("introText", "Açıklama (linkten sonra)", "Text (after the link)", 5, {
              tr: "Politika linkinin hemen ardından gelen metin; ör. \"'da ayrıntılı şekilde açıkladığımız üzere…\".",
              en: "The text right after the policy link.",
            }),
            {
              type: "row",
              fields: [
                text("rejectLabel", "'Reddet' linki", "'Reject' link"),
                text("settingsLinkLabel", "Ayarlar linki", "Settings link", {
                  tr: "Ayarlar penceresini açan link, ör. 'buraya tıklayabilirsiniz.'",
                  en: "The link that opens the settings window.",
                }),
              ],
            },
            area("rejectText", "Reddet ile ayarlar linki arasındaki metin", "Text between 'Reject' and the settings link", 3),
            text("acceptLabel", "Kabul butonu", "Accept button"),
          ],
        },
        {
          label: { tr: "Ayarlar Penceresi", en: "Settings Window" },
          fields: [
            text("pcTitle", "Başlık", "Title"),
            area("pcDescription", "Açıklama", "Description", 10, {
              tr: "Paragrafları boş bir satırla ayırın.",
              en: "Separate paragraphs with an empty line.",
            }),
            {
              type: "row",
              fields: [text("moreInfoLabel", "'Daha fazla bilgi' linki", "'More info' link"), text("moreInfoUrl", "Link adresi", "Link address")],
            },
            {
              type: "row",
              fields: [
                text("allowAllLabel", "'Tümüne izin ver' butonu", "'Allow all' button"),
                text("saveLabel", "'Ayarları kaydet' butonu", "'Save settings' button"),
              ],
            },
            {
              type: "row",
              fields: [
                text("manageTitle", "Kategoriler başlığı", "Categories heading"),
                text("alwaysActiveLabel", "'Her zaman etkin' etiketi", "'Always active' label"),
              ],
            },
            {
              name: "categories",
              type: "array",
              label: { tr: "Çerez kategorileri", en: "Cookie categories" },
              labels: { singular: { tr: "Kategori", en: "Category" }, plural: { tr: "Kategoriler", en: "Categories" } },
              maxRows: COOKIE_CATEGORY_KEYS.length,
              admin: {
                initCollapsed: true,
                description: {
                  tr: "Pencerede bu sırayla gösterilir. 'Zorunlu' her zaman açıktır ve listeden çıkarılamaz; diğerleri ziyaretçinin açıp kapattığı anahtarlardır. Bir kategori listede yoksa sitede o kategoriye izin istenmez ve kapalı sayılır.",
                  en: "Shown in this order. 'Necessary' is always on and can't be removed; the others are switches the visitor turns on or off. A category missing from the list is never asked for and counts as off.",
                },
              },
              validate: (value: unknown, { req }: { req: { i18n?: { language?: string } } }) =>
                validateCookieCategories(value, req?.i18n?.language === "en" ? "en" : "tr"),
              fields: [
                {
                  name: "key",
                  type: "select",
                  required: true,
                  label: { tr: "Tür", en: "Type" },
                  options: COOKIE_CATEGORY_KEYS.map((value) => ({ value, label: CATEGORY_LABELS[value] })),
                },
                { name: "title", type: "text", required: true, label: { tr: "Başlık", en: "Title" } },
                { name: "description", type: "textarea", label: { tr: "Açıklama", en: "Description" }, admin: { rows: 6 } },
              ],
            },
          ],
        },
        {
          label: { tr: "Onay Sürümü", en: "Consent Version" },
          fields: [
            {
              name: "policyVersion",
              type: "number",
              defaultValue: 1,
              min: 1,
              label: { tr: "Onay sürümü", en: "Consent version" },
              admin: {
                description: {
                  tr: "Ziyaretçinin seçimi bu numarayla birlikte saklanır. Çerez politikasında esaslı bir değişiklik yapıldığında bir artırın: bant herkese yeniden gösterilir.",
                  en: "A visitor's choice is stored with this number. Raise it by one after a material change to the cookie policy: everyone is asked again.",
                },
              },
            },
          ],
        },
      ],
    },
  ],
  hooks: {
    beforeChange: [denyMakerEditPublishedGlobal, denyMakerPublishGlobal],
    afterChange: [revalidateGlobalTag("cookie-consent"), auditGlobalAfterChange("cookie-consent")],
  },
};
