import { defineConfig } from "@playwright/test";

/**
 * 19.09.2026 — uçtan uca testler (prompt 3 / madde 6). Runs against a LOCAL
 * stack: the CMS (`CMS_AUTO_LOGIN=true`, scheduler on) and the site, both
 * started the usual way — see e2e/README.md. Files are `*.e2e.ts` so Vitest's
 * default `*.test.ts` / `*.spec.ts` pattern never picks them up.
 *
 * One worker, in order: the tests switch the single auto-login user's role
 * in the database, so two running at once would step on each other.
 */
export default defineConfig({
  testDir: ".",
  testMatch: "**/*.e2e.ts",
  timeout: 240_000,
  expect: { timeout: 20_000 },
  fullyParallel: false,
  workers: 1,
  retries: 0,
  globalTeardown: "./global-teardown.ts",
  reporter: [["list"], ["html", { outputFolder: "../e2e-report", open: "never" }]],
  outputDir: "../e2e-results",
  use: {
    baseURL: process.env.E2E_CMS_URL ?? "http://localhost:3099",
    locale: "tr-TR",
    timezoneId: "Europe/Istanbul",
    viewport: { width: 1440, height: 900 },
    screenshot: "on",
    trace: "retain-on-failure",
  },
});
