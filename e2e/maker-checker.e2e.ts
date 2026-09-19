import { expect, test } from "@playwright/test";
import { E2E_PREFIX, ROLES, SITE, api, asRole, cleanup, sql } from "./helpers";

/**
 * Maker → Checker → sitede (duyuru). A Growth Maker writes and submits a
 * draft; it has no way to publish it. A Growth Checker opens it, sees the
 * publish button, publishes; the site's Duyurular page shows it.
 */
test("Growth Maker taslak gönderir, Growth Checker yayınlar, sitede görünür", async ({ page, request }) => {
  const title = `${E2E_PREFIX} duyuru onay akışı`;
  let id: number | undefined;
  try {
    await asRole(ROLES.GROWTH_MAKER);
    await page.goto("/admin/collections/announcements/create");
    await page.locator("#field-title").fill(title);
    await page.locator("#field-body").fill("Uçtan uca test metni.");
    // A Maker gets no publish button — only "submit for approval".
    await expect(page.getByRole("button", { name: "Değişiklikleri yayınla" })).toHaveCount(0);
    await page.getByRole("button", { name: "Taslağı Onaya Gönder" }).click();
    await expect(page).toHaveURL(/\/admin\/collections\/announcements\/\d+/);
    id = Number(page.url().match(/announcements\/(\d+)/)![1]);
    await page.screenshot({ path: test.info().outputPath("1-maker-gonderdi.png") });

    const [row] = await sql<{ _status: string }>("select _status from announcements where id = $1", [id]);
    expect(row._status).toBe("draft");

    // The server refuses a Maker's publish even if the button were bypassed.
    const forced = await api(request, "PATCH", `/announcements/${id}`, { _status: "published" });
    expect(forced.status).toBe(403);

    await asRole(ROLES.GROWTH_CHECKER);
    await page.goto(`/admin/collections/announcements/${id}`);
    await page.getByRole("button", { name: "Değişiklikleri yayınla" }).click();
    await expect.poll(async () => (await sql<{ _status: string }>("select _status from announcements where id = $1", [id]))[0]._status).toBe("published");
    await page.screenshot({ path: test.info().outputPath("2-checker-yayinladi.png") });

    const site = await page.context().newPage();
    await site.goto(`${SITE}/duyurular`);
    await expect(site.getByText(title)).toBeVisible();
    await site.screenshot({ path: test.info().outputPath("3-sitede.png"), fullPage: true });
  } finally {
    if (id) await cleanup(request, "announcements", id);
  }
});
