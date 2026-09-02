import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

/**
 * 02.09.2026 kullanıcı geri bildirimi: OCP'deki route (örn.
 * clover-vepas-ai-am.apps.tst-vcloud.vpara.local) çıplak halde 404
 * basıyordu — `src/app/(payload)` sadece `/admin` ve `/api` altını
 * kapsıyor, `/` için hiç sayfa yok. Bir editör bu adrese gelince login
 * ekranını görmesi lazım, 404 değil. Root layout'u (html/body) sadece
 * `(payload)/layout.tsx`'te var, o yüzden burada ayrı bir `app/page.tsx`
 * eklemek yerine — en basit ve en az riskli yol — middleware'de SADECE `/`
 * yolunu `/admin`'e yönlendirmek (Payload zaten oturum yoksa kendi
 * içinde login'e düşürüyor).
 */
export function middleware(request: NextRequest) {
  if (request.nextUrl.pathname === "/") {
    return NextResponse.redirect(new URL("/admin", request.url));
  }
  return NextResponse.next();
}

export const config = {
  matcher: "/",
};
