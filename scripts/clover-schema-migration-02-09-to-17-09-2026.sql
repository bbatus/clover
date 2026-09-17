-- =============================================================================
-- Clover (Payload CMS) — şema göç scripti: 02.09.2026 → 17.09.2026
--
-- ÖNCEKİ HALKA: scripts/clover-schema-migration-01-09-to-02-09-2026.sql
-- Bu script onun bıraktığı durumdan devam eder.
--
-- (16.09.2026'da `...-02-09-to-16-09-2026.sql` adıyla sadece 1. bölümle
-- yazılmıştı; hiçbir yere uygulanmadan genişletilip yeniden adlandırıldı —
-- "son hali tek script'te dursun" kuralı.)
--
-- ⚠️ ÇALIŞTIRMA SIRASI ÖNEMLİ — ÖNCE BUNU, SONRA BU SCRIPT'İ ÇALIŞTIRIN:
--     scripts/nav-links-products-menu-migration-16-09-2026.sql   (VERİ göçü)
-- Aşağıdaki 2. bölüm `header-products` enum değerini düşürüyor; o değeri
-- taşıyan tek bir satır bile kalmışsa tür dönüşümü hata verir ve BEGIN/COMMIT
-- sayesinde bu script HİÇBİR ŞEY uygulamadan geri döner (güvenli başarısızlık).
-- Yani yanlış sırada çalıştırmak veri bozmaz, sadece hata verir — veri
-- script'ini çalıştırıp bunu tekrar deneyin.
--
-- KAPSAM:
--   1. media.alt                  → NOT NULL kısıtı kaldırıldı (16.09)
--   2. nav_links section enum'ları → 'header-products' değeri düşürüldü (16.09)
--   3. pages.is_homepage          → YENİ kolon (17.09)
--      _pages_v.version_is_homepage
--   4. Mevcut anasayfanın işaretlenmesi (VERİ, 3. bölümle ayrılmaz)
--
--   5. Önceden var olan şema kaymasının düzeltilmesi (17.09'da bulundu —
--      içinde prod'u etkileyen gerçek bir taslak-kaydetme hatası var)
--
--   6. Ücretler & Limitler (17.09) → YENİ kolonlar + 2 YENİ enum tipi
--      fee_rows.row_type / highlight_value / note (+ _fee_rows_v karşılıkları)
--      limit_tables.footnote (+ _limit_tables_v.version_footnote)
--   7. SSS cevabı düz metin → zengin metin (17.09) → faq_items.answer ve
--      _faq_items_v.version_answer varchar → jsonb (VERİ DÖNÜŞÜMÜYLE)
--
-- NASIL DOĞRULANDI (elle türetilmedi): yerel geliştirme DB'sine Payload'ın
-- kendi push-tabanlı şema senkronu uygulandı; ardından
-- clover-test-db-schema.sql → ...01-09-to-02-09-2026.sql → bu script boş bir
-- scratch DB'ye sırayla yüklenip TÜM ŞEMANIN `pg_dump --schema-only` çıktısı
-- dev DB'ninkiyle karşılaştırıldı — birebir aynı (10.933 satır; 6. bölüm eklendikten sonra 17.09'da tekrar: 11.479 satır, yine birebir). 4. bölümün
-- veri güncellemesi ayrıca gerçek verinin bir kopyasında çalıştırılıp
-- sonuçları kontrol edildi.
--
-- NASIL UYGULANIR (DBeaver): hedef DB'ye bağlan, SQL Editor'de aç, "Execute
-- script" (Alt+X) ile TAMAMINI çalıştır. Tek transaction.
--
-- BİR KEZ ÇALIŞTIRILIR: bütün olarak tekrar çalıştırılabilir DEĞİL (yeniden
-- adlandırılan index'ler ikinci seferde bulunamaz). İkinci denemede hata
-- verirse transaction hiçbir şey uygulamadan geri döner — yani zararsız,
-- ama "zaten uygulanmış" demektir. Beklenen başlangıç durumu:
-- clover-test-db-schema.sql + clover-schema-migration-01-09-to-02-09-2026.sql.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------
-- 1. media.alt artık zorunlu değil (16.09.2026)
--
-- Bir kampanya/sayfa içindeki görsel alanından masaüstünden dosya yükleyen
-- editör, alan `required: true` olduğu için alt metnini yazmadan yükleme
-- çekmecesini kapatamıyordu. Alan opsiyonel yapıldı; boş kalmasın diye
-- Media.ts'e `deriveAltFromFilename` hook'u eklendi. Payload `required`ı ÜST
-- SEVİYE alanlarda gerçek NOT NULL'a çeviriyor (blok içindekilerde değil) —
-- bu yüzden kısıt burada gerçekten düşürülmeli. Veri kaybı yok.
-- -----------------------------------------------------------------------

ALTER TABLE public.media ALTER COLUMN alt DROP NOT NULL;

-- -----------------------------------------------------------------------
-- 2. nav_links: 'header-products' bölümü kaldırıldı (16.09.2026)
--
-- 'Ürünler' menüsünün iki kaynağı vardı (bu bölüm + Pages.showInProductsMenu)
-- ve aynı sayfa iki kez listelenebiliyordu; bu bölüm CMS'ten kalktı.
-- Postgres bir enum'dan değer SİLEMİYOR — Payload'ın kendi yaptığıyla aynı
-- yol izleniyor: eski tip yeniden adlandırılır, yenisi yaratılır, kolon
-- dönüştürülür, eski tip düşürülür. İki kolonda da default veya index yok.
-- -----------------------------------------------------------------------

ALTER TYPE public.enum_nav_links_section RENAME TO enum_nav_links_section__old;
CREATE TYPE public.enum_nav_links_section AS ENUM ('header-main', 'footer-kurumsal', 'footer-yasal');
ALTER TABLE public.nav_links
    ALTER COLUMN section TYPE public.enum_nav_links_section
    USING section::text::public.enum_nav_links_section;
DROP TYPE public.enum_nav_links_section__old;

ALTER TYPE public.enum__nav_links_v_version_section RENAME TO enum__nav_links_v_version_section__old;
CREATE TYPE public.enum__nav_links_v_version_section AS ENUM ('header-main', 'footer-kurumsal', 'footer-yasal');
ALTER TABLE public._nav_links_v
    ALTER COLUMN version_section TYPE public.enum__nav_links_v_version_section
    USING version_section::text::public.enum__nav_links_v_version_section;
DROP TYPE public.enum__nav_links_v_version_section__old;

-- -----------------------------------------------------------------------
-- 3. pages.is_homepage (17.09.2026)
--
-- `/` artık sihirli `anasayfa` slug'ını değil, "Bu Sayfa Anasayfa Olsun"
-- kutusu işaretli sayfayı basıyor. Eski bağ editörün göremeyeceği bir
-- anlaşmaya dayanıyordu: sayfaya "Vodafone Pay Ana Sayfa" başlığı verilse
-- slug farklı çıkar ve `/` onu bulamazdı. Tekillik uygulama katmanında
-- (`enforceSingleHomepage` hook'u) korunuyor.
-- -----------------------------------------------------------------------

ALTER TABLE public.pages     ADD COLUMN IF NOT EXISTS is_homepage boolean DEFAULT false;
ALTER TABLE public._pages_v  ADD COLUMN IF NOT EXISTS version_is_homepage boolean DEFAULT false;

-- -----------------------------------------------------------------------
-- 4. VERİ — mevcut anasayfayı işaretle
--
-- Bu adım olmadan deploy anında `/` 404 verir: kod artık kutuya bakıyor ve
-- henüz hiçbir sayfa işaretli değil. Bugüne kadar anasayfa `anasayfa`
-- slug'lı sayfaydı; o sayfa işaretleniyor.
--
-- Sürüm tablosunda o sayfanın TÜM sürümleri işaretleniyor, sadece güncel
-- olanı değil: eski bir sürüme geri dönmek, sayfanın anasayfa olma
-- özelliğini sessizce silip `/`'i 404'e düşürmemeli (o sürümler zaten
-- slug üzerinden anasayfaydı).
--
-- Tekrar çalıştırılabilir: zaten işaretli bir sayfa varsa hiçbir şey yapmaz.
-- `anasayfa` slug'lı sayfa yoksa da hiçbir şey yapmaz — o durumda panelden
-- anasayfa olacak sayfayı açıp kutuyu işaretleyin.
-- -----------------------------------------------------------------------

UPDATE public.pages
SET    is_homepage = true
WHERE  slug = 'anasayfa'
  AND  NOT EXISTS (SELECT 1 FROM public.pages WHERE is_homepage IS TRUE);

UPDATE public._pages_v v
SET    version_is_homepage = true
FROM   public.pages p
WHERE  v.parent_id = p.id
  AND  p.is_homepage IS TRUE
  AND  v.version_is_homepage IS NOT TRUE;

-- -----------------------------------------------------------------------
-- 5. ÖNCEDEN VAR OLAN ŞEMA KAYMASININ DÜZELTİLMESİ (17.09.2026'da bulundu)
--
-- Bu bölüm bu turun bir özelliğine ait DEĞİL. Bu script doğrulanırken
-- (taban zinciri + bu script → Payload'ın kendi push'unun ürettiği şema,
-- TAM pg_dump karşılaştırması) ortaya çıktı: 01.09.2026'da teslim edilen
-- `clover-test-db-schema.sql` taban script'i, 28.08'de ELLE yazılmış SQL'lerin
-- (growth-role-migration-28-08.sql, add-block-fields-28-08.sql,
-- drop-ghost-collections.sql) bıraktığı şemayı dondurmuştu — Payload'ın
-- gerçekte beklediği şemayı değil. O günkü doğrulamalar tablo bazlıydı, tam
-- şema diff'i yapılmadığı için görünmedi. Prod bu taban script'ten
-- kurulduğu için bu kayma prod'da da var.
--
-- 5a. GERÇEK BİR HATA: taslak modlu koleksiyonlarda NOT NULL kısıtları.
--     Kategoriler ve Temsilciler'e 28.08'de `versions.drafts` eklendi.
--     Payload, taslak modlu koleksiyonlarda zorunlu alanlara NOT NULL
--     KOYMAZ (taslak tanım gereği eksik olabilir). Elle yazılan SQL eski
--     kısıtları bırakmıştı. Sonucu: bir Maker eksik alanlı bir kategori /
--     temsilci TASLAĞI kaydettiğinde (02.09'dan beri taslak kaydı tarayıcı
--     doğrulamasını atlıyor) istek veritabanında NOT NULL ihlaliyle 500'e
--     düşer. Yayınlamada doğrulama zaten uygulama katmanında yapılıyor, yani
--     yayındaki içerik için hiçbir güvence kaybolmuyor.
-- -----------------------------------------------------------------------

ALTER TABLE public.categories ALTER COLUMN scope DROP NOT NULL;
ALTER TABLE public.categories ALTER COLUMN label DROP NOT NULL;
ALTER TABLE public.categories ALTER COLUMN slug  DROP NOT NULL;
ALTER TABLE public._categories_v ALTER COLUMN version_scope SET DEFAULT 'campaign'::public.enum__categories_v_version_scope;

ALTER TABLE public.representatives ALTER COLUMN business_name DROP NOT NULL;
ALTER TABLE public.representatives ALTER COLUMN address       DROP NOT NULL;
ALTER TABLE public.representatives ALTER COLUMN province      DROP NOT NULL;
ALTER TABLE public.representatives ALTER COLUMN district      DROP NOT NULL;

-- 5b. Emekli "hayalet" koleksiyonların (ProductHeroes / FeatureCards /
--     StepCards, 28.08'de silindi) artık enum tipleri. Tabloları çoktan
--     yok; tipler hiçbir kolon tarafından kullanılmıyor. Zararsızdı ama
--     Payload'ın şemasında yoklar. (Bir kolon hâlâ kullanıyor olsaydı
--     DROP TYPE hata verir, transaction geri döner — güvenli.)

DROP TYPE IF EXISTS public.enum_product_heroes_page;
DROP TYPE IF EXISTS public.enum_product_heroes_status;
DROP TYPE IF EXISTS public.enum__product_heroes_v_version_page;
DROP TYPE IF EXISTS public.enum__product_heroes_v_version_status;
DROP TYPE IF EXISTS public.enum_feature_cards_status;
DROP TYPE IF EXISTS public.enum__feature_cards_v_version_status;
DROP TYPE IF EXISTS public.enum_step_cards_status;
DROP TYPE IF EXISTS public.enum__step_cards_v_version_status;

-- 5c. Elle yazılan SQL'in Payload'dan farklı adlandırdığı index/FK'lar ve
--     eksik iki index. İşlevsel etkisi yok (aynı kolonlar); isimler
--     Payload'ınkiyle eşleşmezse bir sonraki şema senkronu bunları gereksiz
--     yere düşürüp yeniden yaratmaya çalışır.

ALTER INDEX public._categories_v_version_version_status_idx      RENAME TO _categories_v_version_version__status_idx;
DROP INDEX  public._categories_v_version_version_scope_idx;
CREATE INDEX version_scope_version_slug_idx ON public._categories_v USING btree (version_scope, version_slug);

ALTER INDEX public._documents_v_version_version_status_idx       RENAME TO _documents_v_version_version__status_idx;
CREATE INDEX _documents_v_version_version_filename_idx ON public._documents_v USING btree (version_filename);

ALTER INDEX public._representatives_v_version_version_status_idx RENAME TO _representatives_v_version_version__status_idx;
ALTER INDEX public._representatives_v_version_qr_code_idx        RENAME TO _representatives_v_version_version_qr_code_idx;

ALTER INDEX public.pages_blocks_video_list_dark_bg_image_idx     RENAME TO pages_blocks_video_list_dark_background_image_idx;
ALTER INDEX public._pages_v_blocks_video_list_dark_bg_image_idx  RENAME TO _pages_v_blocks_video_list_dark_background_image_idx;
ALTER TABLE public.pages_blocks_video_list
    RENAME CONSTRAINT pages_blocks_video_list_dark_background_image_id_media_fk
    TO pages_blocks_video_list_dark_background_image_id_media_id_fk;
ALTER TABLE public._pages_v_blocks_video_list
    RENAME CONSTRAINT _pages_v_blocks_video_list_dark_bg_image_id_media_fk
    TO _pages_v_blocks_video_list_dark_background_image_id_media_id_fk;

-- -----------------------------------------------------------------------------
-- 6. Ücretler & Limitler: satır türü, yeşil değer, tablo altı not (17.09.2026)
--
-- Canlıdaki /ucretler-ve-limitler sayfasını birebir üretebilmek için: ücret
-- tablosuna ara başlık satırı, yeşil ("Ücretsiz") değer, çok satırlı değer ve
-- tablonun altında linkli not; limit tablolarına tablo altı dipnot.
-- Mevcut satırlar DEFAULT sayesinde otomatik olarak 'fee' (düz ücret satırı)
-- olur — görünümleri değişmez. `value` text → textarea: Postgres'te ikisi de
-- varchar, kolon değişmedi. Enum'lar DO-blok içinde oluşturuluyor (varsa
-- atlanır); kolonlar ADD COLUMN IF NOT EXISTS — bu bölüm tek başına
-- tekrar çalıştırılabilir.
-- -----------------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE public.enum_fee_rows_row_type AS ENUM ('fee', 'heading', 'note');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
    CREATE TYPE public.enum__fee_rows_v_version_row_type AS ENUM ('fee', 'heading', 'note');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

ALTER TABLE public.fee_rows
    ADD COLUMN IF NOT EXISTS row_type public.enum_fee_rows_row_type DEFAULT 'fee'::public.enum_fee_rows_row_type,
    ADD COLUMN IF NOT EXISTS highlight_value boolean DEFAULT false,
    ADD COLUMN IF NOT EXISTS note jsonb;
ALTER TABLE public._fee_rows_v
    ADD COLUMN IF NOT EXISTS version_row_type public.enum__fee_rows_v_version_row_type DEFAULT 'fee'::public.enum__fee_rows_v_version_row_type,
    ADD COLUMN IF NOT EXISTS version_highlight_value boolean DEFAULT false,
    ADD COLUMN IF NOT EXISTS version_note jsonb;

ALTER TABLE public.limit_tables    ADD COLUMN IF NOT EXISTS footnote character varying;
ALTER TABLE public._limit_tables_v ADD COLUMN IF NOT EXISTS version_footnote character varying;

-- -----------------------------------------------------------------------------
-- 7. SSS cevabı: düz metin (textarea) → zengin metin (richText) (17.09.2026)
--
-- Canlıdaki SSS cevaplarında kalın ara başlık, liste ve tablo var; düz metin
-- alanı bunları ifade edemiyordu. Payload richText'i jsonb (Lexical JSON)
-- olarak saklıyor. Kolon tipi değişirken HER mevcut cevap kayıpsız
-- dönüştürülüyor: boş satırla ayrılmış bloklar ayrı paragraf, tek satır
-- sonları paragraf içinde satır sonu (linebreak) olur. NULL/boş cevap NULL
-- kalır. Yardımcı fonksiyon aynı transaction içinde oluşturulup silinir.
--
-- TEKRAR ÇALIŞTIRILAMAZ (kolon zaten jsonb ise ALTER ... USING hata verir ve
-- transaction geri döner — zararsız, "zaten uygulanmış" demektir).
-- Doğrulama: dönüşüm öncesi ve sonrası her satırın düz metni (satır sonları
-- dahil) karşılaştırıldı — 26 kayıt + 78 sürüm, fark yok.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pg_temp.faq_text_to_lexical(t text) RETURNS jsonb
LANGUAGE sql IMMUTABLE AS $fn$
    SELECT CASE WHEN t IS NULL OR btrim(t) = '' THEN NULL ELSE jsonb_build_object('root', jsonb_build_object(
        'type', 'root', 'format', '', 'indent', 0, 'version', 1, 'direction', 'ltr',
        'children', (
            SELECT jsonb_agg(jsonb_build_object(
                'type', 'paragraph', 'format', '', 'indent', 0, 'version', 1, 'direction', 'ltr',
                'textFormat', 0, 'textStyle', '',
                'children', (
                    SELECT jsonb_agg(node ORDER BY ord)
                    FROM (
                        SELECT (l.n * 2) AS ord, jsonb_build_object('type', 'text', 'text', l.line, 'mode', 'normal',
                               'style', '', 'detail', 0, 'format', 0, 'version', 1) AS node
                        FROM unnest(string_to_array(p.para, E'\n')) WITH ORDINALITY AS l(line, n)
                        WHERE l.line <> ''
                        UNION ALL
                        SELECT (l.n * 2 + 1), jsonb_build_object('type', 'linebreak', 'version', 1)
                        FROM unnest(string_to_array(p.para, E'\n')) WITH ORDINALITY AS l(line, n)
                        WHERE l.n < array_length(string_to_array(p.para, E'\n'), 1)
                    ) nodes
                )
            ) ORDER BY p.pn)
            FROM unnest(regexp_split_to_array(btrim(replace(t, E'\r', ''), E'\n'), E'\n[ \t]*\n+')) WITH ORDINALITY AS p(para, pn)
            WHERE btrim(p.para) <> ''
        )
    )) END
$fn$;

ALTER TABLE public.faq_items
    ALTER COLUMN answer TYPE jsonb USING pg_temp.faq_text_to_lexical(answer);
ALTER TABLE public._faq_items_v
    ALTER COLUMN version_answer TYPE jsonb USING pg_temp.faq_text_to_lexical(version_answer);

DROP FUNCTION pg_temp.faq_text_to_lexical(text);

COMMIT;
