import { describe, expect, it } from "vitest";
import { CookieConsent } from "@/globals/CookieConsent";
import { COOKIE_CONSENT_DEFAULTS, validateCookieCategories } from "@/lib/cookieConsentDefaults";
import { getAccessMatrixRows } from "@/lib/rolePermissions";

describe("Çerez Bandı global (19.09.2026)", () => {
  it("goes through maker→checker like the other content globals", () => {
    expect(CookieConsent.versions).toEqual({ drafts: true });
    expect(CookieConsent.hooks?.beforeChange?.length).toBe(2);
    expect(CookieConsent.access?.read?.({} as never)).toBe(true);
  });

  it("starting categories: the four vodafone.com.tr ones, necessary first", () => {
    expect(COOKIE_CONSENT_DEFAULTS.categories.map((c) => c.key)).toEqual(["necessary", "performance", "functional", "marketing"]);
    expect(validateCookieCategories(COOKIE_CONSENT_DEFAULTS.categories, "tr")).toBe(true);
  });

  it("refuses a duplicate category and a list without 'necessary'", () => {
    expect(validateCookieCategories([{ key: "necessary" }, { key: "marketing" }, { key: "marketing" }], "tr")).toMatch(/iki kez/);
    expect(validateCookieCategories([{ key: "performance" }], "en")).toMatch(/Necessary/);
    expect(validateCookieCategories([], "tr")).toMatch(/Zorunlu/);
  });

  it("is listed in the access matrix", () => {
    expect(getAccessMatrixRows().some((r) => JSON.stringify(r).includes("cookie-consent"))).toBe(true);
  });
});
