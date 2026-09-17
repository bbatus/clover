import type { CollectionConfig } from "payload";
import { revalidateTag, revalidateTagOnDelete } from "@/hooks/revalidate";
import { auditAfterChange, auditAfterDelete } from "@/hooks/audit";
import { authenticated, publishedOrAuthenticated, denyUnauthenticatedDraftRead } from "@/access/authenticated";
import { denyMakerEditPublished, denyMakerPublish, standardCreate, standardDelete, standardReadWrite } from "@/access/roles";
import { setOwnerOnCreate } from "@/hooks/ownership";
import { dbLabel } from "@/lib/collectionLabels";
import { assignNextOrder, orderField } from "@/hooks/ordering";
import { CATEGORY_SCOPES } from "@/collections/Categories";

export const FaqItems: CollectionConfig = {
  slug: "faq-items",
  labels: {
    singular: dbLabel("collectionLabel.faq-items.singular", { tr: "Sık Sorulan Soru", en: "FAQ Item" }),
    plural: dbLabel("collectionLabel.faq-items.plural", { tr: "Sık Sorulanlar", en: "FAQ Items" }),
  },
  // RFP follow-up: was `defaultSort: "order"` (RFP feedback 5.5) — that's
  // still exactly right for the SITE (getFaqItems sorts by `order`, unchanged),
  // but for the ADMIN LIST it meant a newly-created question could land
  // anywhere in a long "order" sequence instead of being easy to find right
  // after creating it. Admin list now shows newest-first; the site's own
  // visitor-facing order is untouched — see `order`'s own field comment.
  defaultSort: "-createdAt",
  admin: {
    hideAPIURL: true,
    useAsTitle: "question",
    defaultColumns: ["question", "category", "order", "createdAt", "_status"],
    group: { tr: "İçerik Yönetimi", en: "Content Management" },
    components: {
      edit: {
        PublishButton: "/components/MakerAwarePublishButton#default",
        // Payload offers Unpublish only inside the ⋮ menu, which never renders
        // for a Checker and 403s for a Maker — see HideMenuUnpublishButton.
        UnpublishButton: "/components/HideMenuUnpublishButton#default",
        SaveDraftButton: "/components/SaveOrSubmitButton#default",
      },
      beforeList: [
        { path: "/components/HelpButton#default", clientProps: { collection: "faq-items" } },
        {
          path: "/components/ReorderWidget#default",
          clientProps: {
            collection: "faq-items",
            groupField: "category",
            // Group list (with per-category counts) comes from the server,
            // including categories with 0 or 1 question — see ReorderWidget's
            // `groupsFrom` doc comment for why this replaced the old
            // fetch-all-200-then-group-client-side approach.
            groupsFrom: { collection: "categories", where: { scope: { equals: CATEGORY_SCOPES.FAQ } } },
          },
        },
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
    { name: "question", type: "text", required: true, label: { tr: "Soru", en: "Question" } },
    {
      // 17.09.2026: was a plain textarea. The live vodafonepay.com.tr answers
      // carry bold sub-headings, lists and tables (e.g. "Anında Bakiye ile
      // yapacağım işlemlerde bir limit var mıdır?"), none of which a textarea
      // can hold — so the site could not reproduce them. Existing answers were
      // converted paragraph-for-paragraph by
      // scripts/clover-schema-migration-02-09-to-17-09-2026.sql §7.
      name: "answer",
      type: "richText",
      required: true,
      label: { tr: "Cevap", en: "Answer" },
      admin: {
        description: {
          tr: "Sitede soru açıldığında görünen metin. Kalın yazı, liste, tablo ve link ekleyebilirsiniz.",
          en: "Text shown on the site when the question is opened. Bold text, lists, tables and links are supported.",
        },
      },
    },
    {
      // RFP §3.1.7: "Each content item should have a deeplink field in
      // order to enable redirection." An FAQ answer is often "see the full
      // details here" — rendered as an optional link under the answer text
      // in the shared Faq.tsx accordion component on the site.
      name: "deeplink",
      type: "text",
      label: { tr: "İlgili Bağlantı", en: "Related Link" },
      admin: {
        description: {
          tr: "Opsiyonel — cevabın altında gösterilecek ilgili bir sayfa bağlantısı, örn: /vodafone-pay-kart",
          en: "Optional — a related page link shown below the answer, e.g. /vodafone-pay-kart",
        },
      },
    },
    {
      // Was a hardcoded `select` (fixed option list baked into code, same
      // problem Campaigns/BlogPosts.category had before their own
      // Categories migration — RFP feedback 1.3). Every product page fetches
      // its FAQ block by category slug (see src/app/*/page.tsx's
      // `getFaqItems("<slug>")` calls on the site) and the SSS page's tabs
      // are keyed off the same slugs, so adding a category here (Kategoriler
      // → Oluştur) is what makes both the product page's FAQ block and a new
      // /sikca-sorulan-sorular?kategori=<slug> tab exist — no code change,
      // no developer needed.
      name: "category",
      type: "relationship",
      relationTo: "categories",
      required: true,
      label: { tr: "Kategori", en: "Category" },
      // Categories is shared with Campaigns/BlogPosts now — `scope` keeps
      // this picker from also offering their (unrelated) categories. See
      // Categories.ts for why this has to be a separate list at all.
      filterOptions: () => ({ scope: { equals: CATEGORY_SCOPES.FAQ } }),
      admin: {
        description: {
          tr: "Bu sorunun hangi ürün sayfasında ve /sikca-sorulan-sorular sekmesinde görüneceğini belirler (SSS akışındaki kategoriler). Listede yoksa Kategoriler'e gidip 'Akış: Sık Sorulan Sorular' ile yeni bir tane oluşturun.",
          en: "Determines which product page and /sikca-sorulan-sorular tab this question shows on (categories in the FAQ flow). If it's not in the list, go to Categories and create one with 'Flow: FAQ'.",
        },
      },
    },
    orderField({ collection: "faq-items", watchPath: "category", mode: "relationship" }),
    // 17.09.2026 (kullanıcı kararı): `showInFooter` / `footerOrder` kaldırıldı.
    // Canlı vodafonepay.com.tr footer'ında "Sık Sorulanlar" sütunu yok; sitenin
    // footer'ı canlıyla eşitlenince bu kutu hiçbir yerde render edilmez olacaktı
    // (AGENTS.md: render edilmeyen alan bırakma). Kolonlar
    // clover-schema-migration-02-09-to-17-09-2026.sql §10'da düşürülüyor.
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
      assignNextOrder("faq-items", ["category"]),
      denyMakerEditPublished,
      denyMakerPublish,
    ],
    afterChange: [revalidateTag("faq-items"), auditAfterChange("faq-items")],
    afterDelete: [revalidateTagOnDelete("faq-items"), auditAfterDelete("faq-items")],
  },
};
