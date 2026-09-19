# Uçtan uca testler (Playwright)

19.09.2026 — kritik akışların tarayıcıda, gerçek CMS + site + veritabanıyla testi.

| Dosya | Akış |
|---|---|
| `maker-checker.e2e.ts` | Growth Maker duyuru taslağı gönderir (yayınlayamaz, API ile zorlasa 403) → Growth Checker yayınlar → sitede /duyurular'da görünür |
| `scheduled-publish.e2e.ts` | Growth Maker ileri tarihli kampanya gönderir → Checker "Onayla ve Planla" → zamanlayıcı o anda yayınlar → sitede açılır (~2 dk) |
| `share-link.e2e.ts` | Taslak kampanyaya önizleme linki → CMS oturumu olmayan tarayıcıda ÖNİZLEME bandıyla açılır → iptal edilince "iptal edilmiş" |
| `bulk-and-trash.e2e.ts` | Toplu yayın "her birini inceledim" beyanı olmadan yapılamaz → toplu çöpe taşıma → Çöp sekmesinden geri yükleme (taslak döner) → Checker kalıcı silemez |
| `cookie-consent.e2e.ts` | Çerez bandı ilk ziyarette çıkar → ayarlardan seçim → çerez yazılır, tekrar çıkmaz |

## Çalıştırma

Yerel yığın gerekir (testler başka bir adrese karşı çalışmayı reddeder):

1. Postgres + MinIO (`docker compose up -d postgres minio`).
2. CMS: `CMS_AUTO_LOGIN=true` ile, zamanlayıcı AÇIK (`SCHEDULED_PUBLISH_DISABLED` verilmeden), `http://localhost:3099`.
3. Site: `CMS_API_URL=http://localhost:3099/api`, `http://localhost:3098`.
4. `npm run test:e2e` (ilk sefer: `npx playwright install chromium`).

Adresler `E2E_CMS_URL` / `E2E_SITE_URL`, veritabanı `DATABASE_URI` ile değiştirilebilir (verilmezse `.env`'den localhost:5432).

## Nasıl çalışır

- Roller: otomatik giriş yapan tek kullanıcının (`admin@vodafonepay.local`) rolü test sırasında veritabanında değiştirilir; test bitince (hata olsa da) `new_vertical_maker`'a döner. Bu yüzden testler sırayla, tek worker ile koşar.
- Veri: her test kendi kayıtlarını `E2E <tarih saat>` başlığıyla oluşturur ve sonunda çöpe taşıyıp kalıcı siler. Başka kayda dokunmaz. Kampanyalar için var olan bir görsel ve kampanya kategorisi okunur.
- Çıktı: her adımın ekran görüntüsü `e2e-results/`, HTML rapor `e2e-report/`.
- Not: yerelde `CMS_AUTO_LOGIN` açıkken sitenin CMS okumaları da admin sayılır ve taslaklar sitede görünür; bu yüzden "taslak sitede yok" kontrolü yapılmıyor. `src/env.ts` bu bayrağı bir Kubernetes/OpenShift pod'unda reddeder.
