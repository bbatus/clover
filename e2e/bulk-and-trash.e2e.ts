import { expect, test, type Page } from "@playwright/test";
import { E2E_PREFIX, ROLES, api, asRole, cleanup, sql } from "./helpers";

async function selectRows(page: Page, titles: string[]) {
  for (const title of titles) {
    await page.getByRole("row").filter({ hasText: title }).getByRole("checkbox").check();
  }
}

/**
 * Toplu işlemler + geri dönüşüm kutusu. A Growth Checker bulk-publishes two
 * drafts — only after ticking "I reviewed each one". A Growth Maker bulk-moves
 * two of its own drafts to the trash; a Growth Checker restores one from the
 * Çöp tab, and it comes back as a draft.
 */
test("Toplu yayın beyan ister; toplu çöpe taşıma ve Çöp sekmesinden geri yükleme çalışır", async ({ page, request }) => {
  const created: number[] = [];
  const mk = async (title: string) => {
    const r = await api<{ doc: { id: number } }>(request, "POST", "/announcements?draft=true", { title, body: "Uçtan uca test.", _status: "draft" });
    expect(r.status, JSON.stringify(r.body)).toBe(201);
    created.push(r.body.doc.id);
    return r.body.doc.id;
  };
  const statusOf = async (id: number) => (await sql<{ _status: string; deleted_at: Date | null }>("select _status, deleted_at from announcements where id = $1", [id]))[0];

  try {
    await asRole(ROLES.GROWTH_MAKER);
    const pubA = await mk(`${E2E_PREFIX} toplu yayın A`);
    const pubB = await mk(`${E2E_PREFIX} toplu yayın B`);
    const trashA = await mk(`${E2E_PREFIX} toplu çöp A`);
    const trashB = await mk(`${E2E_PREFIX} toplu çöp B`);

    // Bulk publish (Checker) needs the explicit "reviewed each one" statement.
    await asRole(ROLES.GROWTH_CHECKER);
    await page.goto(`/admin/collections/announcements?search=${encodeURIComponent(`${E2E_PREFIX} toplu yayın`)}`);
    await selectRows(page, [`${E2E_PREFIX} toplu yayın A`, `${E2E_PREFIX} toplu yayın B`]);
    await expect(page.getByText("2 kayıt seçildi")).toBeVisible();
    await page.getByRole("button", { name: "Seçilenleri yayınla" }).click();
    const confirm = page.getByRole("button", { name: "Evet, devam et" });
    await expect(confirm).toBeDisabled();
    await page.locator("#bulk-review-ack").check();
    await page.screenshot({ path: test.info().outputPath("1-toplu-yayin-beyan.png") });
    await confirm.click();
    await expect(page.getByText("2 başarılı · 0 atlandı · 0 başarısız")).toBeVisible();
    expect((await statusOf(pubA))._status).toBe("published");
    expect((await statusOf(pubB))._status).toBe("published");
    await page.screenshot({ path: test.info().outputPath("2-toplu-yayin-sonuc.png") });

    // Bulk move to trash (Maker, own drafts).
    await asRole(ROLES.GROWTH_MAKER);
    await page.goto(`/admin/collections/announcements?search=${encodeURIComponent(`${E2E_PREFIX} toplu çöp`)}`);
    await selectRows(page, [`${E2E_PREFIX} toplu çöp A`, `${E2E_PREFIX} toplu çöp B`]);
    await page.getByRole("button", { name: "Seçili taslakları çöp kutusuna taşı" }).click();
    await page.getByRole("button", { name: "Evet, devam et" }).click();
    await expect(page.getByText("2 başarılı · 0 atlandı · 0 başarısız")).toBeVisible();
    expect((await statusOf(trashA)).deleted_at).not.toBeNull();
    expect((await statusOf(trashB)).deleted_at).not.toBeNull();

    // Restore one from the Çöp tab (Checker) — it comes back as a draft.
    await asRole(ROLES.GROWTH_CHECKER);
    await page.goto(`/admin/collections/announcements/trash/${trashA}`);
    await expect(page.getByText("çöpe atıldı ve sadece okuma modunda")).toBeVisible();
    await page.screenshot({ path: test.info().outputPath("3-copte.png") });
    await page.getByRole("button", { name: "Geri Yükle" }).click();
    await expect(page.getByText("Yayınlanan sürüm olarak geri yükle")).toBeHidden();
    await page.getByRole("button", { name: "Onayla" }).click();
    await expect(page).toHaveURL(new RegExp(`/admin/collections/announcements/${trashA}$`));
    await expect.poll(async () => (await statusOf(trashA)).deleted_at).toBeNull();
    expect((await statusOf(trashA))._status).toBe("draft");
    expect((await statusOf(trashB)).deleted_at).not.toBeNull();

    // A Checker never gets a permanent delete.
    const where = encodeURIComponent("where[id][equals]");
    const purge = await api(request, "DELETE", `/announcements?trash=true&${where}=${trashB}`);
    expect(purge.status).toBeGreaterThanOrEqual(400);
    expect((await statusOf(trashB)).deleted_at).not.toBeNull();
  } finally {
    for (const id of created) await cleanup(request, "announcements", id);
  }
});
