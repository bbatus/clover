import { describe, expect, it } from "vitest";
import { requiredForFeeRow, requiredForNote, requiredUnlessNote } from "../FeeRows";

const note = (text: string) => ({
  root: { type: "root", children: [{ type: "paragraph", children: text ? [{ type: "text", text }] : [] }] },
});

describe("FeeRows row-type validation", () => {
  it("requires a label on fee and heading rows, not on notes", () => {
    expect(requiredUnlessNote("", { siblingData: { rowType: "fee" } })).toBe("Bu alan zorunludur.");
    expect(requiredUnlessNote("  ", { siblingData: { rowType: "heading" } })).toBe("Bu alan zorunludur.");
    expect(requiredUnlessNote("", { siblingData: { rowType: "note" } })).toBe(true);
    expect(requiredUnlessNote("ATM’den Para Çekme", { siblingData: { rowType: "heading" } })).toBe(true);
  });

  it("requires a value only on plain fee rows (rows saved before rowType existed count as fee rows)", () => {
    expect(requiredForFeeRow("", { siblingData: {} })).toBe("Bu alan zorunludur.");
    expect(requiredForFeeRow(null, { siblingData: { rowType: "fee" } })).toBe("Bu alan zorunludur.");
    expect(requiredForFeeRow("", { siblingData: { rowType: "heading" } })).toBe(true);
    expect(requiredForFeeRow("", { siblingData: { rowType: "note" } })).toBe(true);
    expect(requiredForFeeRow("Ücretsiz", { siblingData: { rowType: "fee" } })).toBe(true);
  });

  it("requires note text on note rows, treating Lexical's empty paragraph as blank", () => {
    expect(requiredForNote(note(""), { siblingData: { rowType: "note" } })).toBe("Bu alan zorunludur.");
    expect(requiredForNote(null, { siblingData: { rowType: "note" } })).toBe("Bu alan zorunludur.");
    expect(requiredForNote(note("Ücretlerde değişiklik hakkı saklıdır."), { siblingData: { rowType: "note" } })).toBe(true);
    expect(requiredForNote(null, { siblingData: { rowType: "fee" } })).toBe(true);
  });
});
