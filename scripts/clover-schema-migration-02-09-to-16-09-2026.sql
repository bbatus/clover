-- =============================================================================
-- Clover (Payload CMS) — şema göç scripti: 02.09.2026 → 16.09.2026
--
-- ÖNCEKİ HALKA: scripts/clover-schema-migration-01-09-to-02-09-2026.sql
-- Bu script onun bıraktığı durumdan devam eder.
--
-- KAPSAM — tek bir değişiklik: `media.alt` artık zorunlu değil.
--
-- NEDEN: Bir kampanya/sayfa içindeki görsel alanından masaüstünden dosya
-- yükleyen editör, alan `required: true` olduğu için alt metnini yazmadan
-- yükleme çekmecesini kapatamıyordu (zorunlu alan doğrulaması tarayıcıda
-- koşuyor). Alan opsiyonel yapıldı; boş kalmasın diye Media.ts'e
-- `deriveAltFromFilename` beforeChange hook'u eklendi — alt boşsa dosya
-- adından okunabilir bir metin yazıyor, editör sonradan düzeltebiliyor.
--
-- Payload `required: true`yu üst seviye koleksiyon alanlarında gerçek bir
-- NOT NULL kısıtına çeviriyor (blok/array içindeki alanlarda ÇEVİRMİYOR —
-- 02.09'daki `hero.heading` değişikliğinin DB'ye hiç dokunmamasının sebebi
-- buydu; ikisini karıştırmayın, `\d <tablo>` ile bakın). Bu yüzden bu sefer
-- gerçekten bir kısıt düşürmek gerekiyor: kod alanı opsiyonel sayarken
-- veritabanının NOT NULL tutması, kod ile şemanın sessizce ayrışması olurdu.
--
-- VERİ KAYBI YOK: hiçbir satır silinmiyor/değişmiyor, sadece bir kısıt
-- gevşetiliyor. Mevcut tüm `alt` değerleri olduğu gibi kalır.
-- (Yerelde uygulanmadan önce kontrol edildi: alt'ı boş/NULL olan 0 kayıt.)
--
-- NASIL UYGULANIR (DBeaver): hedef veritabanına bağlan, SQL Editor'de bu
-- dosyayı aç, "Execute script" (Alt+X) ile TAMAMINI çalıştır. Tek
-- transaction (BEGIN/COMMIT) — hata olursa hiçbir şey uygulanmaz.
--
-- TEKRAR ÇALIŞTIRILABİLİR: `DROP NOT NULL` zaten düşürülmüş bir kısıtta
-- hata vermez, hiçbir şey yapmaz.
-- =============================================================================

BEGIN;

ALTER TABLE public.media ALTER COLUMN alt DROP NOT NULL;

COMMIT;
