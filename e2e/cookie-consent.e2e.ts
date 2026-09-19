import { expect, test } from "@playwright/test";
import { SITE } from "./helpers";

/** Çerez bandı (19.09.2026): first visit shows it, a choice is remembered, nothing optional is allowed by "Reddet". */
test("Çerez bandı ilk ziyarette çıkar, seçim hatırlanır", async ({ browser }) => {
  const context = await browser.newContext({ locale: "tr-TR" });
  const page = await context.newPage();
  await page.goto(`${SITE}/`);
  const banner = page.getByRole("dialog", { name: "Çerez ayarlarınızı yönetin" });
  await expect(banner).toBeVisible();
  await page.screenshot({ path: test.info().outputPath("1-bant.png") });

  await page.getByRole("button", { name: "buraya tıklayabilirsiniz." }).click();
  await expect(page.getByRole("dialog", { name: "Gizliliğiniz" })).toBeVisible();
  await page.getByRole("checkbox", { name: "Performans (Analitik) Çerezleri" }).check({ force: true });
  await page.screenshot({ path: test.info().outputPath("2-ayarlar.png") });
  await page.getByRole("button", { name: "Ayarları Kaydet" }).click();
  await expect(page.getByRole("dialog")).toHaveCount(0);

  const cookie = (await context.cookies()).find((c) => c.name === "vfpay_consent");
  expect(JSON.parse(decodeURIComponent(cookie!.value)).c).toEqual({ performance: true, functional: false, marketing: false });

  await page.reload();
  await expect(page.getByRole("dialog")).toHaveCount(0);
  await context.close();
});
