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
--   8. Kampanyalar (17.09) → campaigns.assignment_period / participation
--      (+ _campaigns_v); Kampanya Grid bloğuna `layout` (grid|carousel) +
--      anasayfadaki bloğun carousel'e alınması (VERİ)
--   9. Blog (17.09) → "Daha fazlasını keşfedin" için blog_posts_rels ve
--      _blog_posts_v_rels (YENİ tablolar)
--  10. Footer (17.09) → SSS'lerden footer kolonları DÜŞÜRÜLDÜ (VERİ KAYBI:
--      "Footer'da Göster" işaretleri), blog_posts'a footer kolonları, YENİ
--      footer_settings global tabloları + LinkedIn adresli ilk kayıt (VERİ)
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


-- -----------------------------------------------------------------------------
-- 8. Kampanyalar: detay sayfası bilgi kutuları + blok görünümü (17.09.2026)
--
-- a) Canlı kampanya detayındaki "Tanımlama Süresi" ve "Katılım" kutuları için
--    iki opsiyonel metin kolonu. Boş (NULL) kalırsa sitede kutu oluşmaz.
-- b) Kampanya Grid bloğuna görünüm seçimi: 'grid' (Kampanyalar sayfası kart
--    ızgarası) | 'carousel' (anasayfadaki gri zeminli kaydırmalı şerit).
--    Mevcut bloklar DEFAULT ile 'grid' olur — görünümleri değişmez.
-- c) VERİ: anasayfa olarak işaretli sayfadaki (pages.is_homepage, 3. bölüm)
--    kampanya bloğu canlıdaki gibi 'carousel' yapılır — yayındaki tablo ve
--    o sayfanın TÜM sürümleri (admin düzenleme ekranı sürüm tablosundan
--    okuyor, bkz. 1. bölüm notu).
--
-- a/b tekrar çalıştırılabilir (IF NOT EXISTS / duplicate_object atlanır);
-- c idempotent (zaten 'carousel' olanı yeniden yazar).
-- -----------------------------------------------------------------------------
ALTER TABLE public.campaigns
    ADD COLUMN IF NOT EXISTS assignment_period character varying,
    ADD COLUMN IF NOT EXISTS participation character varying;
ALTER TABLE public._campaigns_v
    ADD COLUMN IF NOT EXISTS version_assignment_period character varying,
    ADD COLUMN IF NOT EXISTS version_participation character varying;

DO $$ BEGIN
    CREATE TYPE public.enum_pages_blocks_campaign_grid_layout AS ENUM ('grid', 'carousel');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
    CREATE TYPE public.enum__pages_v_blocks_campaign_grid_layout AS ENUM ('grid', 'carousel');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

ALTER TABLE public.pages_blocks_campaign_grid
    ADD COLUMN IF NOT EXISTS layout public.enum_pages_blocks_campaign_grid_layout DEFAULT 'grid'::public.enum_pages_blocks_campaign_grid_layout;
ALTER TABLE public._pages_v_blocks_campaign_grid
    ADD COLUMN IF NOT EXISTS layout public.enum__pages_v_blocks_campaign_grid_layout DEFAULT 'grid'::public.enum__pages_v_blocks_campaign_grid_layout;

UPDATE public.pages_blocks_campaign_grid b
SET    layout = 'carousel'
FROM   public.pages p
WHERE  b._parent_id = p.id AND p.is_homepage IS TRUE;

UPDATE public._pages_v_blocks_campaign_grid vb
SET    layout = 'carousel'
FROM   public._pages_v v, public.pages p
WHERE  vb._parent_id = v.id AND v.parent_id = p.id AND p.is_homepage IS TRUE;


-- -----------------------------------------------------------------------------
-- 9. Blog: "Daha fazlasını keşfedin" yazı seçimi (17.09.2026)
--
-- BlogPosts'a opsiyonel `relatedPosts` (hasMany ilişki, en fazla 3) eklendi —
-- Payload hasMany ilişkileri `<tablo>_rels` tablosunda tutuyor. BlogPosts'un
-- başka hasMany ilişkisi olmadığı için bu tablolar YENİ. Boş kalırsa site
-- otomatik seçim yapıyor; mevcut hiçbir kayıt etkilenmez.
-- Tablolar CREATE TABLE IF NOT EXISTS; index/FK'lar yalnızca tablo bu
-- çalıştırmada oluşturulduysa eklenir (DO bloğu) — bölüm tek başına tekrar
-- çalıştırılabilir.
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('public.blog_posts_rels') IS NULL THEN
        CREATE TABLE public.blog_posts_rels (
            id integer NOT NULL,
            "order" integer,
            parent_id integer NOT NULL,
            path character varying NOT NULL,
            blog_posts_id integer
        );
        CREATE SEQUENCE public.blog_posts_rels_id_seq AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
        ALTER SEQUENCE public.blog_posts_rels_id_seq OWNED BY public.blog_posts_rels.id;
        ALTER TABLE ONLY public.blog_posts_rels ALTER COLUMN id SET DEFAULT nextval('public.blog_posts_rels_id_seq'::regclass);
        ALTER TABLE ONLY public.blog_posts_rels ADD CONSTRAINT blog_posts_rels_pkey PRIMARY KEY (id);
        CREATE INDEX blog_posts_rels_blog_posts_id_idx ON public.blog_posts_rels USING btree (blog_posts_id);
        CREATE INDEX blog_posts_rels_order_idx ON public.blog_posts_rels USING btree ("order");
        CREATE INDEX blog_posts_rels_parent_idx ON public.blog_posts_rels USING btree (parent_id);
        CREATE INDEX blog_posts_rels_path_idx ON public.blog_posts_rels USING btree (path);
        ALTER TABLE ONLY public.blog_posts_rels
            ADD CONSTRAINT blog_posts_rels_blog_posts_fk FOREIGN KEY (blog_posts_id) REFERENCES public.blog_posts(id) ON DELETE CASCADE;
        ALTER TABLE ONLY public.blog_posts_rels
            ADD CONSTRAINT blog_posts_rels_parent_fk FOREIGN KEY (parent_id) REFERENCES public.blog_posts(id) ON DELETE CASCADE;
    END IF;

    IF to_regclass('public._blog_posts_v_rels') IS NULL THEN
        CREATE TABLE public._blog_posts_v_rels (
            id integer NOT NULL,
            "order" integer,
            parent_id integer NOT NULL,
            path character varying NOT NULL,
            blog_posts_id integer
        );
        CREATE SEQUENCE public._blog_posts_v_rels_id_seq AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
        ALTER SEQUENCE public._blog_posts_v_rels_id_seq OWNED BY public._blog_posts_v_rels.id;
        ALTER TABLE ONLY public._blog_posts_v_rels ALTER COLUMN id SET DEFAULT nextval('public._blog_posts_v_rels_id_seq'::regclass);
        ALTER TABLE ONLY public._blog_posts_v_rels ADD CONSTRAINT _blog_posts_v_rels_pkey PRIMARY KEY (id);
        CREATE INDEX _blog_posts_v_rels_blog_posts_id_idx ON public._blog_posts_v_rels USING btree (blog_posts_id);
        CREATE INDEX _blog_posts_v_rels_order_idx ON public._blog_posts_v_rels USING btree ("order");
        CREATE INDEX _blog_posts_v_rels_parent_idx ON public._blog_posts_v_rels USING btree (parent_id);
        CREATE INDEX _blog_posts_v_rels_path_idx ON public._blog_posts_v_rels USING btree (path);
        ALTER TABLE ONLY public._blog_posts_v_rels
            ADD CONSTRAINT _blog_posts_v_rels_blog_posts_fk FOREIGN KEY (blog_posts_id) REFERENCES public.blog_posts(id) ON DELETE CASCADE;
        ALTER TABLE ONLY public._blog_posts_v_rels
            ADD CONSTRAINT _blog_posts_v_rels_parent_fk FOREIGN KEY (parent_id) REFERENCES public._blog_posts_v(id) ON DELETE CASCADE;
    END IF;
END $$;


-- -----------------------------------------------------------------------------
-- 10a. SSS'lerin footer kolonları kaldırıldı (17.09.2026, kullanıcı kararı)
--
-- Canlı vodafonepay.com.tr footer'ında "Sık Sorulanlar" sütunu yok; site
-- footer'ı canlıyla eşitlendi ve FaqItems'taki "Footer'da Göster" / "Footer
-- Sırası" alanları kaldırıldı. ⚠️ VERİ KAYBI (bilinçli): hangi SSS'nin
-- footer'da işaretli olduğu bilgisi silinir — sitede zaten hiçbir yerde
-- gösterilmeyecek. IF EXISTS: tekrar çalıştırılabilir.
-- -----------------------------------------------------------------------------
DROP INDEX IF EXISTS public.faq_items_footer_order_idx;
DROP INDEX IF EXISTS public._faq_items_v_version_version_footer_order_idx;
ALTER TABLE public.faq_items
    DROP COLUMN IF EXISTS show_in_footer,
    DROP COLUMN IF EXISTS footer_order;
ALTER TABLE public._faq_items_v
    DROP COLUMN IF EXISTS version_show_in_footer,
    DROP COLUMN IF EXISTS version_footer_order;


-- -----------------------------------------------------------------------------
-- 10b. Blog yazılarına "Footer'da Göster" (17.09.2026)
--
-- Canlı footer'ın orta sütunu blog yazılarıdır. Kampanyalardaki alanın
-- birebir aynısı: show_in_footer + footer_order (UNIQUE — eşzamanlı kayıtta
-- aynı sıraya düşmeyi engelleyen son savunma, bkz. Campaigns.footerOrder).
-- Mevcut yazılar DEFAULT false ile footer'da DEĞİL başlar.
-- -----------------------------------------------------------------------------
ALTER TABLE public.blog_posts
    ADD COLUMN IF NOT EXISTS show_in_footer boolean DEFAULT false,
    ADD COLUMN IF NOT EXISTS footer_order numeric;
ALTER TABLE public._blog_posts_v
    ADD COLUMN IF NOT EXISTS version_show_in_footer boolean DEFAULT false,
    ADD COLUMN IF NOT EXISTS version_footer_order numeric;
CREATE UNIQUE INDEX IF NOT EXISTS blog_posts_footer_order_idx ON public.blog_posts USING btree (footer_order);
CREATE INDEX IF NOT EXISTS _blog_posts_v_version_version_footer_order_idx ON public._blog_posts_v USING btree (version_footer_order);

-- -----------------------------------------------------------------------------
-- 10c. Footer Yönetimi global'i (17.09.2026) — YENİ tablolar
--
-- Arka plan görseli, QR görseli, LinkedIn adresi; taslak/yayın (maker→
-- checker) için sürüm tablosu. Link sütunları burada TUTULMAZ — Menü
-- Linkleri / Blog Yazıları / Kampanyalar kayıtlarının kendisinden okunur.
-- Tekrar çalıştırılabilir: tablo zaten varsa blok hiçbir şey yapmaz.
-- -----------------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE public.enum_footer_settings_status AS ENUM ('draft', 'published');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
    CREATE TYPE public.enum__footer_settings_v_version_status AS ENUM ('draft', 'published');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$
BEGIN
    IF to_regclass('public.footer_settings') IS NULL THEN
        CREATE TABLE public._footer_settings_v (
            id integer NOT NULL,
            version_background_image_id integer,
            version_qr_image_id integer,
            version_linkedin_url character varying,
            version__status public.enum__footer_settings_v_version_status DEFAULT 'draft'::public.enum__footer_settings_v_version_status,
            version_updated_at timestamp(3) with time zone,
            version_created_at timestamp(3) with time zone,
            created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
            updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
            latest boolean
        );
        CREATE SEQUENCE public._footer_settings_v_id_seq
            AS integer
            START WITH 1
            INCREMENT BY 1
            NO MINVALUE
            NO MAXVALUE
            CACHE 1;
        ALTER SEQUENCE public._footer_settings_v_id_seq OWNED BY public._footer_settings_v.id;
        CREATE TABLE public.footer_settings (
            id integer NOT NULL,
            background_image_id integer,
            qr_image_id integer,
            linkedin_url character varying,
            _status public.enum_footer_settings_status DEFAULT 'draft'::public.enum_footer_settings_status,
            updated_at timestamp(3) with time zone,
            created_at timestamp(3) with time zone
        );
        CREATE SEQUENCE public.footer_settings_id_seq
            AS integer
            START WITH 1
            INCREMENT BY 1
            NO MINVALUE
            NO MAXVALUE
            CACHE 1;
        ALTER SEQUENCE public.footer_settings_id_seq OWNED BY public.footer_settings.id;
        ALTER TABLE ONLY public._footer_settings_v ALTER COLUMN id SET DEFAULT nextval('public._footer_settings_v_id_seq'::regclass);
        ALTER TABLE ONLY public.footer_settings ALTER COLUMN id SET DEFAULT nextval('public.footer_settings_id_seq'::regclass);
        ALTER TABLE ONLY public._footer_settings_v
            ADD CONSTRAINT _footer_settings_v_pkey PRIMARY KEY (id);
        ALTER TABLE ONLY public.footer_settings
            ADD CONSTRAINT footer_settings_pkey PRIMARY KEY (id);
        CREATE INDEX _footer_settings_v_created_at_idx ON public._footer_settings_v USING btree (created_at);
        CREATE INDEX _footer_settings_v_latest_idx ON public._footer_settings_v USING btree (latest);
        CREATE INDEX _footer_settings_v_updated_at_idx ON public._footer_settings_v USING btree (updated_at);
        CREATE INDEX _footer_settings_v_version_version__status_idx ON public._footer_settings_v USING btree (version__status);
        CREATE INDEX _footer_settings_v_version_version_background_image_idx ON public._footer_settings_v USING btree (version_background_image_id);
        CREATE INDEX _footer_settings_v_version_version_qr_image_idx ON public._footer_settings_v USING btree (version_qr_image_id);
        CREATE INDEX footer_settings__status_idx ON public.footer_settings USING btree (_status);
        CREATE INDEX footer_settings_background_image_idx ON public.footer_settings USING btree (background_image_id);
        CREATE INDEX footer_settings_qr_image_idx ON public.footer_settings USING btree (qr_image_id);
        ALTER TABLE ONLY public._footer_settings_v
            ADD CONSTRAINT _footer_settings_v_version_background_image_id_media_id_fk FOREIGN KEY (version_background_image_id) REFERENCES public.media(id) ON DELETE SET NULL;
        ALTER TABLE ONLY public._footer_settings_v
            ADD CONSTRAINT _footer_settings_v_version_qr_image_id_media_id_fk FOREIGN KEY (version_qr_image_id) REFERENCES public.media(id) ON DELETE SET NULL;
        ALTER TABLE ONLY public.footer_settings
            ADD CONSTRAINT footer_settings_background_image_id_media_id_fk FOREIGN KEY (background_image_id) REFERENCES public.media(id) ON DELETE SET NULL;
        ALTER TABLE ONLY public.footer_settings
            ADD CONSTRAINT footer_settings_qr_image_id_media_id_fk FOREIGN KEY (qr_image_id) REFERENCES public.media(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 10d. VERİ: canlı sitedeki LinkedIn adresiyle yayınlanmış ilk kayıt. Görseller
-- boş bırakılır — site bu durumda canlının kendi arka planını ve QR kartını
-- kullanır. Kayıt zaten varsa (panelden kaydedilmişse) dokunulmaz.
INSERT INTO public.footer_settings (linkedin_url, _status, updated_at, created_at)
SELECT 'https://www.linkedin.com/company/vodafone-elektronik-para-ve-%C3%B6deme-hizmetleri-a-%C5%9F/', 'published', now(), now()
WHERE NOT EXISTS (SELECT 1 FROM public.footer_settings);
INSERT INTO public._footer_settings_v (version_linkedin_url, version__status, version_updated_at, version_created_at, latest)
SELECT f.linkedin_url, 'published', now(), now(), true
FROM public.footer_settings f
WHERE NOT EXISTS (SELECT 1 FROM public._footer_settings_v);

COMMIT;
