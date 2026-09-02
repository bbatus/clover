import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

/**
 * RFP §3.5.7: admin panelinin ilk açılışta Türkçe olması gerekiyor —
 * tarayıcı dili ne olursa olsun. Payload'ın kendi dil çözümlemesi
 * (getRequestLanguage) sırayla payload-lng cookie -> Accept-Language header
 * -> fallbackLanguage'a bakıyor; yani cookie yokken İngilizce tarayıcılı bir
 * kullanıcı Accept-Language üzerinden doğrudan İngilizce görür,
 * fallbackLanguage="tr" hiç devreye girmez. Bu proxy ilk ziyarette
 * payload-lng cookie'sini tr olarak sabitler; kullanıcı admin panelinden
 * bilinçli olarak EN'e geçerse (Payload kendi cookie'sini günceller) bu
 * proxy tekrar müdahale etmez.
 *
 * 02.09.2026 kullanıcı geri bildirimi: test ortamındaki route çıplak halde
 * (clover-vepas-ai-am.apps.tst-vcloud.vpara.local, /admin olmadan) 404
 * basıyordu — `src/app/(payload)` sadece /admin ve /api altını kapsıyor, `/`
 * için hiç sayfa yok. Editör bu adrese geldiğinde login ekranını görmeli.
 * Ayrı bir `app/page.tsx` eklemek root layout (html/body) gerektirdiği için
 * en az riskli yol burada tek satırlık bir yönlendirme — bu dosya zaten
 * Next'in tek proxy giriş noktası (middleware.ts bu Next sürümünde proxy.ts
 * ile birlikte kullanılamıyor, build hatası veriyor).
 */
export function proxy(request: NextRequest) {
  if (request.nextUrl.pathname === "/") {
    return NextResponse.redirect(new URL("/admin", request.url));
  }

  if (request.cookies.has("payload-lng")) {
    return NextResponse.next();
  }

  request.cookies.set("payload-lng", "tr");
  const response = NextResponse.next({ request });
  response.cookies.set("payload-lng", "tr", { path: "/", sameSite: "lax" });
  return response;
}

export const config = {
  matcher: ["/", "/admin/:path*"],
};
