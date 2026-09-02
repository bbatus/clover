"use client";

import { useEffect } from "react";
import { useRouter, useSearchParams } from "next/navigation";

/**
 * 02.09.2026 kullanıcı geri bildirimi: "growth maker ve checkerin dashboard
 * ına atmalı otomatik sanki en son hangi sayfadaysa oraya atıyor ilk
 * loginde" — Payload'ın kendi LoginForm'u `?redirect=` query param'ını
 * okuyup login sonrası oraya yönlendiriyor (bkz.
 * @payloadcms/next/dist/views/Login/LoginForm). Bu param, oturumu düşmüş
 * bir kullanıcı eski bir admin linkini (örn. eski bir kampanya sayfası)
 * tekrar açtığında Payload tarafından otomatik ekleniyor — bizim kodumuzda
 * hiçbir yerde set edilmiyor. Login ekranı her açıldığında bu param'ı
 * URL'den siliyoruz ki LoginForm'un `useSearchParams()` ile okuduğu değer
 * boş kalsın ve login sonrası her zaman panele (dashboard) düşsün.
 */
export default function StripLoginRedirectParam() {
  const router = useRouter();
  const searchParams = useSearchParams();

  useEffect(() => {
    if (searchParams.has("redirect")) {
      router.replace("/admin/login");
    }
  }, [searchParams, router]);

  return null;
}
