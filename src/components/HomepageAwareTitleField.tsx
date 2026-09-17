"use client";

import { useEffect } from "react";
import { TextField, useField, useFormFields } from "@payloadcms/ui";
import type { TextFieldClientProps } from "payload";
import { useAdminLocale } from "./useAdminLocale";

/**
 * 16.09.2026 kullanıcı isteği: "bu sayfa anasayfa olsun seçilirse zaten
 * başlık vermesine gerek kalmaz, başlık alanı kilitlensin dinamik olarak ve
 * 'anasayfa için bir başlık girmenize gerek kalmadı' gibi bir mesaj
 * gösterilsin."
 *
 * Neden özel bir bileşen gerekiyor: Payload'da `admin.readOnly` bir boolean,
 * fonksiyon DEĞİL (payload/dist/fields/config/types.d.ts) — yani "şu kutu
 * işaretliyse kilitle" diye koşullu bir salt-okunurluk alan tanımıyla
 * yazılamıyor. AutoSlugField ile aynı çözüm: alanı biz render ediyoruz.
 *
 * Neden başlığı BOŞ bırakmıyoruz: `title` zorunlu ve slug ondan türüyor
 * (generateSlug). Zorunluluğu kaldırmak TÜM sayfaları etkilerdi, üstelik
 * Payload zorunlu alan doğrulamasını TARAYICIDA koşturuyor — boş başlıklı
 * bir kayıt zaten hiç submit edilemezdi (Media.alt'ta yaşadığımızın aynısı).
 * Onun yerine kutu işaretlenince başlığı biz dolduruyoruz ve kilitliyoruz:
 * editör hiçbir şey yazmıyor, veri modeli de bozulmuyor.
 *
 * Var olan bir başlığın ÜZERİNE YAZMIYORUZ. "Kurumsal Yönetim" başlıklı bir
 * sayfayı anasayfa yapan editörün başlığını sessizce "Anasayfa"ya çevirmek
 * veri kaybı olurdu; sadece boşsa dolduruyoruz, doluysa olduğu gibi
 * kilitliyoruz.
 */
const DEFAULT_HOMEPAGE_TITLE = "Anasayfa";

const STRINGS = {
  tr: {
    note: `Bu sayfa anasayfa olarak işaretli — başlık girmenize gerek yok, sayfa "/" adresinde yayınlanacak. Başlık yalnızca yönetim panelindeki listelerde görünür.`,
  },
  en: {
    note: `This page is marked as the homepage — you don't need to enter a title, it will be published at "/". The title is only used in admin listings.`,
  },
} as const;

export default function HomepageAwareTitleField(props: TextFieldClientProps) {
  const locale = useAdminLocale();
  const { value, setValue } = useField<string>({ path: props.path });
  const isHomepage = useFormFields(([fields]) => Boolean(fields.isHomepage?.value));

  useEffect(() => {
    // Sadece boşken doldur — editörün yazdığı başlığı asla ezme.
    if (isHomepage && !value) setValue(DEFAULT_HOMEPAGE_TITLE);
  }, [isHomepage, value, setValue]);

  return (
    <>
      <TextField {...props} readOnly={props.readOnly || isHomepage} />
      {isHomepage && <p className="field-description">{STRINGS[locale].note}</p>}
    </>
  );
}
