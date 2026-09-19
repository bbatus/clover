import { expect, test } from "@playwright/test";
import { E2E_PREFIX, ROLES, SITE, api, asRole, campaignFixtures, cleanup, sql } from "./helpers";

/**
 * Zamanlanmış yayın. A Growth Maker submits a campaign with an Istanbul
 * publish time ~90 seconds ahead; a Growth Checker approves the schedule;
 * the CMS's own scheduler (every 30s, must be running — not
 * SCHEDULED_PUBLISH_DISABLED) publishes it at that time and the site shows it.
 */
test("İleri tarihli kampanya Checker onayından sonra zamanı gelince kendiliğinden yayına girer", async ({ page, request }) => {
  test.setTimeout(300_000);
  const title = `${E2E_PREFIX} zamanlanmış kampanya`;
  const slug = `e2e-zamanlanmis-${Date.now()}`;
  const at = new Date(Date.now() + 90_000);
  let id: number | undefined;
  try {
    const { image, category } = await campaignFixtures();
    await asRole(ROLES.GROWTH_MAKER);
    const created = await api<{ doc: { id: number } }>(request, "POST", "/campaigns?draft=true", {
      title,
      slug,
      description: "Uçtan uca test — zamanlanmış yayın.",
      image,
      category,
      scheduledPublishAt: at.toISOString(),
      scheduledPublishAt_tz: "Europe/Istanbul",
      _status: "draft",
    });
    expect(created.status, JSON.stringify(created.body)).toBe(201);
    id = created.body.doc.id;

    await asRole(ROLES.GROWTH_CHECKER);
    await page.goto(`/admin/collections/campaigns/${id}`);
    await page.getByRole("button", { name: "Onayla ve Planla" }).click();
    await expect(page.getByText("İleri tarihli yayını onaylıyorsunuz")).toBeVisible();
    await page.getByRole("button", { name: /^Onayla — / }).click();
    await expect(page.getByText(/Planlandı: .* \(İstanbul\) yayına girecek/)).toBeVisible();
    await page.screenshot({ path: test.info().outputPath("1-planlandi.png") });

    // The approval lives on the latest draft version — where the scheduler reads it (draft: true).
    const planned = await api<{ _status: string; reviewStatus: string }>(request, "GET", `/campaigns/${id}?draft=true&depth=0`);
    expect({ _status: planned.body._status, reviewStatus: planned.body.reviewStatus }).toEqual({ _status: "draft", reviewStatus: "scheduled" });

    // Not before its time…
    expect(Date.now()).toBeLessThan(at.getTime());
    // …and live within one scheduler tick (30 s) after it.
    await expect
      .poll(async () => (await sql<{ _status: string }>("select _status from campaigns where id = $1", [id]))[0]._status, {
        timeout: at.getTime() - Date.now() + 75_000,
        intervals: [5_000],
      })
      .toBe("published");
    const [published] = await sql<{ published_at: Date }>(
      "select max(created_at) as published_at from _campaigns_v where parent_id = $1 and version__status = 'published'",
      [id]
    );
    expect(new Date(published.published_at).getTime()).toBeGreaterThanOrEqual(at.getTime());

    const audit = await sql<{ summary: string }>("select summary from audit_logs where collection_slug = 'campaigns' and document_id = $1 order by id", [String(id)]);
    expect(audit.map((a) => a.summary).join("\n")).toMatch(/yayınlandı/);

    const site = await page.context().newPage();
    await site.goto(`${SITE}/kampanyalar/${slug}`);
    await expect(site.getByRole("heading", { name: title }).first()).toBeVisible();
    await site.screenshot({ path: test.info().outputPath("2-sitede.png") });
  } finally {
    if (id) await cleanup(request, "campaigns", id);
  }
});
