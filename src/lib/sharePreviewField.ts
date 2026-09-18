import type { Field } from "payload";

/** 18.09.2026 — "Önizleme linki paylaş" sidebar panel (components/SharePreviewPanel.tsx, collections/ShareLinks.ts). */
export const sharePreviewField: Field = {
  name: "sharePreview",
  type: "ui",
  admin: {
    position: "sidebar",
    components: { Field: "/components/SharePreviewPanel#default" },
  },
};
