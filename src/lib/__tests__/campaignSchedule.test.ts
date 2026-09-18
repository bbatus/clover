import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  changedContentFields,
  manageCampaignSchedule,
  resetScheduledPublishRetries,
  runScheduledPublishes,
  SCHEDULED_PUBLISH_CONTEXT,
  ScheduleNoLongerDueError,
} from "@/lib/campaignSchedule";
import { writeAuditLog } from "@/hooks/audit";
import { formatIstanbul } from "@/lib/istanbulTime";
import { ROLES } from "@/access/roles";

vi.mock("@/hooks/audit", () => ({ writeAuditLog: vi.fn() }));

const NOW = new Date("2026-09-18T14:00:00.000Z"); // 17:00 in Istanbul
const FUTURE = "2026-10-01T07:00:00.000Z"; // 01.10.2026 10:00 Istanbul
const PAST = "2026-09-01T07:00:00.000Z";

function req(role?: string, id: number = 1) {
  return {
    user: role ? { id, role } : undefined,
    i18n: { language: "tr" },
    payload: { find: vi.fn().mockResolvedValue({ totalDocs: 0 }) },
  };
}

function run(data: Record<string, unknown>, originalDoc: Record<string, unknown>, role?: string, context: Record<string, unknown> = {}) {
  return manageCampaignSchedule({ data, originalDoc, operation: "update", req: req(role), context } as never);
}

describe("formatIstanbul", () => {
  it("formats an instant in Istanbul time, not the machine's zone", () => {
    expect(formatIstanbul("2026-09-30T21:00:00.000Z")).toBe("01.10.2026 00:00");
    expect(formatIstanbul("2026-09-18T14:30:00.000Z")).toBe("18.09.2026 17:30");
  });
});

describe("manageCampaignSchedule", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(NOW);
  });
  afterEach(() => vi.useRealTimers());

  it("lets a Checker approve a future time and stamps who and when", async () => {
    const data = await run({ reviewStatus: "scheduled", _status: "draft" }, { id: 5, reviewStatus: "pending", scheduledPublishAt: FUTURE, _status: "draft" }, ROLES.GROWTH_CHECKER);
    expect(data).toMatchObject({ reviewStatus: "scheduled", scheduleApprovedBy: 1, scheduleApprovedAt: NOW.toISOString() });
  });

  it("refuses a Growth Maker approving their own schedule", async () => {
    await expect(
      run({ reviewStatus: "scheduled" }, { id: 5, reviewStatus: "pending", scheduledPublishAt: FUTURE }, ROLES.GROWTH_MAKER)
    ).rejects.toThrow("yalnızca bir Checker");
  });

  it("refuses a time that is already past, naming it in Istanbul time", async () => {
    await expect(
      run({ reviewStatus: "scheduled", scheduledPublishAt: PAST }, { id: 5, reviewStatus: "pending" }, ROLES.GROWTH_CHECKER)
    ).rejects.toThrow("01.09.2026 10:00, İstanbul");
  });

  it("refuses approval without a date", async () => {
    await expect(run({ reviewStatus: "scheduled" }, { id: 5, reviewStatus: "pending" }, ROLES.NEW_VERTICAL_CHECKER)).rejects.toThrow("tarihi");
  });

  it("drops the approval when content changes after it", async () => {
    const data = await run(
      { reviewStatus: "scheduled", description: "yeni", scheduledPublishAt: FUTURE },
      { id: 5, reviewStatus: "scheduled", description: "eski", scheduledPublishAt: FUTURE, scheduleApprovedBy: 2 },
      ROLES.GROWTH_MAKER
    );
    expect(data).toMatchObject({ reviewStatus: "pending", scheduleApprovedBy: null, scheduleApprovedAt: null });
  });

  it("drops the approval when the date itself moves", async () => {
    const data = await run(
      { reviewStatus: "scheduled", scheduledPublishAt: "2026-10-02T07:00:00.000Z" },
      { id: 5, reviewStatus: "scheduled", scheduledPublishAt: FUTURE },
      ROLES.GROWTH_CHECKER
    );
    expect(data.reviewStatus).toBe("pending");
  });

  it("keeps the approval when the form is resubmitted unchanged (relationships as ids vs objects)", async () => {
    const data = await run(
      { reviewStatus: "scheduled", title: "T", category: 20, scheduledPublishAt: FUTURE, updatedAt: "x" },
      { id: 5, reviewStatus: "scheduled", title: "T", category: { id: 20, label: "K" }, scheduledPublishAt: FUTURE, updatedAt: "y" },
      ROLES.GROWTH_MAKER
    );
    expect(data.reviewStatus).toBe("scheduled");
  });

  it("cancels a plan when reviewStatus is set back to pending", async () => {
    const data = await run({ reviewStatus: "pending" }, { id: 5, reviewStatus: "scheduled", scheduledPublishAt: FUTURE }, ROLES.GROWTH_CHECKER);
    expect(data).toMatchObject({ reviewStatus: "pending", scheduleApprovedBy: null });
  });

  it("a manual publish supersedes the plan", async () => {
    const data = await run({ _status: "published", reviewStatus: "scheduled" }, { id: 5, reviewStatus: "scheduled" }, ROLES.GROWTH_CHECKER);
    expect(data.reviewStatus).toBe("pending");
  });

  it("lets the scheduler's own publish through untouched", async () => {
    const input = { _status: "published", reviewStatus: "pending" };
    const data = await run(input, { id: 5, reviewStatus: "scheduled", _status: "draft", scheduledPublishAt: PAST }, undefined, {
      [SCHEDULED_PUBLISH_CONTEXT]: true,
    });
    expect(data).toEqual(input);
  });

  // 18.09.2026 review: the scheduler queries first and saves later; whatever
  // happened in between must not go live on the strength of the old approval.
  it("refuses the scheduler's publish when the approval was dropped after its query (Maker edit in between)", async () => {
    await expect(
      run({ _status: "published", reviewStatus: "pending" }, { id: 5, reviewStatus: "pending", _status: "draft", scheduledPublishAt: PAST }, undefined, {
        [SCHEDULED_PUBLISH_CONTEXT]: true,
      })
    ).rejects.toBeInstanceOf(ScheduleNoLongerDueError);
  });

  it("refuses the scheduler's publish when the plan was moved into the future", async () => {
    await expect(
      run({ _status: "published" }, { id: 5, reviewStatus: "scheduled", _status: "draft", scheduledPublishAt: FUTURE }, undefined, {
        [SCHEDULED_PUBLISH_CONTEXT]: true,
      })
    ).rejects.toBeInstanceOf(ScheduleNoLongerDueError);
  });
});

describe("changedContentFields", () => {
  it("ignores review bookkeeping and timestamps", () => {
    expect(changedContentFields({ reviewStatus: "x", updatedAt: "a", _status: "draft" }, { reviewStatus: "y", updatedAt: "b" })).toEqual([]);
  });
});

describe("runScheduledPublishes", () => {
  beforeEach(() => {
    resetScheduledPublishRetries();
    vi.mocked(writeAuditLog).mockClear();
  });

  it("queries due, approved drafts by absolute instant and publishes each as the system", async () => {
    const find = vi.fn().mockResolvedValue({ docs: [{ id: 7, scheduledPublishAt: "2026-09-18T14:30:00.000Z" }] });
    const update = vi.fn().mockResolvedValue({});
    const payload = { find, update, logger: { info: vi.fn(), error: vi.fn() } };
    const now = new Date("2026-09-18T14:30:10.000Z");
    const result = await runScheduledPublishes(payload as never, now);

    const where = find.mock.calls[0][0].where.and;
    expect(where).toContainEqual({ reviewStatus: { equals: "scheduled" } });
    expect(where).toContainEqual({ _status: { equals: "draft" } });
    expect(where).toContainEqual({ scheduledPublishAt: { less_than_equal: "2026-09-18T14:30:10.000Z" } });
    expect(find.mock.calls[0][0]).toMatchObject({ draft: true, overrideAccess: true });

    expect(update).toHaveBeenCalledWith(
      expect.objectContaining({
        collection: "campaigns",
        id: 7,
        data: { _status: "published", reviewStatus: "pending" },
        overrideAccess: true,
        context: expect.objectContaining({ [SCHEDULED_PUBLISH_CONTEXT]: true }),
      })
    );
    expect(find.mock.calls[0][0]).toMatchObject({ sort: "scheduledPublishAt" });
    expect(result).toEqual({ published: ["7"], failed: [], skipped: [] });
  });

  it("keeps going when one campaign fails and reports it", async () => {
    const find = vi.fn().mockResolvedValue({ docs: [{ id: 1 }, { id: 2 }] });
    const update = vi.fn().mockRejectedValueOnce(new Error("boom")).mockResolvedValueOnce({});
    const result = await runScheduledPublishes({ find, update, logger: { info: vi.fn(), error: vi.fn() } } as never);
    expect(result).toEqual({ published: ["2"], failed: [{ id: "1", error: "boom" }], skipped: [] });
  });

  it("counts a plan that changed mid-run as skipped, not failed", async () => {
    const find = vi.fn().mockResolvedValue({ docs: [{ id: 3 }] });
    const update = vi.fn().mockRejectedValue(new ScheduleNoLongerDueError());
    const logger = { info: vi.fn(), error: vi.fn() };
    const result = await runScheduledPublishes({ find, update, logger } as never);
    expect(result).toEqual({ published: [], failed: [], skipped: ["3"] });
    expect(logger.error).not.toHaveBeenCalled();
  });

  it("backs off a failing campaign instead of retrying every tick, and audits the first failure once", async () => {
    const find = vi.fn().mockResolvedValue({ docs: [{ id: 9, title: "Eksik Kategori" }] });
    const update = vi.fn().mockRejectedValue(new Error("Lütfen geçersiz alanı düzeltin: Kategori"));
    const payload = { find, update, logger: { info: vi.fn(), error: vi.fn() } };
    const t0 = new Date("2026-09-18T14:30:00.000Z");

    await runScheduledPublishes(payload as never, t0);
    expect(writeAuditLog).toHaveBeenCalledTimes(1);
    expect(vi.mocked(writeAuditLog).mock.calls[0][1]).toMatchObject({
      documentId: "9",
      actorEmail: "sistem (zamanlanmış yayın)",
      summary: expect.stringContaining("BAŞARISIZ"),
    });

    // 20 s later (next tick): still inside the 30 s backoff, not retried.
    await runScheduledPublishes(payload as never, new Date(t0.getTime() + 20_000));
    expect(update).toHaveBeenCalledTimes(1);

    // After the backoff: retried, fails again, not audited a second time; next wait doubles.
    await runScheduledPublishes(payload as never, new Date(t0.getTime() + 31_000));
    expect(update).toHaveBeenCalledTimes(2);
    expect(writeAuditLog).toHaveBeenCalledTimes(1);
    await runScheduledPublishes(payload as never, new Date(t0.getTime() + 31_000 + 45_000));
    expect(update).toHaveBeenCalledTimes(2);
    await runScheduledPublishes(payload as never, new Date(t0.getTime() + 31_000 + 61_000));
    expect(update).toHaveBeenCalledTimes(3);
  });
});
