import type { GlobalConfig } from "payload";
import { revalidateGlobalTag } from "@/hooks/revalidate";
import { auditGlobalAfterChange } from "@/hooks/audit";
import { authenticated } from "@/access/authenticated";
import { denyMakerEditPublishedGlobal, denyMakerPublishGlobal, standardReadWrite } from "@/access/roles";

/**
 * 17.09.2026 kullanıcı: "footer'ın arka planını, sticky QR görselini
 * yönetebileceğimiz alanlar CMS'te olsun; footer'daki aktif sayfaları,
 * blogları, kampanyaları buradan yönetebilsin; maker/checker onayı aynı olsun;
 * blog/kampanyadaki 'Footer'da Göster' ile senkron olsun."
 *
 * One record (a global) for what exists only once — background, QR visual,
 * LinkedIn link. The four link lists are deliberately NOT copied in here: the
 * FooterSyncPanel ui field shows and edits the records they already live on
 * (Menü Linkleri → footer-kurumsal / footer-yasal, Blog Yazıları and
 * Kampanyalar → showInFooter), so the footer screen and a blog post's own
 * "Footer'da Göster" box can never disagree — there is only one source.
 *
 * Maker→checker: drafts-enabled like every content collection. A Growth
 * Maker saves drafts; only a Checker (or New Vertical) publishes — the same
 * denyMakerPublish / denyMakerEditPublished rules, via their global wrappers.
 *
 * Every field is optional: an empty image falls back to the live site's own
 * asset (vodafonepaycomtr-site/public/images/footer/), so the footer never
 * renders without a background or QR visual.
 */
export const FooterSettings: GlobalConfig = {
  slug: "footer-settings",
  label: { tr: "Footer Yönetimi", en: "Footer Management" },
  admin: {
    hideAPIURL: true,
    group: { tr: "Site Yapısı", en: "Site Structure" },
    description: {
      tr: "Sitenin her sayfasının altındaki footer. Görseller ve LinkedIn bağlantısı bu kayıtta; link sütunları ise ilgili kayıtların kendisinden gelir (aşağıdaki panelde listelenir). Değişiklikler onaydan (yayınla) sonra sitede görünür.",
      en: "The footer at the bottom of every page. Images and the LinkedIn link live on this record; the link columns come from the records themselves (listed in the panel below). Changes show on the site once approved (published).",
    },
    components: {
      elements: {
        beforeDocumentControls: [{ path: "/components/HelpButton#default", clientProps: { collection: "footer-settings" } }],
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
      name: "linksPanel",
      type: "ui",
      admin: { components: { Field: "/components/FooterSyncPanel#default" } },
    },
    {
      name: "backgroundImage",
      type: "upload",
      relationTo: "media",
      label: { tr: "Arka Plan Görseli", en: "Background Image" },
      admin: {
        description: {
          tr: "Masaüstünde footer'ın tamamını kaplayan yatay görsel. Önerilen: 1280 × 480 px (keskin ekranlar için 2560 × 960 px), SVG, PNG veya JPG. Görsel sol kenardan hizalanır; sağ tarafı dar ekranlarda kırpılabilir, önemli öğeleri ortaya-sola koyun. Mobilde görsel yerine siyah→kırmızı geçiş gösterilir. Boş bırakılırsa sitenin varsayılan arka planı kullanılır.",
          en: "Landscape image covering the whole footer on desktop. Recommended: 1280 × 480 px (2560 × 960 px for sharp screens), SVG, PNG or JPG. Anchored to the left edge; the right side may be cropped on narrower screens. Mobile shows a black→red gradient instead. Left empty, the site's default background is used.",
        },
      },
    },
    {
      name: "qrImage",
      type: "upload",
      relationTo: "media",
      label: { tr: "QR Görseli", en: "QR Image" },
      admin: {
        description: {
          tr: "Footer'ın solundaki 'Pay indir' QR kartı (yalnızca masaüstünde görünür, 220 px genişlikte gösterilir). Dikey dikdörtgen olmalı — önerilen: 456 × 625 px PNG (şeffaf köşeli). Boş bırakılırsa sitenin varsayılan QR kartı kullanılır.",
          en: "The 'Pay indir' QR card on the left of the footer (desktop only, shown 220 px wide). Must be a portrait rectangle — recommended: 456 × 625 px PNG (transparent corners). Left empty, the site's default QR card is used.",
        },
      },
    },
    {
      name: "linkedinUrl",
      type: "text",
      label: { tr: "LinkedIn Adresi", en: "LinkedIn URL" },
      admin: {
        description: {
          tr: "Sol sütunun altındaki LinkedIn ikonunun gideceği adres. Boş bırakılırsa ikon gösterilmez.",
          en: "Where the LinkedIn icon under the left column links to. Left empty, the icon is hidden.",
        },
      },
    },
  ],
  hooks: {
    beforeChange: [denyMakerEditPublishedGlobal, denyMakerPublishGlobal],
    afterChange: [revalidateGlobalTag("footer-settings"), auditGlobalAfterChange("footer-settings")],
  },
};
