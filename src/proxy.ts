import { NextResponse, type NextRequest } from "next/server";
import { cmsSecurityHeaders, originOf, requestIdFrom } from "@/lib/security/headers";

/**
 * 19.09.2026 — security headers + `x-request-id` on every admin/API response
 * (see lib/security/headers.ts). The request id is also what the API rate
 * limiter and the JSON request log use to tie a line to a request.
 */
export function proxy(request: NextRequest) {
  const requestId = requestIdFrom(request.headers.get("x-request-id"));
  const forwardedProto = request.headers.get("x-forwarded-proto");
  const isHttps = (forwardedProto ?? request.nextUrl.protocol.replace(":", "")) === "https";

  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-request-id", requestId);
  const response = NextResponse.next({ request: { headers: requestHeaders } });
  const headers = cmsSecurityHeaders({
    isDev: process.env.NODE_ENV === "development",
    isHttps,
    siteOrigin: originOf(process.env.SITE_URL),
    mediaOrigin: originOf(process.env.S3_PUBLIC_URL),
  });
  for (const [key, value] of Object.entries(headers)) response.headers.set(key, value);
  response.headers.set("x-request-id", requestId);
  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
