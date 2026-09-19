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
  3. ✅ **Kırık link raporu** (YAPILDI 18.09.2026, tasks.md #62): site içindeki kırık linkler ve 404 alan adresler, /admin/broken-links. 301 yönetimi gelince 404 satırından yönlendirme oluşturma bağlanacak.
  4. ✅ **Toplu işlemler** (YAPILDI 18.09.2026, tasks.md #63): liste ekranında seçili kayıtları birlikte yayınlama / yayından kaldırma / taslak silme; Growth Maker kampanyalarda toplu "yayından kaldırma talebi". Maker→checker kuralları her kayıt için ayrı ayrı sunucuda uygulanıyor, sonuç kayıt kayıt nedeniyle gösteriliyor, denetim kaydına özet satırı düşüyor.

## ⚠️ Açık riskler ve bekleyen kararlar (19.09.2026 itibarıyla)

18.09.2026'daki beş işin production gözden geçirmesinden (tasks.md #64) ve sonrasından kalanlar. Bir madde kapatılınca buradan silinmeli ya da "KAPANDI (tarih, tasks.md #)" diye işaretlenmeli.

| # | Risk / karar | Durum | Not |
|---|---|---|---|
| R1 | Editörlerin kendi "Önizle" linki `PREVIEW_SECRET`'ı URL'de taşıyor; bu sırla TÜM taslaklar okunabilir (tarayıcı geçmişi, proxy logları, ekran paylaşımı). | Açık — güvenlik | Öneri: editör başına kısa ömürlü imzalı anahtar (paylaşılabilir önizleme linkindeki gibi tek belgeye bağlı). |
| R2 | OCP `k8s/networkpolicy.yaml` egress'i `{}` (sınırsız). Kırık link taramasındaki SSRF kodda kapatıldı (iç ağ adreslerine gidilmiyor) ama asıl koruma egress'i daraltmak. | Açık — altyapı | Ağ ekibiyle: CMS pod'u yalnız Postgres, MinIO, site Service'i ve gerekiyorsa dış HTTPS. |
| R3 | Kırık link dış kontrolünde DNS rebinding ile kalan küçük SSRF açığı (ad çözümlemesi kontrolden sonra değişebilir). | Açık — düşük | Tam kapatmak için çözülen IP'ye sabitlenmiş bağlantı gerekir; R2 yapılırsa pratikte kapanır. |
| R4 | Checker kayıtları tek tek önizlemeden toplu yayınlayabiliyor. | KARAR VERİLDİ 19.09.2026 (tasks.md #65) | Kullanıcı: toplu yayın kalsın. Kutucukla "her birini inceledim ve onaylıyorum" beyanı zorunlu; sunucu da istiyor, denetim kaydına yazılıyor. |
| R5 | Growth Maker, Checker onayı almamış bir taslak için dışarıya önizleme linki üretebiliyor (tasarım gereği). | Karar bekliyor | Yalnız Checker'lar üretsin istenirse `ShareLinks.ts` create uç noktasında tek satırlık rol kontrolü. |
| R6 | KVKK saklama süresi yok: `not_found_hits` (adres, geldiği sayfa), `share_links` (not alanı: kişi adı olabilir), toplu işlem denetim satırları. | Karar bekliyor — hukuk | Saklama süresi belirlenince periyodik silme işi (zamanlayıcıya eklenebilir). |
| R7 | Önizleme linki görüntülenme sayısı Teams/Slack/WhatsApp link önizleme botlarıyla şişiyor. | Açık — düşük | Bot user-agent'ları sayılmayabilir; "kaç kez açıldı" kesin değildir. |
| R8 | Site `/api/not-found` hız sınırları pod başına bellekte; HPA ile N pod = N kat sınır. | Açık — düşük | Satır sınırı ve eskiyen kayıt silme ayrıca koruyor. Gerekirse paylaşımlı sayaç (Postgres). |
| R9 | Gece yarısı biten kampanya sitenin listesinde önbellek yüzünden 1 saate kadar görünmeye devam edebilir. | Açık — düşük | Zamanlayıcı İstanbul gece yarısında `campaigns` etiketini tazeleyebilir. |
| R10 | Taslaklı 14 koleksiyonda Payload'ın toplu "Düzenle"si kaldırıldı; `?where=` ile toplu REST yazma artık 403. | Bilgi | Kodda kullanan yer yok; dışarıdan toplu yazan bir script varsa etkilenir. |
| R11 | 18.09 işleri için SonarQube taraması yapılmadı (AGENTS.md "büyük değişiklik sonrası Sonar" kuralı). | Açık — süreç | Push'tan önce `docker compose -f ../vodafonepaycomtr/tools/sonarqube/docker-compose.yml up -d` + `SONAR_TOKEN=… scripts/sonar-scan.sh` (her iki repoda). Bağımlılık değişmediği için Trivy gerekmiyor. |
| R12 | Bekleyen migration (`clover-schema-migration-17-09-to-18-09-2026.sql`, §11–§15) canlıda çalışmadan deploy edilirse ilgili ekranlar 500 verir; §15 olmadan toplu işlem özet denetim satırı yazılamaz. | Açık — deploy | Aşağıdaki "Bekleyen deploy adımları". |
| R13 | Önceden bilinen, kapsam dışı bırakılanlar: gerçek LDAP girişi bağlı değil; içerik test→canlı taşıma yok; içerik çok dilli değil; SEO analitiği (GA4/GTM) yok. | Açık — yol haritası | RFP denklik sayfasında da listeli. |

## ⚠️ Bekleyen deploy adımları (canlı DB'de HENÜZ ÇALIŞTIRILMADI — 18.09.2026)

Kullanıcı: "bu sessionda henüz deploy etmicem, geliştirmeler devam edecek." Canlıya çıkarken aşağıdakiler yapılmadan yeni imaj deploy edilmemeli, yoksa ilgili ekranlar "column does not exist" hatasıyla 500 döner. **Deploy'a kadar yapılan her yeni şema değişikliği AYNI dosyaya yeni bölüm olarak eklenmeli** ve bu liste güncellenmeli. Dosya canlıda çalıştırılınca bu bölüm "çalıştırıldı (tarih)" diye işaretlenir, sonraki değişiklikler yeni bir `clover-schema-migration-18-09-to-<tarih>.sql` dosyasında başlar.

**Canlıda zaten çalıştırılmış olanlar** (tekrar çalıştırmayın): `clover-schema-migration-01-09-to-02-09-2026.sql`, `nav-links-products-menu-migration-16-09-2026.sql`, `clover-schema-migration-02-09-to-17-09-2026.sql`. Hepsi 17.09.2026'da çalıştırıldı. `nav-links` scripti taşıyamadığı "Yeni Menü Linki" test kaydını bıraktı; o kayıt elle silindi.

**Çalıştırılacak tek dosya:** `scripts/clover-schema-migration-17-09-to-18-09-2026.sql`
- §11 — SEO Dosyaları global'i: `seo_files` / `_seo_files_v` tabloları, robots.txt ve llms.txt başlangıç içeriği (VERİ).
- §12 — Kampanya zamanlanmış yayını: `campaigns` / `_campaigns_v` kolonları, saat dilimi enum'ları, `review_status`'a `'scheduled'` değeri.
- §13 — Paylaşılabilir önizleme linkleri: `share_links` tablosu, `payload_locked_documents_rels.share_links_id`.
- §14 — Kırık link raporu: `not_found_hits` tablosu, `payload_locked_documents_rels.not_found_hits_id`.
- §15 — Toplu işlemler: `enum_audit_logs_action`'a `'bulk'` değeri.
- Tekrar çalıştırılabilir. PostgreSQL 12+ gerekir. Zincirle birlikte boş DB'de doğrulandı; şema dev DB ile birebir aynı.

**Deploy sırası:**
1. DB yedeği al.
2. DBeaver ayarları: Window → Preferences → Editors → SQL Editor → SQL Processing → "Blank line is statement delimiter" = **Never**; araç çubuğunda commit modu **Auto**.
3. Dosyayı **File → Open File** ile aç; metni kopyalayıp yapıştırma, çünkü hizalama boşlukları bölünmez boşluğa dönüşüp hata veriyor. Doğru bağlantıyı seçip **Alt+X** ile tamamını çalıştır.
4. Kontrol:
   ```sql
   SELECT to_regclass('public.seo_files') AS seo, (SELECT count(*) FROM seo_files) AS seo_kaydi,
          (SELECT count(*) FROM information_schema.columns WHERE table_name='campaigns' AND column_name='scheduled_publish_at') AS zamanlama,
          to_regclass('public.share_links') AS onizleme, to_regclass('public.not_found_hits') AS kirik_link,
          'bulk' = ANY(enum_range(NULL::enum_audit_logs_action)::text[]) AS toplu;
   ```
   Beklenen: `seo_files | 1 | 1 | share_links | not_found_hits | t`.
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
   - Site Yapısı → Kırık Linkler → "Taramayı başlat" çalışıyor. Sitede olmayan bir adres açılınca birkaç saniye içinde "404 alan adresler" listesine düşüyor. Tarama siteye SITE_REVALIDATE_URL'nin origin'inden (küme içi `http://vodafonepaycomtr:3000`) gidiyor; farklıysa `SITE_INTERNAL_URL` tanımlanabilir.
   - Önizleme linki için iki pod'da da `PREVIEW_SECRET` aynı olmalı (zaten öyle), ve Clover'ın `SITE_URL`'i sitenin dışarıdan açılan adresi olmalı; link bu adresle üretilir.
   - Toplu işlemler: bir liste ekranında (ör. Blog Yazıları) birkaç satır seçince tablonun üstünde "N kayıt seçildi" çubuğu çıkıyor; Denetim Kayıtları'nda işlem türü "Toplu işlem" olan satır görünüyor.
   - 18.09.2026 gözden geçirme (#64): şema değişikliği YOK, migration dosyası aynı. Zamanlanmış yayın yayınlayamazsa (ör. onaydan sonra silinen kategori) artık 30 sn'de bir sonsuza dek denemiyor: bekleme süresi 1 saate kadar katlanıyor, ilk hata Denetim Kayıtları'na "zamanlanmış yayını BAŞARISIZ" diye düşüyor, kampanya ekranında turuncu "Yayınlanamadı" notu çıkıyor. Kırık Linkler'in dış link kontrolü iç ağ adreslerine (10.x, 172.16–31.x, 169.254.x, localhost, Service adları) istek atmıyor; yine de `k8s/networkpolicy.yaml` egress'i hâlâ `{}` — ağ ekibiyle daraltılmalı.

Detaylar: `tasks.md` #58, #59, #63 ve #64.
