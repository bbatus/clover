import { describe, expect, it, vi } from "vitest";
import type { PayloadRequest } from "payload";
import { livenessEndpoint, readinessEndpoint } from "@/lib/healthEndpoints";

describe("livenessEndpoint", () => {
  it("always answers 200 with no dependency check — a DB outage must not fail this", async () => {
    const res = await livenessEndpoint.handler!({} as PayloadRequest);
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ status: "ok" });
  });
});

describe("readinessEndpoint", () => {
  it("200s when a real DB round trip succeeds", async () => {
    const find = vi.fn().mockResolvedValue({ docs: [] });
    const req = { payload: { find } } as unknown as PayloadRequest;
    const res = await readinessEndpoint.handler!(req);
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ status: "ok", db: "ok" });
    expect(find).toHaveBeenCalledWith(
      expect.objectContaining({ collection: "users", limit: 0, overrideAccess: true })
    );
  });

  it("503s (not 500, not a silent pass) when the DB round trip throws", async () => {
    const find = vi.fn().mockRejectedValue(new Error("connection refused"));
    const req = { payload: { find } } as unknown as PayloadRequest;
    const res = await readinessEndpoint.handler!(req);
    expect(res.status).toBe(503);
    const body = await res.json();
    expect(body.status).toBe("unavailable");
    expect(body.error).toContain("connection refused");
  });
});
