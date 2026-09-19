import { readFileSync } from "node:fs";
import { Client } from "pg";
import { expect, type APIRequestContext, type Page } from "@playwright/test";

/**
 * Shared plumbing for the e2e tests. Everything a test creates carries the
 * `E2E_PREFIX` in its title and is removed again by `cleanup()` (trash →
 * permanent delete, as a New Vertical Maker) — the tests never touch records
 * they didn't create.
 */

export const CMS = process.env.E2E_CMS_URL ?? "http://localhost:3099";
export const SITE = process.env.E2E_SITE_URL ?? "http://localhost:3098";
export const TEST_USER = process.env.E2E_USER_EMAIL ?? "admin@vodafonepay.local";
export const E2E_PREFIX = `E2E ${new Date().toISOString().slice(0, 16).replace("T", " ")}`;

export const ROLES = {
  NV_MAKER: "new_vertical_maker",
  NV_CHECKER: "new_vertical_checker",
  GROWTH_MAKER: "growth_maker",
  GROWTH_CHECKER: "growth_checker",
} as const;
export type Role = (typeof ROLES)[keyof typeof ROLES];

// Safety: these tests write to the database they point at. Never anything but local.
for (const url of [CMS, SITE]) {
  if (!/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?/.test(url)) {
    throw new Error(`e2e: refusing to run against ${url} — local stack only.`);
  }
}

function databaseUri(): string {
  if (process.env.DATABASE_URI) return process.env.DATABASE_URI;
  // Same .env docker compose reads; the DB is published on localhost:5432.
  const env = Object.fromEntries(
    readFileSync(new URL("../.env", import.meta.url), "utf8")
      .split("\n")
      .filter((l) => /^[A-Z_]+=/.test(l))
      .map((l) => [l.slice(0, l.indexOf("=")), l.slice(l.indexOf("=") + 1).replace(/^"|"$/g, "")])
  );
  return `postgres://${env.POSTGRES_USER}:${env.POSTGRES_PASSWORD}@localhost:5432/${env.POSTGRES_DB}`;
}

async function sql<T = Record<string, unknown>>(query: string, params: unknown[] = []): Promise<T[]> {
  const client = new Client({ connectionString: databaseUri() });
  await client.connect();
  try {
    return (await client.query(query, params)).rows as T[];
  } finally {
    await client.end();
  }
}

/** The auto-login user acts as `role` from the next request on (Payload reads the role from the DB per request). */
export async function asRole(role: Role): Promise<void> {
  await sql("update users set role = $1 where email = $2", [role, TEST_USER]);
}

export async function restoreRole(): Promise<void> {
  await asRole(ROLES.NV_MAKER);
}

export async function api<T = Record<string, unknown>>(
  request: APIRequestContext,
  method: "GET" | "POST" | "PATCH" | "DELETE",
  urlPath: string,
  data?: unknown
): Promise<{ status: number; body: T }> {
  const res = await request.fetch(`${CMS}/api${urlPath}`, {
    method,
    data: data === undefined ? undefined : data,
    headers: data === undefined ? undefined : { "content-type": "application/json" },
  });
  const text = await res.text();
  return { status: res.status(), body: (text ? JSON.parse(text) : {}) as T };
}

/** An existing media id and campaign category id, read (not created) so test campaigns satisfy their required fields. */
export async function campaignFixtures(): Promise<{ image: number; category: number }> {
  const [image] = await sql<{ id: number }>("select id from media order by id limit 1");
  const [category] = await sql<{ id: number }>("select id from categories where scope = 'campaign' and deleted_at is null order by id limit 1");
  if (!image || !category) throw new Error("e2e: needs at least one media item and one campaign category in the DB");
  return { image: image.id, category: category.id };
}

/** Removes a test record for good: into the trash, then a permanent delete from it (New Vertical Maker). */
export async function cleanup(request: APIRequestContext, collection: string, id: string | number): Promise<void> {
  await asRole(ROLES.NV_MAKER);
  await api(request, "PATCH", `/${collection}/${id}`, { deletedAt: new Date().toISOString() });
  const where = encodeURIComponent("where[id][equals]");
  await api(request, "DELETE", `/${collection}?trash=true&${where}=${id}`);
  const left = await sql(`select 1 from ${collection.replace(/-/g, "_")} where id = $1`, [id]);
  expect(left, `${collection}/${id} should be gone after cleanup`).toHaveLength(0);
}

export async function waitForAdmin(page: Page): Promise<void> {
  await page.waitForLoadState("networkidle");
}

export { sql };
