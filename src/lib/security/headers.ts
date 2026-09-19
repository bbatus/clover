/**
 * 19.09.2026 — security headers for the CMS (admin UI and API), applied in
 * src/proxy.ts at runtime (next.config `headers()` would be baked into the
 * image at build time; test and production use different origins).
 *
 * Payload's admin needs inline scripts/styles, blob: and data: URLs; eval only
 * in development. The admin is never framed by anything (frame-ancestors
 * 'none'); it frames the SITE for previews (frame-src = SITE_URL origin).
 * No third-party script host is allowed — the one dependency on one (the
 * Monaco editor from cdn.jsdelivr.net, used by `code` fields) was removed the
 * same day.
 */
export type CmsHeaderEnv = { isDev: boolean; isHttps: boolean; siteOrigin?: string; mediaOrigin?: string };

export function originOf(url: string | undefined): string | undefined {
  if (!url) return undefined;
  try {
    return new URL(url).origin;
  } catch {
    return undefined;
  }
}

export function buildCmsCsp(env: CmsHeaderEnv): string {
  const media = env.mediaOrigin ? ` ${env.mediaOrigin}` : "";
  const directives = [
    "default-src 'self'",
    `script-src 'self' 'unsafe-inline'${env.isDev ? " 'unsafe-eval'" : ""}`,
    "style-src 'self' 'unsafe-inline'",
    `img-src 'self' data: blob: https:${media}`,
    `media-src 'self' blob: https:${media}`,
    "font-src 'self' data:",
    `connect-src 'self'${env.isDev ? " ws: wss:" : ""}`,
    `frame-src 'self'${env.siteOrigin ? ` ${env.siteOrigin}` : ""}`,
    "worker-src 'self' blob:",
    "frame-ancestors 'none'",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'",
  ];
  if (env.isHttps) directives.push("upgrade-insecure-requests");
  return directives.join("; ");
}

export function cmsSecurityHeaders(env: CmsHeaderEnv): Record<string, string> {
  const headers: Record<string, string> = {
    "Content-Security-Policy": buildCmsCsp(env),
    "X-Frame-Options": "DENY",
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=(), payment=(), usb=(), interest-cohort=()",
    "Cross-Origin-Opener-Policy": "same-origin",
  };
  if (env.isHttps) headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains";
  return headers;
}

export function requestIdFrom(incoming: string | null): string {
  return incoming && /^[A-Za-z0-9._-]{8,128}$/.test(incoming) ? incoming : crypto.randomUUID();
}
