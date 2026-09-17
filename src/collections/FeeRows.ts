import type { CollectionConfig } from "payload";
import { denyMakerEditPublished, denyMakerPublish, standardCreate, standardDelete, standardReadWrite } from "@/access/roles";
import { authenticated, publishedOrAuthenticated, denyUnauthenticatedDraftRead } from "@/access/authenticated";
import { revalidateTag, revalidateTagOnDelete } from "@/hooks/revalidate";
import { auditAfterChange, auditAfterDelete } from "@/hooks/audit";
import { setOwnerOnCreate } from "@/hooks/ownership";
import { dbLabel } from "@/lib/collectionLabels";
import { assignNextOrder, orderField } from "@/hooks/ordering";

type FeeRowSibling = { rowType?: string | null };

const isBlank = (v: unknown) => v == null || (typeof v === "string" && v.trim() === "");

/** A note row has no label of its own — every other row type needs one. */
export const requiredUnlessNote = (value: unknown, { siblingData }: { siblingData?: FeeRowSibling }) =>
  siblingData?.rowType === "note" || !isBlank(value) || "Bu alan zorunludur.";

/** Only a plain fee row carries a value; headings and notes don't. */
export const requiredForFeeRow = (value: unknown, { siblingData }: { siblingData?: FeeRowSibling }) =>
  (siblingData?.rowType ?? "fee") !== "fee" || !isBlank(value) || "Bu alan zorunludur.";

/** An empty Lexical state still has a root with one empty paragraph — treat that as blank. */
export const requiredForNote = (value: unknown, { siblingData }: { siblingData?: FeeRowSibling }) => {
  if (siblingData?.rowType !== "note") return true;
  const text = JSON.stringify((value as { root?: unknown } | null)?.root ?? "").match(/"text":"([^"]*)"/g);
  return (text ?? []).some((t) => t.length > '"text":""'.length) || "Bu alan zorunludur.";
};

export const FeeRows: CollectionConfig = {
  slug: "fee-rows",
  labels: {
    singular: dbLabel("collectionLabel.fee-rows.singular", { tr: "Ücret Satırı", en: "Fee Row" }),
    plural: dbLabel("collectionLabel.fee-rows.plural", { tr: "Ücret Tablosu", en: "Fee Rows" }),
  },
  // RFP feedback 5.5: the list must reflect the `order` field (and the
  // drag-to-reorder widget's saved sequence), not Payload's fallback order.
  defaultSort: "order",
  admin: {
    hideAPIURL: true,
    useAsTitle: "label",
    defaultColumns: ["label", "rowType", "value", "order"],
    group: { tr: "Ücretler & Limitler", en: "Fees & Limits" },
    // RFP follow-up: /admin/fees-and-limits (FeesAndLimitsView.tsx) is the
    // ONLY entry point now — `hidden: true` removes this collection from
    // the sidebar AND 404s its own /admin/collections/fee-rows routes
    // (confirmed live: Payload's List/Document views check
    // `visibleEntities`, which `getVisibleEntities` excludes hidden
    // collections from). That's fine here because FeesAndLimitsApp no
    // longer links to those routes — it edits/creates fee-rows through
    // `useDocumentDrawer`, which defaults `overrideEntityVisibility: true`
    // and bypasses that exact check.
    components: {
      edit: {
        PublishButton: "/components/MakerAwarePublishButton#default",
        // Payload offers Unpublish only inside the ⋮ menu, which never renders
        // for a Checker and 403s for a Maker — see HideMenuUnpublishButton.
        UnpublishButton: "/components/HideMenuUnpublishButton#default",
        SaveDraftButton: "/components/SaveOrSubmitButton#default",
      },
    },
    hidden: true,
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
    /**
     * 17.09.2026 — kullanıcı: "canlıdaki /ucretler-ve-limitler sayfasını
     * TIPATIP biz de üretebilmeliyiz". Canlı tablo tek bir zengin metin
     * bloğu; içinde düz satırların yanında (1) tablonun içinde büyük kalın
     * ara başlık satırları ("ATM'den Para Çekme"), (2) çok satırlı değerler
     * (Geç Tahsilat Bedeli'nin kademeleri), (3) yeşil "Ücretsiz" değerleri ve
     * (4) tablonun ALTINDA linkli bir not var. Eski label/value çifti
     * bunların hiçbirini ifade edemiyordu. Serbest zengin metin tablosu
     * yerine satır türü eklendi: editör yine satır satır çalışıyor, sıralama/
     * taslak/onay akışı aynen geçerli, ama sayfanın dört parçası da
     * üretilebiliyor.
     */
    {
      name: "rowType",
      type: "select",
      defaultValue: "fee",
      label: { tr: "Satır Türü", en: "Row Type" },
      options: [
        { label: { tr: "Ücret satırı", en: "Fee row" }, value: "fee" },
        { label: { tr: "Ara başlık (tablo içinde, büyük kalın yazı)", en: "Section heading (inside the table, large bold)" }, value: "heading" },
        { label: { tr: "Tablo altı not", en: "Note below the table" }, value: "note" },
      ],
      admin: {
        description: {
          tr: "Ücret satırı: solda ad, sağda değer. Ara başlık: tablonun içinde, altındaki satırları gruplayan büyük kalın başlık (örn. 'ATM’den Para Çekme') — değer almaz. Tablo altı not: tablonun altında düz metin olarak görünür, link içerebilir (örn. 'Ücretlerde değişiklik yapma hakkı…').",
          en: "Fee row: name on the left, value on the right. Section heading: a large bold heading inside the table grouping the rows below it (e.g. 'ATM’den Para Çekme') — takes no value. Note: shown as plain text below the table, may contain links.",
        },
      },
    },
    {
      name: "label",
      type: "text",
      label: { tr: "Etiket", en: "Label" },
      validate: requiredUnlessNote,
      admin: {
        condition: (_, sibling) => sibling?.rowType !== "note",
      },
    },
    {
      name: "value",
      type: "textarea",
      label: { tr: "Değer", en: "Value" },
      validate: requiredForFeeRow,
      admin: {
        condition: (_, sibling) => (sibling?.rowType ?? "fee") === "fee",
        description: {
          tr: "Birden fazla satır yazabilirsiniz; boş bir satır bırakmak araya boşluk koyar (örn. gecikme kademeleri).",
          en: "You can write several lines; an empty line adds a gap (e.g. late-payment tiers).",
        },
      },
    },
    {
      name: "highlightValue",
      type: "checkbox",
      defaultValue: false,
      label: { tr: "Değeri yeşil göster", en: "Show value in green" },
      admin: {
        condition: (_, sibling) => (sibling?.rowType ?? "fee") === "fee",
        description: { tr: "Canlı sitedeki yeşil 'Ücretsiz' görünümü.", en: "The live site's green 'Ücretsiz' style." },
      },
    },
    {
      name: "note",
      type: "richText",
      label: { tr: "Not", en: "Note" },
      validate: requiredForNote,
      admin: {
        condition: (_, sibling) => sibling?.rowType === "note",
        description: {
          tr: "Tablonun altında görünen metin. Link eklemek için metni seçip link butonunu kullanın. Her paragraf arasında bir satır boşluk bırakılır.",
          en: "Text shown below the table. Select text and use the link button to add a link. Paragraphs are separated by one blank line.",
        },
      },
    },
    orderField({ collection: "fee-rows", mode: "flat" }),
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
    beforeChange: [setOwnerOnCreate("createdBy"), assignNextOrder("fee-rows"), denyMakerEditPublished, denyMakerPublish],
    afterChange: [revalidateTag("fee-rows"), auditAfterChange("fee-rows")],
    afterDelete: [revalidateTagOnDelete("fee-rows"), auditAfterDelete("fee-rows")],
  },
};
