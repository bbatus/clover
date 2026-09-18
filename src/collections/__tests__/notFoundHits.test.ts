import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { MAX_ROWS, NotFoundHits } from "@/collections/NotFoundHits";
import { writeAuditLog } from "@/hooks/audit";

vi.mock("@/hooks/audit", () => ({ writeAuditLog: vi.fn() }));

type TestEndpoint = { path: string; handler: (req: never) => Promise<Response> };
const endpoint = (path: string): TestEndpoint => (NotFoundHits.endpoints as unknown as TestEndpoint[]).find((e) => e.path === path)!;

const SECRET = "test-preview-secret";

function req(body: Record<string, unknown>, payload: Record<string, unknown>, extra: Record<string, unknown> = {}) {
  return {
    headers: new Headers({ "x-preview-secret": SECRET }),
    i18n: { language: "tr" },
    json: async () => body,
    routeParams: {},
    payload,
    ...extra,
  } as never;
}

describe("POST /not-found-hits/record (18.09.2026 review)", () => {
  beforeEach(() => {
    process.env.PREVIEW_SECRET = SECRET;
  });
  afterEach(() => {
    delete process.env.PREVIEW_SECRET;
    vi.mocked(writeAuditLog).mockClear();
  });

  it("stores the referrer without its query string", async () => {
    const payload = {
      find: vi.fn().mockResolvedValue({ docs: [] }),
      count: vi.fn().mockResolvedValue({ totalDocs: 0 }),
      create: vi.fn().mockResolvedValue({}),
    };
    await endpoint("/record").handler(req({ path: "/eski-sayfa", referrer: "https://mail.example.com/r?email=a@b.com" }, payload));
    expect(payload.create.mock.calls[0][0].data).toMatchObject({ path: "/eski-sayfa", lastReferrer: "https://mail.example.com/r" });
  });

  it("when full, evicts the stalest one-off address instead of refusing every new one forever", async () => {
    const payload = {
      find: vi
        .fn()
        .mockResolvedValueOnce({ docs: [] }) // the new path isn't there yet
        .mockResolvedValueOnce({ docs: [{ id: 42 }] }), // stalest single-hit row
      count: vi.fn().mockResolvedValue({ totalDocs: MAX_ROWS }),
      delete: vi.fn().mockResolvedValue({}),
      create: vi.fn().mockResolvedValue({}),
    };
    const res = await endpoint("/record").handler(req({ path: "/yeni-kirik" }, payload));
    expect(res.status).toBe(204);
    expect(payload.find.mock.calls[1][0]).toMatchObject({
      where: { and: [{ count: { less_than_equal: 1 } }, { ignored: { not_equals: true } }] },
      sort: "lastSeenAt",
      limit: 1,
    });
    expect(payload.delete).toHaveBeenCalledWith(expect.objectContaining({ id: 42 }));
    expect(payload.create).toHaveBeenCalled();
  });

  it("when full of repeat or ignored addresses, drops the new one", async () => {
    const payload = {
      find: vi.fn().mockResolvedValue({ docs: [] }),
      count: vi.fn().mockResolvedValue({ totalDocs: MAX_ROWS }),
      delete: vi.fn(),
      create: vi.fn(),
    };
    await endpoint("/record").handler(req({ path: "/yeni-kirik" }, payload));
    expect(payload.delete).not.toHaveBeenCalled();
    expect(payload.create).not.toHaveBeenCalled();
  });

  it("refuses callers without the site's secret", async () => {
    const payload = { find: vi.fn() };
    const res = await endpoint("/record").handler(req({ path: "/x" }, payload, { headers: new Headers() }));
    expect(res.status).toBe(401);
    expect(payload.find).not.toHaveBeenCalled();
  });
});

describe("POST /not-found-hits/:id/ignore", () => {
  it("is audited with the path", async () => {
    const payload = { update: vi.fn().mockResolvedValue({ path: "/eski" }) };
    const res = await endpoint("/:id/ignore").handler(
      req({ ignored: true }, payload, { user: { id: 1, role: "growth_checker" }, routeParams: { id: "7" } })
    );
    expect(res.status).toBe(200);
    expect(vi.mocked(writeAuditLog).mock.calls[0][1]).toMatchObject({ documentId: "7", summary: expect.stringContaining("/eski") });
  });
});
