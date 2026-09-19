import { APIError, type Access, type CollectionBeforeDeleteHook, type CollectionConfig } from "payload";
import { ROLES } from "./roleConstants";

/**
 * 19.09.2026 — geri dönüşüm kutusu. Kullanıcı: "geri dönüşüm kutusu yap
 * evet" + "denetim gereği 10 yıl bir şey silmeyeceğiz".
 *
 * Payload's own trash (`trash: true`, 3.x): deleting moves a record to the
 * collection's Çöp view (a `deletedAt` stamp); the site stops showing it at
 * once (every read excludes trashed rows, and the afterChange revalidate
 * hooks fire on the stamp like on any update). From the Çöp view it can be
 * restored, which needs only update access — so a Checker can undo a
 * Maker's mistake.
 *
 * Nothing leaves the database on its own: there is no automatic purge. A
 * permanent delete is a deliberate second step, allowed only
 * - for a record that is already in the trash (no "skip the trash" route —
 *   Payload's "Çöpü atlayın ve kalıcı olarak silin" checkbox is hidden in
 *   custom.css and refused here), and
 * - to a New Vertical Maker (the developer role), e.g. for a KVKK erasure
 *   request; every such delete is in the audit log.
 */

/**
 * Wraps a collection's delete access so Payload's admin shows the right
 * controls. Payload asks delete access three ways:
 * - with `data.deletedAt` set: "may this user move it to the trash?" → the
 *   collection's own rule (Growth Maker: only their own drafts);
 * - with `data` present but no `deletedAt` (document/list views asking
 *   about a permanent delete) → New Vertical Maker only;
 * - with no `data` at all (the role's permission map, and the permanent
 *   delete operation itself) → the collection's rule; the operation is
 *   then held by `requireTrashedBeforeDelete` below.
 */
export function trashAwareDelete(inner: Access | undefined): Access {
  return (args) => {
    const allowed = inner ? inner(args) : Boolean(args.req.user);
    const data = args.data as { deletedAt?: unknown } | undefined;
    if (data === undefined || data === null) return allowed;
    if (data.deletedAt) return allowed;
    return (args.req.user as { role?: string } | null | undefined)?.role === ROLES.NEW_VERTICAL_MAKER ? allowed : false;
  };
}

export const requireTrashedBeforeDelete: CollectionBeforeDeleteHook = async ({ req, id, collection }) => {
  const english = req.i18n?.language === "en";
  const role = (req.user as { role?: string } | null | undefined)?.role;
  if (req.user && role !== ROLES.NEW_VERTICAL_MAKER) {
    throw new APIError(
      english
        ? "Only a New Vertical Maker can delete permanently. Records stay in the trash and can be restored."
        : "Kalıcı silme yalnız New Vertical Maker rolüne açıktır. Kayıtlar çöp kutusunda kalır, geri alınabilir.",
      403,
      undefined,
      true
    );
  }
  const doc = (await req.payload.findByID({
    collection: collection.slug as never,
    id,
    depth: 0,
    trash: true,
    overrideAccess: true,
    req,
  }).catch(() => null)) as { deletedAt?: string | null } | null;
  if (doc && !doc.deletedAt) {
    throw new APIError(
      english
        ? "Move the record to the trash first; it can be deleted permanently only from there."
        : "Kayıt önce çöp kutusuna taşınmalı; kalıcı silme yalnız çöp kutusundan yapılır.",
      403,
      undefined,
      true
    );
  }
};

/** Turns the trash on for a collection, with the rules above. Applied in payload.config.ts to every draft-enabled collection. */
export function withTrash(collection: CollectionConfig): CollectionConfig {
  return {
    ...collection,
    trash: true,
    access: { ...collection.access, delete: trashAwareDelete(collection.access?.delete) },
    hooks: { ...collection.hooks, beforeDelete: [requireTrashedBeforeDelete, ...(collection.hooks?.beforeDelete ?? [])] },
  };
}
