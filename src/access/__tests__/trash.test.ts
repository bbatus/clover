import { describe, expect, it, vi } from "vitest";
import type { Access, CollectionConfig, PayloadRequest } from "payload";
import { requireTrashedBeforeDelete, trashAwareDelete, withTrash } from "@/access/trash";
import { ROLES } from "@/access/roleConstants";

const req = (role?: string, doc?: Record<string, unknown> | null) =>
  ({
    user: role ? { id: 7, role } : undefined,
    i18n: { language: "tr" },
    payload: { findByID: vi.fn(async () => doc) },
  }) as unknown as PayloadRequest;

const ownDrafts: Access = ({ req: r }) =>
  (r.user as { role?: string } | undefined)?.role === ROLES.GROWTH_MAKER ? { createdBy: { equals: 7 } } : (r.user as { role?: string } | undefined)?.role === ROLES.NEW_VERTICAL_MAKER;

describe("geri dönüşüm kutusu (19.09.2026)", () => {
  const access = trashAwareDelete(ownDrafts);

  it("moving to the trash follows the collection's own delete rule", () => {
    expect(access({ req: req(ROLES.GROWTH_MAKER), data: { deletedAt: "now" } } as never)).toEqual({ createdBy: { equals: 7 } });
    expect(access({ req: req(ROLES.GROWTH_CHECKER), data: { deletedAt: "now" } } as never)).toBe(false);
    expect(access({ req: req(ROLES.NEW_VERTICAL_MAKER), data: { deletedAt: "now" } } as never)).toBe(true);
  });

  it("the permanent-delete question (data without deletedAt) is New Vertical Maker only", () => {
    expect(access({ req: req(ROLES.GROWTH_MAKER), data: {} } as never)).toBe(false);
    expect(access({ req: req(ROLES.NEW_VERTICAL_MAKER), data: {} } as never)).toBe(true);
  });

  it("the role's permission map (no data) keeps the collection rule, so trash buttons still show", () => {
    expect(access({ req: req(ROLES.GROWTH_MAKER) } as never)).toEqual({ createdBy: { equals: 7 } });
  });

  it("refuses a permanent delete by anyone but a New Vertical Maker", async () => {
    await expect(
      requireTrashedBeforeDelete({ req: req(ROLES.GROWTH_MAKER, { deletedAt: "x" }), id: 1, collection: { slug: "pages" } } as never)
    ).rejects.toThrow(/yalnız New Vertical Maker/);
  });

  it("refuses a permanent delete of a record that isn't in the trash", async () => {
    await expect(
      requireTrashedBeforeDelete({ req: req(ROLES.NEW_VERTICAL_MAKER, { deletedAt: null }), id: 1, collection: { slug: "pages" } } as never)
    ).rejects.toThrow(/önce çöp kutusuna/);
    await expect(
      requireTrashedBeforeDelete({ req: req(ROLES.NEW_VERTICAL_MAKER, { deletedAt: "2026-09-19" }), id: 1, collection: { slug: "pages" } } as never)
    ).resolves.toBeUndefined();
  });

  it("withTrash turns the trash on and keeps the collection's own hooks", () => {
    const own = vi.fn();
    const c = withTrash({ slug: "pages", fields: [], access: { delete: ownDrafts }, hooks: { beforeDelete: [own] } } as CollectionConfig);
    expect(c.trash).toBe(true);
    expect(c.hooks?.beforeDelete).toEqual([requireTrashedBeforeDelete, own]);
  });
});
