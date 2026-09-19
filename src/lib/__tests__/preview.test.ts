import { afterEach, describe, expect, it } from "vitest";
import { createHmac } from "node:crypto";
import { PREVIEW_TOKEN_TTL_MS, signPreviewToken, sitePreviewUrl } from "@/lib/preview";

describe("sitePreviewUrl (19.09.2026: signed ticket, no secret in the URL)", () => {
  const ORIGINAL = { ...process.env };
  afterEach(() => {
    process.env = { ...ORIGINAL };
  });

  it("points at the site's /api/preview with a token and never the secret itself", () => {
    process.env.SITE_URL = "https://vodafonepay.com.tr";
    process.env.PREVIEW_SECRET = "the-secret";
    const url = new URL(sitePreviewUrl("/kampanyalar/yaz-kampanyasi"));
    expect(url.origin + url.pathname).toBe("https://vodafonepay.com.tr/api/preview");
    expect(url.search).not.toContain("the-secret");
    expect(url.searchParams.get("secret")).toBeNull();
    expect(url.searchParams.get("token")).toMatch(/^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/);
  });

  it("binds the token to the path and an expiry, signed with HMAC-SHA256", () => {
    const now = 1_000_000;
    const token = signPreviewToken("/blog/x", now, "s3cret");
    const [body, sig] = token.split(".");
    expect(JSON.parse(Buffer.from(body, "base64url").toString())).toEqual({ p: "/blog/x", e: now + PREVIEW_TOKEN_TTL_MS });
    expect(sig).toBe(createHmac("sha256", "s3cret").update(body).digest("base64url"));
  });

  it("falls back to localhost when SITE_URL is unset", () => {
    delete process.env.SITE_URL;
    expect(sitePreviewUrl("/x")).toContain("http://localhost:3000/api/preview?token=");
  });
});
