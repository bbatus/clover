import { describe, expect, it, vi } from "vitest";
import { classifyLink, extractLinks, readableField, toSitePath } from "@/lib/linkScan";
import { isPrivateAddress, isPublicHttpTarget, scanBrokenLinks } from "@/lib/brokenLinks";
import { normaliseNotFoundPath, referrerPath } from "@/collections/NotFoundHits";

describe("linkScan", () => {
  it("turns same-site URLs into paths and keeps other sites external", () => {
    expect(toSitePath("https://www.vodafonepay.com.tr/kampanyalar/x/?a=1#b")).toBe("/kampanyalar/x");
    expect(toSitePath("/blog/")).toBe("/blog");
    expect(toSitePath("/")).toBe("/");
    expect(toSitePath("https://test.example/x", ["test.example"])).toBe("/x");
    expect(toSitePath("https://google.com/x")).toBeNull();
    expect(classifyLink("https://google.com", "f")).toMatchObject({ kind: "external" });
  });

  it("skips mail, phone, anchors and app deep links; flags scheme-less relative links", () => {
    for (const v of ["mailto:a@b.c", "tel:02129422121", "#top", "vodafonepay://open", ""]) expect(classifyLink(v, "f")).toBeNull();
    expect(classifyLink("layout-test-sayfasi", "href")).toMatchObject({ kind: "invalid" });
    expect(classifyLink("www.vodafonepay.com.tr", "href")).toMatchObject({ kind: "invalid" });
  });

  it("finds url-like fields at any depth and Lexical links, custom and internal", () => {
    const doc = {
      title: "T",
      ctaUrl: "/kampanyalar",
      imageUrl_not: "x",
      layout: [{ blockType: "hero", cards: [{ href: "https://www.vodafonepay.com.tr/aninda-bakiye" }] }],
      body: {
        root: {
          children: [
            { type: "paragraph", children: [{ type: "link", fields: { linkType: "custom", url: "/silinmis-sayfa" }, children: [] }] },
            { type: "link", fields: { linkType: "internal", doc: { relationTo: "pages", value: 12 } }, children: [] },
          ],
        },
      },
    };
    const links = extractLinks(doc);
    expect(links).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ kind: "internal", path: "/kampanyalar", field: "ctaUrl" }),
        expect.objectContaining({ kind: "internal", path: "/aninda-bakiye" }),
        expect.objectContaining({ kind: "internal", path: "/silinmis-sayfa" }),
        expect.objectContaining({ kind: "doc", relationTo: "pages", id: "12" }),
      ])
    );
    expect(links).toHaveLength(4);
    expect(readableField("layout[0].cards[1].href")).toBe("layout › cards › href");
  });
});

const publicDns = async () => ["93.184.216.34"];

describe("scanBrokenLinks", () => {
  it("asks the site about each distinct internal path once and reports 404s with every place they appear", async () => {
    process.env.SITE_REVALIDATE_URL = "http://vodafonepaycomtr:3000/api/revalidate";
    const docsBy: Record<string, unknown[]> = {
      "nav-links": [{ id: 1, label: "Eski", href: "/eski" }, { id: 2, label: "Göreli", href: "kampanya" }],
      campaigns: [{ id: 5, title: "K", ctaUrl: "/eski", body: { root: { children: [{ type: "link", fields: { linkType: "internal", doc: { relationTo: "pages", value: 9 } } }] } } }],
    };
    const payload = {
      find: vi.fn(async ({ collection }: { collection: string }) => ({ docs: docsBy[collection] ?? [] })),
      findGlobal: vi.fn(async () => ({ linkedinUrl: "https://www.linkedin.com/company/x" })),
      findByID: vi.fn(async () => ({ _status: "draft" })),
    };
    const fetchImpl = vi.fn(async (url: string) => new Response(null, { status: url.endsWith("/eski") ? 404 : 200 }));
    const result = await scanBrokenLinks(payload as never, { fetchImpl: fetchImpl as never });

    expect(fetchImpl).toHaveBeenCalledTimes(1); // "/eski" once; external not checked by default
    expect(fetchImpl.mock.calls[0][0]).toBe("http://vodafonepaycomtr:3000/eski");
    const eski = result.broken.find((b) => b.target === "/eski")!;
    expect(eski).toMatchObject({ reason: "not-found", status: 404 });
    expect(eski.sources.map((s) => s.adminUrl)).toEqual(["/admin/collections/nav-links/1", "/admin/collections/campaigns/5"]);
    expect(result.broken.find((b) => b.type === "invalid")?.target).toBe("kampanya");
    expect(result.broken.find((b) => b.type === "doc")).toMatchObject({ target: "pages/9", reason: "unpublished" });
    expect(payload.find).toHaveBeenCalledWith(expect.objectContaining({ where: { _status: { equals: "published" } } }));
  });

  it("checks external links only when asked, and treats network errors as unreachable", async () => {
    const payload = {
      find: vi.fn(async () => ({ docs: [] })),
      findGlobal: vi.fn(async () => ({ linkedinUrl: "https://example.invalid/x" })),
      findByID: vi.fn(),
    };
    const fetchImpl = vi.fn(async () => {
      throw new Error("ENOTFOUND");
    });
    const result = await scanBrokenLinks(payload as never, { external: true, fetchImpl: fetchImpl as never, resolve: publicDns });
    expect(result.broken[0]).toMatchObject({ type: "external", reason: "unreachable" });
  });

  // 18.09.2026 review: content is editor-controlled; the scan must not become a probe of the cluster network.
  it("never fetches external links that point at internal, loopback, link-local or metadata addresses", async () => {
    const urls = [
      "http://169.254.169.254/latest/meta-data/",
      "http://127.0.0.1:3000/api/users",
      "http://10.0.0.5:5432/",
      "http://[::1]/",
      "http://localhost/admin",
      "http://clover-postgres:5432/",
      "https://ok.example.com/",
    ];
    const payload = {
      find: vi.fn(async () => ({ docs: [{ id: 1, label: "x", links: urls.map((href) => ({ href })) }] })),
      findGlobal: vi.fn(async () => ({})),
      findByID: vi.fn(),
    };
    const resolve = vi.fn(async (host: string) => (host === "clover-postgres" ? ["172.30.12.4"] : ["93.184.216.34"]));
    const fetchImpl = vi.fn<(url: string) => Promise<Response>>(async () => new Response(null, { status: 200 }));
    const result = await scanBrokenLinks(payload as never, { external: true, fetchImpl: fetchImpl as never, resolve });
    expect(fetchImpl.mock.calls.map((c) => c[0])).toEqual(["https://ok.example.com/"]);
    expect(result.broken.filter((b) => b.reason === "private-address").map((b) => b.target).sort()).toEqual(urls.slice(0, 6).sort());
  });

  it("reads every page of a large collection instead of stopping at a fixed limit", async () => {
    const find = vi.fn(async ({ page }: { page: number }) => ({
      docs: page === 1 ? [{ id: 1, label: "a", href: "/a" }] : [{ id: 2, label: "b", href: "/b" }],
      hasNextPage: page === 1,
    }));
    const payload = { find, findGlobal: vi.fn(async () => ({})), findByID: vi.fn() };
    const fetchImpl = vi.fn(async () => new Response(null, { status: 404 }));
    const result = await scanBrokenLinks(payload as never, { fetchImpl: fetchImpl as never });
    expect(result.broken.map((b) => b.target).sort()).toEqual(["/a", "/b"]);
  });

  it("does not report sites that merely refuse bots (LinkedIn 999, 403, 429)", async () => {
    const payload = { find: vi.fn(async () => ({ docs: [] })), findGlobal: vi.fn(async () => ({ linkedinUrl: "https://www.linkedin.com/company/x" })), findByID: vi.fn() };
    for (const status of [999, 403, 429]) {
      const fetchImpl = vi.fn(async () => ({ status }) as Response);
      const result = await scanBrokenLinks(payload as never, { external: true, fetchImpl: fetchImpl as never, resolve: publicDns });
      expect(result.broken).toEqual([]);
    }
  });
});

describe("isPrivateAddress / isPublicHttpTarget", () => {
  it("classifies addresses", () => {
    for (const ip of ["10.1.2.3", "172.16.0.1", "172.31.229.152", "192.168.1.1", "127.0.0.1", "169.254.169.254", "100.64.0.1", "0.0.0.0", "::1", "fd00::1", "fe80::1", "::ffff:10.0.0.1", "224.0.0.1"]) {
      expect(isPrivateAddress(ip), ip).toBe(true);
    }
    for (const ip of ["93.184.216.34", "8.8.8.8", "172.32.0.1", "2606:4700::1111"]) {
      expect(isPrivateAddress(ip), ip).toBe(false);
    }
  });

  it("refuses non-http schemes and hosts that resolve to nothing or to any private address", async () => {
    expect(await isPublicHttpTarget("ftp://example.com/", async () => ["93.184.216.34"])).toBe(false);
    expect(await isPublicHttpTarget("https://mixed.example/", async () => ["93.184.216.34", "10.0.0.1"])).toBe(false);
    expect(await isPublicHttpTarget("https://nx.example/", async () => { throw new Error("ENOTFOUND"); })).toBe(false);
    expect(await isPublicHttpTarget("https://www.linkedin.com/x", async () => ["13.107.42.14"])).toBe(true);
  });
});

describe("referrerPath", () => {
  it("keeps origin and path only, drops query strings and non-web schemes", () => {
    expect(referrerPath("https://mail.example.com/inbox?user=ali@x.com&t=abc#m")).toBe("https://mail.example.com/inbox");
    expect(referrerPath("javascript:alert(1)")).toBeUndefined();
    expect(referrerPath("not a url")).toBeUndefined();
  });
});

describe("normaliseNotFoundPath", () => {
  it("keeps page paths, drops noise", () => {
    expect(normaliseNotFoundPath("/kampanyalar/eski/?utm=1")).toBe("/kampanyalar/eski");
    expect(normaliseNotFoundPath("/%C3%BCr%C3%BCnler")).toBe("/ürünler");
    for (const p of ["/wp-login.php", "/.env", "/api/x", "//x", "x", "/a.png", "/" + "a".repeat(400)]) expect(normaliseNotFoundPath(p)).toBeNull();
  });
});
