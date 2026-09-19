import { expect, test } from "@playwright/test";
import { E2E_PREFIX, ROLES, api, asRole, campaignFixtures, cleanup } from "./helpers";

/**
 * Paylaşılabilir önizleme linki. A draft campaign that isn't on the site;
 * from its screen a link is created; opened in a fresh browser with no CMS
 * session it shows the draft under the ÖNİZLEME band; once revoked, the same
 * link says so.
 */
test("Taslak kampanya için önizleme linki oluşturulur, CMS oturumu olmadan açılır, iptal edilince çalışmaz", async ({ page, request, browser }) => {
  const title = `${E2E_PREFIX} önizleme linki`;
  const slug = `e2e-onizleme-${Date.now()}`;
  let id: number | undefined;
  try {
    const { image, category } = await campaignFixtures();
    await asRole(ROLES.NV_MAKER);
    const created = await api<{ doc: { id: number } }>(request, "POST", "/campaigns?draft=true", {
      title,
      slug,
      description: "Uçtan uca test — önizleme linki.",
      image,
      category,
      _status: "draft",
    });
    expect(created.status, JSON.stringify(created.body)).toBe(201);
    id = created.body.doc.id;

    // (Not asserted here: that the draft is absent from /kampanyalar/<slug>.
    // With the local stack's CMS_AUTO_LOGIN every site read is an admin read
    // and drafts do show — see env.ts, which now refuses that flag in a pod.)
    const outsider = await browser.newContext();
    const visitor = await outsider.newPage();

    await page.goto(`/admin/collections/campaigns/${id}`);
    await page.getByLabel("Kime / neden (opsiyonel)").fill("E2E test");
    await page.getByRole("button", { name: "Link oluştur" }).click();
    const url = await page.locator("#spp-url").inputValue();
    expect(url).toMatch(/\/onizleme\/[A-Za-z0-9_-]+$/);
    await page.screenshot({ path: test.info().outputPath("1-link-olustu.png") });

    await visitor.goto(url);
    await expect(visitor.getByText("ÖNİZLEME")).toBeVisible();
    await expect(visitor.getByRole("heading", { name: title }).first()).toBeVisible();
    await visitor.screenshot({ path: test.info().outputPath("2-disaridan-acildi.png") });

    await page.getByRole("button", { name: "İptal et" }).first().click();
    await expect(page.getByText("Bu içerik için aktif link yok.")).toBeVisible();
    await visitor.goto(url);
    await expect(visitor.getByText("Bu önizleme linki iptal edilmiş.")).toBeVisible();
    await visitor.screenshot({ path: test.info().outputPath("3-iptal.png") });
    await outsider.close();
  } finally {
    if (id) await cleanup(request, "campaigns", id);
  }
});
