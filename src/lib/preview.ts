import { createHmac } from "node:crypto";

/**
 * RFP §3.2.12 + RFP feedback 1.7: a real draft-mode preview — clicking
 * "Önizle" takes the editor to the ACTUAL site page, rendered by the site's
 * own code with the doc's current (possibly unpublished) content, not an
 * approximation built inside the CMS admin. The site's `/api/preview` turns
 * on Next.js Draft Mode and redirects into the page.
 *
 * 19.09.2026 (risk R1): the link used to carry PREVIEW_SECRET itself in the
 * query string — the master key that reads every draft, left in browser
 * history, proxy logs and screen shares. It now carries a signed ticket
 * instead: `base64url({ p: path, e: expiry }).HMAC-SHA256(PREVIEW_SECRET)`.
 * It opens exactly that path, for PREVIEW_TOKEN_TTL_MS, and the secret never
 * leaves the servers. Verified by vodafonepaycomtr-site `lib/previewToken.ts`.
 */
export const PREVIEW_TOKEN_TTL_MS = 2 * 60 * 60 * 1000;

export function signPreviewToken(path: string, now: number = Date.now(), secret: string = process.env.PREVIEW_SECRET || ""): string {
  const body = Buffer.from(JSON.stringify({ p: path, e: now + PREVIEW_TOKEN_TTL_MS })).toString("base64url");
  const sig = createHmac("sha256", secret).update(body).digest("base64url");
  return `${body}.${sig}`;
}

export function sitePreviewUrl(path: string): string {
  const base = process.env.SITE_URL || "http://localhost:3000";
  const params = new URLSearchParams({ token: signPreviewToken(path) });
  return `${base}/api/preview?${params.toString()}`;
}
