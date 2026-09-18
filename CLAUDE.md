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
- **Ürün ekibine önerilen geliştirmeler (18.09.2026, kullanıcı onayladı, bu sırayla):**
  1. ✅ **SEO asistanı** (WordPress Yoast benzeri, YAPILDI 18.09.2026): kampanya, blog ve sayfa ekranında, kaydetmeden önce içeriğin yanında başlık ve açıklama uzunluğu, Google sonuç önizlemesi, sosyal medya kartı önizlemesi, anahtar kelime, adres ve açıklayıcı olmayan alt metin uyarıları. → tasks.md #60.
  2. ✅ **Paylaşılabilir önizleme linki** (YAPILDI 18.09.2026, tasks.md #61): CMS hesabı olmayan birine (hukuk, pazarlama müdürü) süreli, tek içeriğe özel taslak linki.
  3. **Kırık link raporu:** site içindeki kırık linkler ve 404 alan adresler; 301/404 yönetimiyle birlikte.
  4. **Toplu işlemler:** birden fazla kaydı birlikte yayınlama / yayından kaldırma. Maker→checker kuralları her kayıt için ayrı ayrı geçerli olmalı.

## ⚠️ Bekleyen deploy adımları (canlı DB'de HENÜZ ÇALIŞTIRILMADI — 18.09.2026)

Kullanıcı: "bu sessionda henüz deploy etmicem, geliştirmeler devam edecek." Canlıya çıkarken aşağıdakiler yapılmadan yeni imaj deploy edilmemeli, yoksa ilgili ekranlar "column does not exist" hatasıyla 500 döner. **Deploy'a kadar yapılan her yeni şema değişikliği AYNI dosyaya yeni bölüm olarak eklenmeli** ve bu liste güncellenmeli. Dosya canlıda çalıştırılınca bu bölüm "çalıştırıldı (tarih)" diye işaretlenir, sonraki değişiklikler yeni bir `clover-schema-migration-18-09-to-<tarih>.sql` dosyasında başlar.

**Canlıda zaten çalıştırılmış olanlar** (tekrar çalıştırmayın): `clover-schema-migration-01-09-to-02-09-2026.sql`, `nav-links-products-menu-migration-16-09-2026.sql`, `clover-schema-migration-02-09-to-17-09-2026.sql`. Hepsi 17.09.2026'da çalıştırıldı. `nav-links` scripti taşıyamadığı "Yeni Menü Linki" test kaydını bıraktı; o kayıt elle silindi.

**Çalıştırılacak tek dosya:** `scripts/clover-schema-migration-17-09-to-18-09-2026.sql`
- §11 — SEO Dosyaları global'i: `seo_files` / `_seo_files_v` tabloları, robots.txt ve llms.txt başlangıç içeriği (VERİ).
- §12 — Kampanya zamanlanmış yayını: `campaigns` / `_campaigns_v` kolonları, saat dilimi enum'ları, `review_status`'a `'scheduled'` değeri.
- §13 — Paylaşılabilir önizleme linkleri: `share_links` tablosu, `payload_locked_documents_rels.share_links_id`.
- Tekrar çalıştırılabilir. PostgreSQL 12+ gerekir. Zincirle birlikte boş DB'de doğrulandı; şema dev DB ile birebir aynı.

**Deploy sırası:**
1. DB yedeği al.
2. DBeaver ayarları: Window → Preferences → Editors → SQL Editor → SQL Processing → "Blank line is statement delimiter" = **Never**; araç çubuğunda commit modu **Auto**.
3. Dosyayı **File → Open File** ile aç; metni kopyalayıp yapıştırma, çünkü hizalama boşlukları bölünmez boşluğa dönüşüp hata veriyor. Doğru bağlantıyı seçip **Alt+X** ile tamamını çalıştır.
4. Kontrol:
   ```sql
   SELECT to_regclass('public.seo_files') AS seo, (SELECT count(*) FROM seo_files) AS seo_kaydi,
          (SELECT count(*) FROM information_schema.columns WHERE table_name='campaigns' AND column_name='scheduled_publish_at') AS zamanlama,
          to_regclass('public.share_links') AS onizleme;
   ```
   Beklenen: `seo_files | 1 | 1 | share_links`.
5. Configmap'leri uygula; ikisine de `TZ: "Europe/Istanbul"` eklendi. `clover/` ve `vodafonepaycomtr-site/` içinde ayrı ayrı `oc apply -f k8s/configmap.yaml`.
6. Önce Clover'ı, sonra siteyi deploy et (`oc rollout status ...`).
7. Site önbelleğini tazele. Build sırasında CMS'e ulaşılamazsa sayfalar eksik veriyle önbelleğe giriyor:
   ```bash
   oc exec deploy/vodafonepaycomtr -- sh -c 'for t in seo-files footer-settings blog-posts campaigns nav-links contact-info announcements faq-items pages; do wget -qO- --header="x-revalidate-secret: $REVALIDATE_SECRET" --header="content-type: application/json" --post-data="{\"tag\":\"$t\"}" http://localhost:3000/api/revalidate; echo; done'
   ```
8. Kontrol:
   - CMS: Site Yapısı → SEO Dosyaları açılıyor; bir kampanyada "İleri Tarihte Yayınla" alanı görünüyor.
   - Site: `/robots.txt` ve `/llms.txt` açılıyor.
   - Clover logunda `[scheduled-publish] scheduler started` satırı var.
   - Bir kampanyada "Önizleme linki paylaş" ile link oluştur ve gizli pencerede aç: önizleme bandı görünmeli. Linki panelden iptal et; aynı link "iptal edilmiş" demeli.
   - Önizleme linki için iki pod'da da `PREVIEW_SECRET` aynı olmalı (zaten öyle), ve Clover'ın `SITE_URL`'i sitenin dışarıdan açılan adresi olmalı; link bu adresle üretilir.

Detaylar: `tasks.md` #58 ve #59.
