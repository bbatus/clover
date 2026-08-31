/**
 * `ReferenceSource`/`REFERENCE_MAP` deliberately live here, not in
 * referentialIntegrity.ts — this file imports nothing from "payload", so
 * client components (MediaUsageField.tsx's "Kullanıldığı yerler" list) can
 * read the map directly without pulling referentialIntegrity.ts's
 * server-only `findReferences`/hook logic (and payload's whole runtime)
 * into the browser bundle. Found 31.08.2026 building with `next build
 * --webpack` (forced by a runner without native SWC bindings) — see
 * roleConstants.ts for the same pattern and the fuller writeup.
 *
 * RFP feedback 5.1 — "kategoriyi silerken önce ona bağlı kampanyayı silmem
 * lazımdı".
 *
 * Root cause: this CMS had ZERO `beforeDelete` hooks. Nothing checked
 * whether the document being deleted was still referenced by another
 * document, and Postgres doesn't backstop it either — Payload/drizzle
 * generates every relationship/upload FK as `ON DELETE SET NULL` (verified
 * against the live DB: `campaigns.category_id`, `campaigns.image_id`,
 * `blog_posts.cover_image_id`, … all 17 of them). So deleting a category
 * silently NULLed `campaigns.category_id` on every campaign in it, even
 * though that field is declared `required: true`. The campaign stayed
 * "published" but fell out of every category filter on the site — an
 * invisible data-integrity break with no error anywhere.
 *
 * This module is the one place that knows "who points at whom". Adding a
 * new relationship means adding ONE row to REFERENCE_MAP; the guard itself
 * never changes.
 */

export type ReferenceSource = {
  /** Collection that holds the reference. */
  collection: string;
  /**
   * Field path exactly as Payload's `where` addresses it — dot notation for
   * array/blocks subfields. Verified live that Payload resolves paths inside
   * polymorphic `blocks` arrays (`pages.layout.image`) and arrays nested in
   * blocks (`pages.layout.logos.logo`), so those are covered here rather
   * than left as a "might be used somewhere" warning.
   */
  path: string;
  /** Field used to name the offending document in the error message. */
  titleField: string;
  /**
   * `true` — deleting the target would leave this document referencing
   * nothing through a field its own schema declares `required`. Blocked.
   *
   * `false` — provenance metadata (who created / rejected / uploaded).
   * Losing it is not a content break, and blocking on it would make it
   * impossible to ever offboard a user who once touched anything. Reported
   * in the audit-log entry instead of blocking the delete.
   */
  blocking: boolean;
};

export const REFERENCE_MAP: Record<string, ReferenceSource[]> = {
  categories: [
    { collection: "campaigns", path: "category", titleField: "title", blocking: true },
    // BlogPosts.category became a relationship to this collection too — same
    // taxonomy as campaigns, so the same delete protection has to cover it.
    { collection: "blog-posts", path: "category", titleField: "title", blocking: true },
    // FaqItems.category — was a hardcoded select, now the same relationship.
    // Unlike Campaigns/BlogPosts this one is `required: true`, so deleting a
    // category out from under an FAQ wouldn't just leave it uncategorized —
    // it'd fail the field's own required check the next time anyone saved it.
    { collection: "faq-items", path: "category", titleField: "question", blocking: true },
  ],

  media: [
    { collection: "campaigns", path: "image", titleField: "title", blocking: true },
    { collection: "blog-posts", path: "coverImage", titleField: "title", blocking: true },
    { collection: "page-meta", path: "ogImage", titleField: "pageKey", blocking: true },
    { collection: "pages", path: "ogImage", titleField: "title", blocking: true },
    // `layout.image` and `layout.logos.logo` each match EVERY block sharing
    // that exact field path, not just one block type — Payload resolves a
    // `where` path inside a polymorphic `blocks` array across all variants
    // that declare it. `layout.image` alone already covers hero, howToEarn
    // and imageWithText (all three name their top-level image field
    // literally "image"); no separate entry needed for each.
    { collection: "pages", path: "layout.image", titleField: "title", blocking: true },
    { collection: "pages", path: "layout.logos.logo", titleField: "title", blocking: true },
    // Follow-up 30.08, from the user: found live that this map only covered
    // 3 of the 13 upload fields across the Pages block library — the other
    // 10 could be deleted out from under a live page with no warning and no
    // "Kullanıldığı Yerler" listing. Same reasoning as above: one entry per
    // distinct field PATH, not per block, so `layout.steps.image` alone
    // covers both `steps` (Adım Listesi) and `stepPhones` (Telefonlu
    // Tanıtım), which happen to name their array/field the same way.
    { collection: "pages", path: "layout.cards.icon", titleField: "title", blocking: true }, // iconCards
    { collection: "pages", path: "layout.steps.image", titleField: "title", blocking: true }, // steps, stepPhones
    { collection: "pages", path: "layout.steps.icon", titleField: "title", blocking: true }, // howToEarn
    { collection: "pages", path: "layout.media", titleField: "title", blocking: true }, // featureHighlights
    { collection: "pages", path: "layout.features.icon", titleField: "title", blocking: true }, // featureHighlights
    { collection: "pages", path: "layout.people.photo", titleField: "title", blocking: true }, // profileGrid
    { collection: "pages", path: "layout.backgroundImage", titleField: "title", blocking: true }, // mediaPanel
    { collection: "pages", path: "layout.sideImage", titleField: "title", blocking: true }, // imageTextSlides
    { collection: "pages", path: "layout.slides.image", titleField: "title", blocking: true }, // imageTextSlides
    { collection: "pages", path: "layout.darkBackgroundImage", titleField: "title", blocking: true }, // videoList
    { collection: "representatives", path: "qrCode", titleField: "businessName", blocking: true },
    { collection: "users", path: "avatar", titleField: "email", blocking: true },
    { collection: "legal-pages", path: "heroImage", titleField: "title", blocking: true },
  ],

  documents: [{ collection: "legal-pages", path: "groups.documents.file", titleField: "title", blocking: true }],

  users: [
    { collection: "campaigns", path: "createdBy", titleField: "title", blocking: false },
    { collection: "campaigns", path: "rejectedBy", titleField: "title", blocking: false },
    { collection: "media", path: "uploadedBy", titleField: "filename", blocking: false },
  ],
};
