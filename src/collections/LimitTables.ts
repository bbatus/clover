import type { CollectionConfig } from "payload";
import { denyMakerEditPublished, denyMakerPublish, standardCreate, standardDelete, standardReadWrite } from "@/access/roles";
import { authenticated, publishedOrAuthenticated, denyUnauthenticatedDraftRead } from "@/access/authenticated";
import { revalidateTag, revalidateTagOnDelete } from "@/hooks/revalidate";
import { auditAfterChange, auditAfterDelete } from "@/hooks/audit";
import { setOwnerOnCreate } from "@/hooks/ownership";
import { dbLabel } from "@/lib/collectionLabels";
import { assignNextOrder, orderField } from "@/hooks/ordering";
import { bulkActionsBar } from "@/lib/bulkActionRules";

export const LimitTables: CollectionConfig = {
  slug: "limit-tables",
  labels: {
    singular: dbLabel("collectionLabel.limit-tables.singular", { tr: "Limit Tablosu", en: "Limit Table" }),
    plural: dbLabel("collectionLabel.limit-tables.plural", { tr: "Limit Tabloları", en: "Limit Tables" }),
  },
  // RFP feedback 5.5: the list must reflect the `order` field (and the
  // drag-to-reorder widget's saved sequence), not Payload's fallback order.
  defaultSort: "order",
  // Toplu işlemler (18.09.2026): Payload's own bulk Edit/Publish/Unpublish/Delete
  // only know collection access, not our maker→checker hooks — replaced by
  // BulkActionsBar + /api/bulk-actions (lib/bulkActions.ts).
  disableBulkEdit: true,
  disableBulkDelete: true,
  admin: {
    hideAPIURL: true,
    useAsTitle: "title",
    defaultColumns: ["title", "order"],
    group: { tr: "Ücretler & Limitler", en: "Fees & Limits" },
    // RFP follow-up: see the longer comment in FeeRows.ts — hidden here too,
    // with editing/creating routed through FeesAndLimitsApp's
    // useDocumentDrawer instead of a direct /admin/collections/limit-tables
    // link.
    components: {
      beforeListTable: [bulkActionsBar("limit-tables")],
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
    { name: "title", type: "text", required: true, label: { tr: "Başlık", en: "Title" } },
    orderField({ collection: "limit-tables", mode: "flat" }),
    {
      name: "rows",
      type: "array",
      required: true,
      minRows: 1,
      label: { tr: "Satırlar", en: "Rows" },
      labels: { singular: { tr: "Satır", en: "Row" }, plural: { tr: "Satırlar", en: "Rows" } },
      fields: [
        { name: "category", type: "text", required: true, label: { tr: "Kategori", en: "Category" } },
        { name: "period", type: "text", required: true, label: { tr: "Dönem", en: "Period" } },
        { name: "unverifiedLimit", type: "text", required: true, label: { tr: "Kimliği Doğrulanmamış Limit", en: "Unverified Limit" } },
        { name: "verifiedLimit", type: "text", required: true, label: { tr: "Kimliği Doğrulanmış Limit", en: "Verified Limit" } },
      ],
    },
    {
      // 17.09.2026: canlıdaki "*Faturana Yansıt limitleriniz her ayın
      // 1'inde yenilenir." notu — tablonun hemen altında düz metin.
      name: "footnote",
      type: "textarea",
      label: { tr: "Tablo Altı Not", en: "Footnote" },
      admin: {
        description: {
          tr: "Opsiyonel. Bu tablonun hemen altında küçük düz metin olarak görünür, örn. '*Faturana Yansıt limitleriniz her ayın 1'inde yenilenir.'",
          en: "Optional. Shown as plain text right below this table.",
        },
      },
    },
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
    beforeChange: [setOwnerOnCreate("createdBy"), assignNextOrder("limit-tables"), denyMakerEditPublished, denyMakerPublish],
    afterChange: [revalidateTag("limit-tables"), auditAfterChange("limit-tables")],
    afterDelete: [revalidateTagOnDelete("limit-tables"), auditAfterDelete("limit-tables")],
  },
};
