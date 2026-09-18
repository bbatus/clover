import type { CollectionConfig } from "payload";
import { revalidateTag, revalidateTagOnDelete } from "@/hooks/revalidate";
import { auditAfterChange, auditAfterDelete } from "@/hooks/audit";
import { authenticated, publishedOrAuthenticated, denyUnauthenticatedDraftRead } from "@/access/authenticated";
import { denyMakerEditPublished, denyMakerPublish, standardCreate, standardDelete, standardReadWrite } from "@/access/roles";
import { setOwnerOnCreate } from "@/hooks/ownership";
import { dbLabel } from "@/lib/collectionLabels";
import { assignNextOrder, orderField } from "@/hooks/ordering";
import { bulkActionsBar } from "@/lib/bulkActionRules";

export const Announcements: CollectionConfig = {
  slug: "announcements",
  labels: {
    singular: dbLabel("collectionLabel.announcements.singular", { tr: "Duyuru", en: "Announcement" }),
    plural: dbLabel("collectionLabel.announcements.plural", { tr: "Duyurular", en: "Announcements" }),
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
    defaultColumns: ["title", "order", "_status"],
    group: { tr: "İçerik Yönetimi", en: "Content Management" },
    components: {
      beforeListTable: [bulkActionsBar("announcements")],
      edit: {
        PublishButton: "/components/MakerAwarePublishButton#default",
        // Payload offers Unpublish only inside the ⋮ menu, which never renders
        // for a Checker and 403s for a Maker — see HideMenuUnpublishButton.
        UnpublishButton: "/components/HideMenuUnpublishButton#default",
        SaveDraftButton: "/components/SaveOrSubmitButton#default",
      },
      beforeList: [
        { path: "/components/HelpButton#default", clientProps: { collection: "announcements" } },
        { path: "/components/ReorderWidget#default", clientProps: { collection: "announcements" } },
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
      name: "title",
      type: "text",
      required: true,
      label: { tr: "Başlık", en: "Title" },
      admin: {
        description: {
          tr: "Örn: 18.08.2026 02:00-08:00 Vodafone Pay Planlı Altyapı Çalışması",
          en: "E.g.: 18.08.2026 02:00-08:00 Vodafone Pay Planned Infrastructure Maintenance",
        },
      },
    },
    {
      name: "body",
      type: "textarea",
      required: true,
      label: { tr: "Metin", en: "Body" },
      admin: { description: { tr: "Paragraflar arasına boş satır bırakın.", en: "Leave a blank line between paragraphs." } },
    },
    {
      name: "deeplink",
      type: "text",
      label: { tr: "Bağlantı (Deeplink)", en: "Deeplink" },
      admin: {
        description: {
          tr: "Örn: /kampanyalar/{slug} veya bir uygulama deeplink'i — verilirse duyuru tıklanabilir olur.",
          en: "E.g.: /kampanyalar/{slug} or an app deeplink — if set, the announcement becomes clickable.",
        },
      },
    },
    orderField({ collection: "announcements", mode: "flat" }),
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
    beforeChange: [setOwnerOnCreate("createdBy"), assignNextOrder("announcements"), denyMakerEditPublished, denyMakerPublish],
    afterChange: [revalidateTag("announcements"), auditAfterChange("announcements")],
    afterDelete: [revalidateTagOnDelete("announcements"), auditAfterDelete("announcements")],
  },
};
