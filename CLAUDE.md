@AGENTS.md

## İleride yapılacaklar (backlog — 17.09.2026, henüz başlanmadı)

Kullanıcıyla konuşuldu, "daha sonranın konusu ama aklımızda tutalım". Biri istemeden başlama; başlarken önce kullanıcıyla kapsamı netleştir.

- ~~**Zamanlanmış yayın**~~ — **YAPILDI 18.09.2026 (kampanyalar için), tasks.md #59.** Maker "İleri Tarihte Yayınla" alanına İstanbul saatiyle tarih/saat seçer, Checker "Onayla ve Planla" der, `src/lib/campaignSchedule.ts` içindeki zamanlayıcı (30 sn'de bir, Postgres advisory lock ile HPA'da tek pod) zamanı gelince yayınlar; onaydan sonraki her içerik değişikliği onayı düşürür. Payload'ın kendi `schedulePublish`'i kullanılmadı: işi planlayan kullanıcı adına yayınlıyor ve maker/checker kuralımızı bilmiyor. Kalan: aynı akışın diğer içerik tiplerine (blog, sayfa, duyuru) genişletilmesi.
- ~~**Saat dilimi (OCP)**~~ — **YAPILDI 18.09.2026.** İki configmap'e `TZ: "Europe/Istanbul"` eklendi (node:24-alpine'da çalıştığı doğrulandı). Doğruluk buna bağlı DEĞİL: zamanlar UTC anı olarak saklanıp anla karşılaştırılıyor, gösterim açıkça `Europe/Istanbul` ile yapılıyor (`src/lib/istanbulTime.ts`; sitede `campaignDate.ts`, `istanbulDay.ts`). Uçtan uca test sunucu `TZ=UTC` ile koşularak yapıldı.
- **Mobil uygulama kampanyalarının buraya taşınması:** Mobil app'teki kampanyalar da bu CMS'ten yönetilebilir.
- **Form doldurma ile kayıt (register) alma:** Kampanya katılımı için form ve başvuru toplama. Kişisel veri içerdiği için KVKK/aydınlatma metni, saklama süresi ve erişim yetkisi (hangi rol başvuruları görür/dışa aktarır) baştan tasarlanmalı.
- **Kampanya yönetimi:** Katılım, başvuru, dönem ve sonuç takibini içeren daha kapsamlı bir kampanya yönetim ekranı. Kapsamı henüz tanımlı değil, yukarıdaki iki madde ile birlikte netleştirilecek.
- **301 / 404 yönetimi (product ekibinin SEO ek istek listesi, 17.09.2026):** Şu an kaldırılan bir kampanya, blog, temsilci ya da sayfa düz 404 veriyor; slug değişince eski adres kırılıyor. Vendor sitesinde de aynı durum var, ama bizim yapmamız isteniyor. Kapsam:
  - CMS'te bir "Yönlendirmeler" ekranı (eski adres → yeni adres, 301/302, maker→checker).
  - Otomatik yönlendirme: slug değişince eski adres için; kapanan bayi, biten kampanya ve silinen blog için (hedef, ör. /temsilciliklerimiz, /kampanyalar, /blog, kural olarak tanımlanmalı).
  - Sitede bunları uygulayan katman (Next `proxy`/middleware ya da catch-all) ve sitemap'ten yönlendirilen adreslerin çıkarılması.
  - Footer ve menüdeki kırık iç linklerin raporlanması.
- **IndexNow:** Aynı listede. Hem vendor'da hem bizde yok. Yayın/silme sonrası CMS'in zaten yaptığı revalidate çağrısının yanına eklenebilir; anahtar dosyası sitede sunulur.
