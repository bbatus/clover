import { describe, expect, it } from "vitest";
import { classifyTrashBulk } from "@/lib/trashBulk";

const u = (path: string) => new URL(`http://cms.local${path}`);
const W = "where%5Bid%5D%5Bequals%5D=15";

describe("trash bulk requests (19.09.2026)", () => {
  it("recognises Payload's restore, as a draft", () => {
    expect(classifyTrashBulk("PATCH", u(`/api/announcements?trash=true&${W}`), { deletedAt: null, _status: "draft" })).toEqual({
      kind: "restore",
      collection: "announcements",
      where: { id: { equals: "15" } },
    });
    expect(classifyTrashBulk("PATCH", u(`/api/pages?${W}`), { deletedAt: null })?.kind).toBe("restore");
  });

  it("flags 'restore as published' so it can be refused", () => {
    expect(classifyTrashBulk("PATCH", u(`/api/pages?${W}`), { deletedAt: null, _status: "published" })?.kind).toBe("restore-published");
  });

  it("recognises emptying the trash only with trash=true", () => {
    expect(classifyTrashBulk("DELETE", u(`/api/campaigns?trash=true&${W}`))?.kind).toBe("purge");
    expect(classifyTrashBulk("DELETE", u(`/api/campaigns?${W}`))).toBeNull();
  });

  it("leaves every other request to Payload (which still refuses bulk edits)", () => {
    expect(classifyTrashBulk("PATCH", u(`/api/pages?${W}`), { title: "x", deletedAt: null })).toBeNull();
    expect(classifyTrashBulk("PATCH", u(`/api/pages?${W}`), { _status: "published" })).toBeNull();
    expect(classifyTrashBulk("PATCH", u(`/api/pages/15`), { deletedAt: null })).toBeNull();
    expect(classifyTrashBulk("PATCH", u(`/api/pages`), { deletedAt: null })).toBeNull();
    expect(classifyTrashBulk("DELETE", u(`/api/users?trash=true&${W}`))).toBeNull();
    expect(classifyTrashBulk("GET", u(`/api/pages?trash=true&${W}`))).toBeNull();
  });
});
