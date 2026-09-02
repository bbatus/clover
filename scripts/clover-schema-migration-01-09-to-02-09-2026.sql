-- =============================================================================
-- Clover (Payload CMS) — şema göç scripti: 01.09.2026 → 02.09.2026
--
-- KAYNAK: scripts/clover-test-db-schema.sql'in kapsadığı taban şemadan
-- (commit 04eae56, 01.09.2026) bugüne kadar `cms/src/collections/Pages.ts`
-- ve `cms/src/collections/FaqItems.ts`'te yapılan alan değişikliklerinin
-- ürettiği fark. Yerel geliştirme ortamında (Payload'ın kendi push-tabanlı
-- şema senkronu ile) uygulanıp ardından `pg_dump --schema-only` ile
-- doğrulanan gerçek tablo/kolon/kısıt adları kullanılmıştır — elle tahmin
-- edilmemiştir.
--
-- NEDEN GEREKLİ: Payload'ın push-tabanlı şema senkronu `NODE_ENV=production`
-- olduğunda adapter tarafından kesin olarak devre dışı bırakılıyor
-- (@payloadcms/db-postgres/dist/connect.js:110), yani gerçek/uzak Postgres'e
-- (Vodafone içi, external) bağlanan hiçbir Payload ortamı (yerel Docker dahil,
-- OCP dahil) bu kolonları/tabloları kendi başına oluşturamaz. Kod bu alanları
-- zaten kullanıyor — bu script çalıştırılmadan deploy edilirse ilgili
-- sayfa/blok kayıtları "column does not exist" hatasıyla 500 döner.
--
-- KAPSAM (bu göçte DEĞİŞEN, önceki script'in kapsamadığı her şey):
--   1. pages_blocks_step_phones_steps (+ _pages_v_ sürüm tablosu):
--      cta_label, cta_page_id, background_image_id kolonları.
--   2. pages_blocks_feature_highlights (+ _pages_v_): video_id kolonu.
--   3. pages_blocks_lead_form_cta (+ _pages_v_): background_image_id, icon_id,
--      text, cta_label, cta_url kolonları.
--   4. pages_blocks_videos_with_tabs_marker_tabs[_items] (+ _pages_v_ olanlar):
--      YENİ tablolar — blok artık `fields: []` değil, editöre sekme+kart
--      girişi sağlıyor.
--   5. pages_rels / _pages_v_rels: YENİ tablolar — campaignGrid bloğuna
--      eklenen `campaigns` (hasMany ilişki) alanı için Payload'ın paylaşımlı
--      polymorphic ilişki tablosu. Pages'in ilk hasMany ilişki alanı olduğu
--      için bu tablo hiç yoktu.
--   6. faq_items / _faq_items_v: show_on_homepage, homepage_order (ve sürüm
--      tablosunda version_ önekli karşılıkları) kolonları KALDIRILDI — CMS'te
--      "Anasayfada Göster" alanı silindi (bkz. tasks.md #43d). Bu adım DATA
--      LOSS uyarısı verecektir — o iki kolonda gerçek veri varsa (26 satırda
--      vardı, yerelde), bu beklenen ve kasıtlı bir kayıp: alan zaten hiçbir
--      şeyi etkilemiyordu (bkz. FaqItems.ts'teki eski alan açıklaması).
--
--   `pages_blocks_hero.heading`'in `required: true` → opsiyonel olması İÇİN
--   BİR ŞEY YAPMANIZA GEREK YOK — Payload zorunlu alanları DB'de NOT NULL
--   olarak uygulamıyor (doğrulama sadece uygulama katmanında), kolon zaten
--   nullable'dı. Aşağıdaki listede bu değişiklik yok, unutulmadı.
--
-- NASIL UYGULANIR (DBeaver): hedef veritabanına bağlan, SQL Editor'de bu
-- dosyayı aç, "Execute script" (Alt+X) ile TAMAMINI çalıştır. Tek bir
-- transaction içinde (BEGIN/COMMIT) — bir satır bile hata verirse HİÇBİR ŞEY
-- uygulanmaz, DB olduğu gibi kalır.
--
-- BEKLENEN BAŞLANGIÇ DURUMU: hedef veritabanı `scripts/clover-test-db-
-- schema.sql` (veya onunla aynı şemaya sahip bir OCP/production DB) ile
-- oluşturulmuş olmalı. Bu script idempotent DEĞİL — zaten uygulanmış bir
-- veritabanında tekrar çalıştırırsanız "column/table already exists"
-- hatası alırsınız (kolon eklemeleri IF NOT EXISTS ile korunuyor, ama yeni
-- tablo/kısıt/index'ler korunmuyor — aynı önceki script'teki gibi).
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------
-- 1. pages_blocks_step_phones_steps — stepPhones'a CTA + arkaplan görseli
-- -----------------------------------------------------------------------

ALTER TABLE public.pages_blocks_step_phones_steps
    ADD COLUMN IF NOT EXISTS cta_label character varying DEFAULT 'Keşfet'::character varying,
    ADD COLUMN IF NOT EXISTS cta_page_id integer,
    ADD COLUMN IF NOT EXISTS background_image_id integer;

ALTER TABLE ONLY public.pages_blocks_step_phones_steps
    ADD CONSTRAINT pages_blocks_step_phones_steps_cta_page_id_pages_id_fk
        FOREIGN KEY (cta_page_id) REFERENCES public.pages(id) ON DELETE SET NULL,
    ADD CONSTRAINT pages_blocks_step_phones_steps_background_image_id_media_id_fk
        FOREIGN KEY (background_image_id) REFERENCES public.media(id) ON DELETE SET NULL;

CREATE INDEX pages_blocks_step_phones_steps_cta_page_idx ON public.pages_blocks_step_phones_steps USING btree (cta_page_id);
CREATE INDEX pages_blocks_step_phones_steps_background_image_idx ON public.pages_blocks_step_phones_steps USING btree (background_image_id);

ALTER TABLE public._pages_v_blocks_step_phones_steps
    ADD COLUMN IF NOT EXISTS cta_label character varying DEFAULT 'Keşfet'::character varying,
    ADD COLUMN IF NOT EXISTS cta_page_id integer,
    ADD COLUMN IF NOT EXISTS background_image_id integer;

ALTER TABLE ONLY public._pages_v_blocks_step_phones_steps
    ADD CONSTRAINT _pages_v_blocks_step_phones_steps_cta_page_id_pages_id_fk
        FOREIGN KEY (cta_page_id) REFERENCES public.pages(id) ON DELETE SET NULL,
    ADD CONSTRAINT "_pages_v_blocks_step_phones_steps_background_image_id_media_id_"
        FOREIGN KEY (background_image_id) REFERENCES public.media(id) ON DELETE SET NULL;

CREATE INDEX _pages_v_blocks_step_phones_steps_cta_page_idx ON public._pages_v_blocks_step_phones_steps USING btree (cta_page_id);
CREATE INDEX _pages_v_blocks_step_phones_steps_background_image_idx ON public._pages_v_blocks_step_phones_steps USING btree (background_image_id);

-- -----------------------------------------------------------------------
-- 2. pages_blocks_feature_highlights — hardcoded video yerine gerçek alan
-- -----------------------------------------------------------------------

ALTER TABLE public.pages_blocks_feature_highlights
    ADD COLUMN IF NOT EXISTS video_id integer;

ALTER TABLE ONLY public.pages_blocks_feature_highlights
    ADD CONSTRAINT pages_blocks_feature_highlights_video_id_media_id_fk
        FOREIGN KEY (video_id) REFERENCES public.media(id) ON DELETE SET NULL;

CREATE INDEX pages_blocks_feature_highlights_video_idx ON public.pages_blocks_feature_highlights USING btree (video_id);

ALTER TABLE public._pages_v_blocks_feature_highlights
    ADD COLUMN IF NOT EXISTS video_id integer;

ALTER TABLE ONLY public._pages_v_blocks_feature_highlights
    ADD CONSTRAINT _pages_v_blocks_feature_highlights_video_id_media_id_fk
        FOREIGN KEY (video_id) REFERENCES public.media(id) ON DELETE SET NULL;

CREATE INDEX _pages_v_blocks_feature_highlights_video_idx ON public._pages_v_blocks_feature_highlights USING btree (video_id);

-- -----------------------------------------------------------------------
-- 3. pages_blocks_lead_form_cta — artık gerçekten düzenlenebilir
-- -----------------------------------------------------------------------

ALTER TABLE public.pages_blocks_lead_form_cta
    ADD COLUMN IF NOT EXISTS background_image_id integer,
    ADD COLUMN IF NOT EXISTS icon_id integer,
    ADD COLUMN IF NOT EXISTS text character varying,
    ADD COLUMN IF NOT EXISTS cta_label character varying,
    ADD COLUMN IF NOT EXISTS cta_url character varying;

ALTER TABLE ONLY public.pages_blocks_lead_form_cta
    ADD CONSTRAINT pages_blocks_lead_form_cta_background_image_id_media_id_fk
        FOREIGN KEY (background_image_id) REFERENCES public.media(id) ON DELETE SET NULL,
    ADD CONSTRAINT pages_blocks_lead_form_cta_icon_id_media_id_fk
        FOREIGN KEY (icon_id) REFERENCES public.media(id) ON DELETE SET NULL;

CREATE INDEX pages_blocks_lead_form_cta_background_image_idx ON public.pages_blocks_lead_form_cta USING btree (background_image_id);
CREATE INDEX pages_blocks_lead_form_cta_icon_idx ON public.pages_blocks_lead_form_cta USING btree (icon_id);

ALTER TABLE public._pages_v_blocks_lead_form_cta
    ADD COLUMN IF NOT EXISTS background_image_id integer,
    ADD COLUMN IF NOT EXISTS icon_id integer,
    ADD COLUMN IF NOT EXISTS text character varying,
    ADD COLUMN IF NOT EXISTS cta_label character varying,
    ADD COLUMN IF NOT EXISTS cta_url character varying;

ALTER TABLE ONLY public._pages_v_blocks_lead_form_cta
    ADD CONSTRAINT _pages_v_blocks_lead_form_cta_background_image_id_media_id_fk
        FOREIGN KEY (background_image_id) REFERENCES public.media(id) ON DELETE SET NULL,
    ADD CONSTRAINT _pages_v_blocks_lead_form_cta_icon_id_media_id_fk
        FOREIGN KEY (icon_id) REFERENCES public.media(id) ON DELETE SET NULL;

CREATE INDEX _pages_v_blocks_lead_form_cta_background_image_idx ON public._pages_v_blocks_lead_form_cta USING btree (background_image_id);
CREATE INDEX _pages_v_blocks_lead_form_cta_icon_idx ON public._pages_v_blocks_lead_form_cta USING btree (icon_id);

-- -----------------------------------------------------------------------
-- 4. pages_blocks_videos_with_tabs_marker_tabs[_items] — YENİ tablolar
--    (sekmeli video bloğu artık editöre sekme + kart girişi sağlıyor)
-- -----------------------------------------------------------------------

CREATE TABLE public.pages_blocks_videos_with_tabs_marker_tabs (
    _order integer NOT NULL,
    _parent_id character varying NOT NULL,
    id character varying NOT NULL,
    label character varying
);

CREATE TABLE public.pages_blocks_videos_with_tabs_marker_tabs_items (
    _order integer NOT NULL,
    _parent_id character varying NOT NULL,
    id character varying NOT NULL,
    label character varying,
    thumbnail_id integer
);

ALTER TABLE ONLY public.pages_blocks_videos_with_tabs_marker_tabs
    ADD CONSTRAINT pages_blocks_videos_with_tabs_marker_tabs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.pages_blocks_videos_with_tabs_marker_tabs_items
    ADD CONSTRAINT pages_blocks_videos_with_tabs_marker_tabs_items_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.pages_blocks_videos_with_tabs_marker_tabs
    ADD CONSTRAINT pages_blocks_videos_with_tabs_marker_tabs_parent_id_fk
        FOREIGN KEY (_parent_id) REFERENCES public.pages_blocks_videos_with_tabs_marker(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pages_blocks_videos_with_tabs_marker_tabs_items
    ADD CONSTRAINT pages_blocks_videos_with_tabs_marker_tabs_items_parent_id_fk
        FOREIGN KEY (_parent_id) REFERENCES public.pages_blocks_videos_with_tabs_marker_tabs(id) ON DELETE CASCADE,
    ADD CONSTRAINT pages_blocks_videos_with_tabs_marker_tabs_items_thumbnail_id_me
        FOREIGN KEY (thumbnail_id) REFERENCES public.media(id) ON DELETE SET NULL;

CREATE INDEX pages_blocks_videos_with_tabs_marker_tabs_order_idx ON public.pages_blocks_videos_with_tabs_marker_tabs USING btree (_order);
CREATE INDEX pages_blocks_videos_with_tabs_marker_tabs_parent_id_idx ON public.pages_blocks_videos_with_tabs_marker_tabs USING btree (_parent_id);
CREATE INDEX pages_blocks_videos_with_tabs_marker_tabs_items_order_idx ON public.pages_blocks_videos_with_tabs_marker_tabs_items USING btree (_order);
CREATE INDEX pages_blocks_videos_with_tabs_marker_tabs_items_parent_id_idx ON public.pages_blocks_videos_with_tabs_marker_tabs_items USING btree (_parent_id);
CREATE INDEX pages_blocks_videos_with_tabs_marker_tabs_items_thumbnai_idx ON public.pages_blocks_videos_with_tabs_marker_tabs_items USING btree (thumbnail_id);

-- Aynı yapının _pages_v_ (taslak/sürüm geçmişi) karşılığı — id burada integer
-- + sequence, çünkü sürüm tabloları character varying değil integer PK
-- kullanıyor (Payload'ın kendi konvansiyonu, canlı tablo ile aynı değil).

CREATE TABLE public._pages_v_blocks_videos_with_tabs_marker_tabs (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    id integer NOT NULL,
    label character varying,
    _uuid character varying
);

CREATE TABLE public._pages_v_blocks_videos_with_tabs_marker_tabs_items (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    id integer NOT NULL,
    label character varying,
    thumbnail_id integer,
    _uuid character varying
);

CREATE SEQUENCE public._pages_v_blocks_videos_with_tabs_marker_tabs_id_seq
    AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER SEQUENCE public._pages_v_blocks_videos_with_tabs_marker_tabs_id_seq
    OWNED BY public._pages_v_blocks_videos_with_tabs_marker_tabs.id;
ALTER TABLE ONLY public._pages_v_blocks_videos_with_tabs_marker_tabs
    ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_videos_with_tabs_marker_tabs_id_seq'::regclass);

CREATE SEQUENCE public._pages_v_blocks_videos_with_tabs_marker_tabs_items_id_seq
    AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER SEQUENCE public._pages_v_blocks_videos_with_tabs_marker_tabs_items_id_seq
    OWNED BY public._pages_v_blocks_videos_with_tabs_marker_tabs_items.id;
ALTER TABLE ONLY public._pages_v_blocks_videos_with_tabs_marker_tabs_items
    ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_videos_with_tabs_marker_tabs_items_id_seq'::regclass);

ALTER TABLE ONLY public._pages_v_blocks_videos_with_tabs_marker_tabs
    ADD CONSTRAINT _pages_v_blocks_videos_with_tabs_marker_tabs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public._pages_v_blocks_videos_with_tabs_marker_tabs_items
    ADD CONSTRAINT _pages_v_blocks_videos_with_tabs_marker_tabs_items_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public._pages_v_blocks_videos_with_tabs_marker_tabs
    ADD CONSTRAINT _pages_v_blocks_videos_with_tabs_marker_tabs_parent_id_fk
        FOREIGN KEY (_parent_id) REFERENCES public._pages_v_blocks_videos_with_tabs_marker(id) ON DELETE CASCADE;
ALTER TABLE ONLY public._pages_v_blocks_videos_with_tabs_marker_tabs_items
    ADD CONSTRAINT _pages_v_blocks_videos_with_tabs_marker_tabs_items_parent_id_fk
        FOREIGN KEY (_parent_id) REFERENCES public._pages_v_blocks_videos_with_tabs_marker_tabs(id) ON DELETE CASCADE,
    ADD CONSTRAINT _pages_v_blocks_videos_with_tabs_marker_tabs_items_thumbnail_id
        FOREIGN KEY (thumbnail_id) REFERENCES public.media(id) ON DELETE SET NULL;

CREATE INDEX _pages_v_blocks_videos_with_tabs_marker_tabs_order_idx ON public._pages_v_blocks_videos_with_tabs_marker_tabs USING btree (_order);
CREATE INDEX _pages_v_blocks_videos_with_tabs_marker_tabs_parent_id_idx ON public._pages_v_blocks_videos_with_tabs_marker_tabs USING btree (_parent_id);
CREATE INDEX _pages_v_blocks_videos_with_tabs_marker_tabs_items_order_idx ON public._pages_v_blocks_videos_with_tabs_marker_tabs_items USING btree (_order);
CREATE INDEX _pages_v_blocks_videos_with_tabs_marker_tabs_items_parent_id_id ON public._pages_v_blocks_videos_with_tabs_marker_tabs_items USING btree (_parent_id);
CREATE INDEX _pages_v_blocks_videos_with_tabs_marker_tabs_items_thumb_idx ON public._pages_v_blocks_videos_with_tabs_marker_tabs_items USING btree (thumbnail_id);

-- -----------------------------------------------------------------------
-- 5. pages_rels / _pages_v_rels — YENİ tablolar (campaignGrid'in
--    `campaigns` hasMany ilişki alanı için Payload'ın paylaşımlı
--    polymorphic ilişki tablosu — Pages'in ilk hasMany alanı)
-- -----------------------------------------------------------------------

CREATE TABLE public.pages_rels (
    id integer NOT NULL,
    "order" integer,
    parent_id integer NOT NULL,
    path character varying NOT NULL,
    campaigns_id integer
);

CREATE SEQUENCE public.pages_rels_id_seq
    AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER SEQUENCE public.pages_rels_id_seq OWNED BY public.pages_rels.id;
ALTER TABLE ONLY public.pages_rels ALTER COLUMN id SET DEFAULT nextval('public.pages_rels_id_seq'::regclass);

ALTER TABLE ONLY public.pages_rels
    ADD CONSTRAINT pages_rels_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.pages_rels
    ADD CONSTRAINT pages_rels_campaigns_fk FOREIGN KEY (campaigns_id) REFERENCES public.campaigns(id) ON DELETE CASCADE,
    ADD CONSTRAINT pages_rels_parent_fk FOREIGN KEY (parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;

CREATE INDEX pages_rels_campaigns_id_idx ON public.pages_rels USING btree (campaigns_id);
CREATE INDEX pages_rels_order_idx ON public.pages_rels USING btree ("order");
CREATE INDEX pages_rels_parent_idx ON public.pages_rels USING btree (parent_id);
CREATE INDEX pages_rels_path_idx ON public.pages_rels USING btree (path);

CREATE TABLE public._pages_v_rels (
    id integer NOT NULL,
    "order" integer,
    parent_id integer NOT NULL,
    path character varying NOT NULL,
    campaigns_id integer
);

CREATE SEQUENCE public._pages_v_rels_id_seq
    AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER SEQUENCE public._pages_v_rels_id_seq OWNED BY public._pages_v_rels.id;
ALTER TABLE ONLY public._pages_v_rels ALTER COLUMN id SET DEFAULT nextval('public._pages_v_rels_id_seq'::regclass);

ALTER TABLE ONLY public._pages_v_rels
    ADD CONSTRAINT _pages_v_rels_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public._pages_v_rels
    ADD CONSTRAINT _pages_v_rels_campaigns_fk FOREIGN KEY (campaigns_id) REFERENCES public.campaigns(id) ON DELETE CASCADE,
    ADD CONSTRAINT _pages_v_rels_parent_fk FOREIGN KEY (parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;

CREATE INDEX _pages_v_rels_campaigns_id_idx ON public._pages_v_rels USING btree (campaigns_id);
CREATE INDEX _pages_v_rels_order_idx ON public._pages_v_rels USING btree ("order");
CREATE INDEX _pages_v_rels_parent_idx ON public._pages_v_rels USING btree (parent_id);
CREATE INDEX _pages_v_rels_path_idx ON public._pages_v_rels USING btree (path);

-- -----------------------------------------------------------------------
-- 6. faq_items / _faq_items_v — "Anasayfada Göster" alanı kaldırıldı
--
-- DATA LOSS UYARISI: show_on_homepage/homepage_order kolonlarında veri
-- varsa (yerelde 26 satırda vardı) bu DROP onları kalıcı olarak siler.
-- Bu KASITLI — alan zaten hiçbir şeyi etkilemiyordu, bkz. tasks.md #43d.
-- Silmeden önce isterseniz `SELECT id, show_on_homepage, homepage_order
-- FROM faq_items WHERE show_on_homepage IS TRUE;` ile hangi satırların
-- etkilendiğini görebilirsiniz — geri dönüşü olmayan bir DROP'tan önce
-- production'da her zaman iyi bir alışkanlıktır.
-- -----------------------------------------------------------------------

ALTER TABLE public.faq_items
    DROP COLUMN IF EXISTS show_on_homepage,
    DROP COLUMN IF EXISTS homepage_order;

ALTER TABLE public._faq_items_v
    DROP COLUMN IF EXISTS version_show_on_homepage,
    DROP COLUMN IF EXISTS version_homepage_order;

COMMIT;
