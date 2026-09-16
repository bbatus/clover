import type { CollectionConfig } from "payload";
import { denyMakerEditPublished, denyMakerPublish, standardCreate, standardDelete, standardReadWrite } from "@/access/roles";
import { authenticated, publishedOrAuthenticated, denyUnauthenticatedDraftRead } from "@/access/authenticated";
import { revalidateTag, revalidateTagOnDelete } from "@/hooks/revalidate";
import { auditAfterChange, auditAfterDelete } from "@/hooks/audit";
import { setOwnerOnCreate } from "@/hooks/ownership";
import { dbLabel } from "@/lib/collectionLabels";
import { assignNextOrder, orderField, rejectIfGroupFull, FOOTER_ORDER_MAX } from "@/hooks/ordering";

const NAV_LINK_FOOTER_SECTION_LIMITS = {
  "footer-kurumsal": FOOTER_ORDER_MAX,
  "footer-yasal": FOOTER_ORDER_MAX,
};

export const NavLinks: CollectionConfig = {
  slug: "nav-links",
  labels: {
    singular: dbLabel("collectionLabel.nav-links.singular", { tr: "Menü Linki", en: "Nav Link" }),
    plural: dbLabel("collectionLabel.nav-links.plural", { tr: "Menü Linkleri", en: "Nav Links" }),
  },
  // RFP feedback 5.5: the list must reflect the `order` field (and the
  // drag-to-reorder widget's saved sequence), not Payload's fallback order.
  defaultSort: "order",
  admin: {
    hideAPIURL: true,
    useAsTitle: "label",
    // Walkthrough 29.08: every drafts-enabled collection needs `_status` in the
    // default columns — without it a draft is indistinguishable from a live
    // record in the list, which is the one thing the list has to tell you.
    defaultColumns: ["label", "href", "section", "order", "_status"],
    group: { tr: "Site Yapısı", en: "Site Structure" },
    components: {
      edit: {
        PublishButton: "/components/MakerAwarePublishButton#default",
        // Payload offers Unpublish only inside the ⋮ menu, which never renders
        // for a Checker and 403s for a Maker — see HideMenuUnpublishButton.
        UnpublishButton: "/components/HideMenuUnpublishButton#default",
        SaveDraftButton: "/components/SaveOrSubmitButton#default",
      },
      beforeList: [
        { path: "/components/HelpButton#default", clientProps: { collection: "nav-links" } },
        { path: "/components/ReorderWidget#default", clientProps: { collection: "nav-links", groupField: "section" } },
      ],
    },
  },
  versions: {
    drafts: true,
  },
  access: {
    read: publishedOrAuthenticated,
    readVersions: authenticated,
    create: standardCreate,
    update: standardReadWrite,
    delete: standardDelete,
  },
  fields: [
    {
      name: "label",
      type: "text",
      required: true,
      label: { tr: "Etiket", en: "Label" },
      admin: {
        description: {
          tr: "Menüde/footer'da görünecek yazı, örn: 'Vodafone Pay Kart'.",
          en: "Text shown in the menu/footer, e.g.: 'Vodafone Pay Kart'.",
        },
      },
    },
    {
      name: "href",
      type: "text",
      required: true,
      label: { tr: "Adres (href)", en: "Href" },
      admin: {
        description: {
          tr: "Tıklanınca gidilecek adres. İç sayfa için başında / olacak şekilde yazın (örn. /vodafone-pay-kart veya, Pages'te oluşturduğunuz bir sayfa için /{o sayfanın slug'ı}); dış bağlantı için https:// ile başlayın (örn. Bilgi Toplum Hizmetleri linki gibi). Bu alan HERHANGİ bir adresi kabul eder — geliştirici sitedeki mevcut sayfaların adres listesini size verebilir.",
          en: "Address to go to when clicked. For an internal page start with / (e.g. /vodafone-pay-kart, or /{that page's slug} for a page you created in Pages); for an external link start with https:// (e.g. the Bilgi Toplum Hizmetleri link). This field accepts ANY address — a developer can give you the list of the site's existing page addresses.",
        },
      },
    },
    {
      // RFP §3.2.2: "editable desktop and mobile URLs" — optional per-link
      // override, only reached by the mobile drawer (HeaderClient.tsx).
      // Empty (the expected case for virtually every link, since the site
      // is one responsive URL, not a separate mobile site) means desktop
      // and mobile keep using the exact same `href` — nothing changes.
      name: "mobileHref",
      type: "text",
      label: { tr: "Mobil URL (opsiyonel)", en: "Mobile URL (optional)" },
      admin: {
        description: {
          tr: "Boş bırakılırsa mobilde de yukarıdaki adres (href) kullanılır. Sadece mobil cihazlarda FARKLI bir adrese göndermek istiyorsanız (örn. bir uygulama deeplink'i) doldurun.",
          en: "If left empty, mobile uses the same address (href) as above. Fill this in only if mobile devices should go somewhere DIFFERENT (e.g. an app deeplink).",
        },
      },
    },
    {
      name: "section",
      type: "select",
      required: true,
      label: { tr: "Bölüm", en: "Section" },
      admin: {
        description: {
          tr: `Bu link NEREDE görünecek? Header — Ana Menü = üst menünün 'Ürünler' dışındaki kısmı (Kampanyalar, Blog vb.). Footer — Kurumsal/Yasal, footer'daki o iki sütuna karşılık gelir ve her biri en fazla ${FOOTER_ORDER_MAX} link alabilir (footer'ın taşmaması için) — dolu bir sütuna yenisini eklemek isterseniz önce var olan birini silmeniz gerekir. ÜST MENÜDEKİ 'ÜRÜNLER' AÇILIR LİSTESİ ARTIK BURADAN YÖNETİLMİYOR: bir sayfayı oraya koymak için Sayfalar'daki o kaydı açıp "'Ürünler' Menüsünde Göster" kutusunu işaretleyin. Footer'daki 'Sık Sorulanlar' ve 'Kampanyalar' sütunları da aynı şekilde ilgili kaydın kendi 'Footer'da Göster' kutusundan yönetiliyor (onlar da aynı ${FOOTER_ORDER_MAX} sınırına tabi). Bir linki KALDIRMAK için bu kaydı silin; SIRASINI değiştirmek için listedeki sürükle-bırak aracını kullanın.`,
          en: `WHERE will this link appear? Header — Ana Menü = the top menu apart from 'Ürünler' (Kampanyalar, Blog, etc.). Footer — Kurumsal/Yasal correspond to those two footer columns, and each one holds at most ${FOOTER_ORDER_MAX} links (so the footer doesn't overflow) — to add another to a full column, delete an existing one first. THE 'ÜRÜNLER' DROPDOWN IS NO LONGER MANAGED HERE: to put a page in it, open that record in Pages and tick "Show in the 'Products' Menu". The footer's 'Sık Sorulanlar' and 'Kampanyalar' columns work the same way — the 'Show in Footer' checkbox on the relevant FAQ/Campaign record (same ${FOOTER_ORDER_MAX} limit applies there too). To REMOVE a link, delete this record; to reorder, use the drag-and-drop tool on the list.`,
        },
      },
      /**
       * 16.09.2026 — `header-products` KALDIRILDI (kullanıcı kararı).
       *
       * 'Ürünler' açılır listesinin İKİ kaynağı vardı: buradaki bu seçenek ve
       * Pages'in kendi `showInProductsMenu` kutusu. Header.tsx ikisini
       * birleştiriyor ama href'e göre tekilleştirmiyordu — yani aynı adresi
       * hem buraya bir link olarak hem de o sayfanın kendi kutusuyla ekleyen
       * editör menüde AYNI sayfayı iki kez görüyordu (kullanıcı tarafından
       * canlıda yaşandı). Tekilleştirme eklemek yerine ikinci kaynağı
       * kaldırdık: artık tek yol Pages'in kendi kutusu, çakışma yapısal
       * olarak imkânsız.
       *
       * Kaybedilen tek yetenek: 'Ürünler' menüsüne bir DIŞ bağlantı veya
       * Pages dokümanı olmayan elle yazılmış bir rota koymak. Kaldırıldığı
       * gün menüde ikisinden de yoktu (mevcut 3 kayıt — vodafone-pay-uygulama,
       * vodafone-pay-kart, faturana-yansit — zaten üçü de Pages dokümanıydı,
       * migration'la kendi kutularına taşındılar). Gerçekten gerekirse
       * seçeneği geri eklemek birkaç satır; o zaman Header.tsx'e href bazlı
       * tekilleştirme de gerekir.
       *
       * Postgres tarafında `enum_nav_links_section` tipinden `header-products`
       * değeri SİLİNMEDİ — Postgres enum değeri düşürmeyi desteklemiyor
       * (tipi yeniden yaratmak gerekir) ve kullanılmayan bir değer zararsız.
       */
      options: [
        { label: { tr: "Header — Ana Menü", en: "Header — Main Menu" }, value: "header-main" },
        { label: { tr: "Footer — Kurumsal", en: "Footer — Corporate" }, value: "footer-kurumsal" },
        { label: { tr: "Footer — Yasal", en: "Footer — Legal" }, value: "footer-yasal" },
      ],
    },
    orderField({ collection: "nav-links", watchPath: "section", mode: "relationship" }),
    {
      name: "createdBy",
      type: "relationship",
      relationTo: "users",
      label: { tr: "Oluşturan", en: "Created By" },
      admin: { position: "sidebar", readOnly: true },
    },
  ],
  hooks: {
    beforeOperation: [denyUnauthenticatedDraftRead],
    beforeChange: [
      setOwnerOnCreate("createdBy"),
      rejectIfGroupFull({ collection: "nav-links", scopeField: "section", limits: NAV_LINK_FOOTER_SECTION_LIMITS }),
      assignNextOrder("nav-links", ["section"]),
      denyMakerEditPublished,
      denyMakerPublish,
    ],
    afterChange: [revalidateTag("nav-links"), auditAfterChange("nav-links")],
    afterDelete: [revalidateTagOnDelete("nav-links"), auditAfterDelete("nav-links")],
  },
};
