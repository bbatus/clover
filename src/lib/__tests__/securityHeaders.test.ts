import { describe, expect, it } from "vitest";
import { buildCmsCsp, cmsSecurityHeaders, requestIdFrom } from "@/lib/security/headers";

describe("CMS security headers", () => {
  it("never allows being framed, frames only the site, and has no eval in production", () => {
    const csp = buildCmsCsp({ isDev: false, isHttps: true, siteOrigin: "https://site.example", mediaOrigin: "http://minio:9000" });
    expect(csp).toContain("frame-ancestors 'none'");
    expect(csp).toContain("frame-src 'self' https://site.example");
    expect(csp).not.toContain("unsafe-eval");
    expect(csp).not.toContain("cdn.jsdelivr.net");
    expect(csp).toContain("object-src 'none'");
    expect(csp).toContain("upgrade-insecure-requests");
    expect(csp).toContain("img-src 'self' data: blob: https: http://minio:9000");
  });

  it("sends HSTS only over https, always DENY framing and nosniff", () => {
    expect(cmsSecurityHeaders({ isDev: false, isHttps: true })["Strict-Transport-Security"]).toContain("max-age=31536000");
    const plain = cmsSecurityHeaders({ isDev: false, isHttps: false });
    expect(plain["Strict-Transport-Security"]).toBeUndefined();
    expect(plain["X-Frame-Options"]).toBe("DENY");
    expect(plain["X-Content-Type-Options"]).toBe("nosniff");
  });

  it("keeps a sane upstream request id and replaces a junk one", () => {
    expect(requestIdFrom("abc-12345678")).toBe("abc-12345678");
    expect(requestIdFrom("<script>")).toMatch(/^[0-9a-f-]{36}$/);
    expect(requestIdFrom(null)).toMatch(/^[0-9a-f-]{36}$/);
  });
});
