-- =============================================================================
-- Clover (Payload CMS) — şema göç scripti: 17.09.2026 → 18.09.2026
--
-- ÖNCEKİ HALKA: scripts/clover-schema-migration-02-09-to-17-09-2026.sql
-- (canlı DB'de 17.09.2026'da çalıştırıldı). Bu script onun bıraktığı
-- durumdan devam eder — o dosya artık DEĞİŞTİRİLMEZ.
--
-- KAPSAM:
--   11. SEO Dosyaları global'i → YENİ tablolar seo_files / _seo_files_v +
--       2 enum; robots.txt ve llms.txt'nin başlangıç içeriği (VERİ, canlı
--       vodafonepay.com.tr'deki dosyalarla aynı; robots.txt'ye canlıdaki gibi
--       `Disallow: /*.pdf` dahil).
--   12. Kampanyalarda zamanlanmış yayın (18.09.2026) → campaigns ve
--       _campaigns_v'ye 5'er kolon (yayın zamanı ve saat dilimi, planı
--       onaylayan, onay zamanı ve saat dilimi) + 4 YENİ enum (saat dilimi) +
--       review_status enum'larına
--       'scheduled' değeri + 2 index + 2 FK (users). Veri değişikliği yok.
--       Not: ALTER TYPE ... ADD VALUE PostgreSQL 12+ gerektirir (transaction
--       içinde çalışır; yeni değer aynı transaction'da kullanılmıyor).
--
-- NASIL DOĞRULANDI: clover-test-db-schema.sql → 01-09-to-02-09 →
-- 02-09-to-17-09 → bu script boş bir scratch DB'ye sırayla yüklendi; tüm
-- şemanın `pg_dump --schema-only` çıktısı, Payload'ın push'uyla güncellenmiş
-- dev DB'ninkiyle birebir aynı.
--
-- NASIL UYGULANIR (DBeaver): hedef DB'ye bağlan, File → Open File ile bu
-- dosyayı aç, Alt+X ("Execute script") ile TAMAMINI çalıştır. Tek transaction.
-- Metinler tek satırlık E'...' dizeleri olarak yazıldı; dosyada hiçbir komutun
-- ortasında boş satır yok (DBeaver "boş satır = komut sonu" ayarından etkilenmez).
--
-- TEKRAR ÇALIŞTIRILABİLİR: tablo/enum yoksa oluşturur, kayıt yoksa ekler.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------
-- 11a. Enum'lar
-- -----------------------------------------------------------------------
DO $$
BEGIN
    IF to_regtype('public.enum_seo_files_status') IS NULL THEN
        CREATE TYPE public.enum_seo_files_status AS ENUM ('draft', 'published');
    END IF;
    IF to_regtype('public.enum__seo_files_v_version_status') IS NULL THEN
        CREATE TYPE public.enum__seo_files_v_version_status AS ENUM ('draft', 'published');
    END IF;
END $$;

-- -----------------------------------------------------------------------
-- 11b. Tablolar (Payload'ın kendi ürettiği şemayla birebir)
-- -----------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('public.seo_files') IS NULL THEN
        CREATE TABLE public._seo_files_v (
            id integer NOT NULL,
            version_robots_txt character varying,
            version_llms_txt character varying,
            version__status public.enum__seo_files_v_version_status DEFAULT 'draft'::public.enum__seo_files_v_version_status,
            version_updated_at timestamp(3) with time zone,
            version_created_at timestamp(3) with time zone,
            created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
            updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
            latest boolean
        );
        CREATE SEQUENCE public._seo_files_v_id_seq AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
        ALTER SEQUENCE public._seo_files_v_id_seq OWNED BY public._seo_files_v.id;
        CREATE TABLE public.seo_files (
            id integer NOT NULL,
            robots_txt character varying,
            llms_txt character varying,
            _status public.enum_seo_files_status DEFAULT 'draft'::public.enum_seo_files_status,
            updated_at timestamp(3) with time zone,
            created_at timestamp(3) with time zone
        );
        CREATE SEQUENCE public.seo_files_id_seq AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
        ALTER SEQUENCE public.seo_files_id_seq OWNED BY public.seo_files.id;
        ALTER TABLE ONLY public._seo_files_v ALTER COLUMN id SET DEFAULT nextval('public._seo_files_v_id_seq'::regclass);
        ALTER TABLE ONLY public.seo_files ALTER COLUMN id SET DEFAULT nextval('public.seo_files_id_seq'::regclass);
        ALTER TABLE ONLY public._seo_files_v ADD CONSTRAINT _seo_files_v_pkey PRIMARY KEY (id);
        ALTER TABLE ONLY public.seo_files ADD CONSTRAINT seo_files_pkey PRIMARY KEY (id);
        CREATE INDEX _seo_files_v_created_at_idx ON public._seo_files_v USING btree (created_at);
        CREATE INDEX _seo_files_v_latest_idx ON public._seo_files_v USING btree (latest);
        CREATE INDEX _seo_files_v_updated_at_idx ON public._seo_files_v USING btree (updated_at);
        CREATE INDEX _seo_files_v_version_version__status_idx ON public._seo_files_v USING btree (version__status);
        CREATE INDEX seo_files__status_idx ON public.seo_files USING btree (_status);
    END IF;
END $$;

-- -----------------------------------------------------------------------
-- 11c. VERİ: yayınlanmış ilk kayıt (canlıdaki robots.txt + llms.txt).
-- Kayıt zaten varsa (panelden kaydedilmişse) dokunulmaz.
-- -----------------------------------------------------------------------
INSERT INTO public.seo_files (robots_txt, llms_txt, _status, updated_at, created_at)
SELECT E'User-agent: *\nDisallow: /api/\nDisallow: /*.pdf\n\n# --- Yapay zeka botlari ---\n# AI arama ve asistan botlari (OAI-SearchBot, ChatGPT-User, PerplexityBot,\n# Claude-User, Claude-SearchBot) yukaridaki genel kurala tabidir; siteye erisebilir.\n# Asagidaki botlar yalnizca model egitimi icin veri toplar ve engellenmistir.\n\nUser-agent: GPTBot\nDisallow: /\n\nUser-agent: CCBot\nDisallow: /\n\nUser-agent: Google-Extended\nDisallow: /\n\nUser-agent: Applebot-Extended\nDisallow: /\n\nUser-agent: meta-externalagent\nDisallow: /\n\nUser-agent: ClaudeBot\nDisallow: /\n', E'# Vodafone Pay\n\n> Vodafone Pay, Vodafone Elektronik Para ve Ödeme Hizmetleri A.Ş. (VEPAŞ) tarafından sunulan yeni nesil mobil cüzdan uygulamasıdır. Kullanıcılar Vodafone Pay ile bakiye yükleyebilir, QR kod ile ödeme yapabilir, ön ödemeli Vodafone Pay Kart ile alışveriş yapabilir, harcamalarını Vodafone faturasına yansıtabilir ve nakit iade (cashback) kampanyalarından yararlanabilir.\n\nVEPAŞ, Vodafone Türkiye iştiraki olarak 2015 yılında kurulmuş, 20.07.2017 tarihinden itibaren BDDK lisansı ile faaliyet gösteren bir elektronik para kuruluşudur. Web sitesi Türkçe\'dir ve Türkiye\'deki kullanıcılara hizmet verir.\n\n## Ürünler ve Hizmetler\n\n- [Vodafone Pay Uygulaması](https://www.vodafonepay.com.tr/vodafone-pay-uygulama): Mobil cüzdan uygulamasının özellikleri, indirme bağlantıları ve kullanım detayları\n- [Vodafone Pay Kart](https://www.vodafonepay.com.tr/vodafone-pay-kart): Ön ödemeli fiziksel ve sanal kart; başvuru, kullanım ve avantajlar\n- [QR ile Faturana Yansıt](https://www.vodafonepay.com.tr/qr-ile-faturana-yansit): QR kod ile yapılan ödemeleri Vodafone faturasına yansıtma hizmeti\n- [Faturana Yansıt](https://www.vodafonepay.com.tr/faturana-yansit): Harcamaları Vodafone faturasına yansıtarak ödeme yöntemi\n- [Anında Bakiye](https://www.vodafonepay.com.tr/aninda-bakiye): Cüzdana anında bakiye yükleme hizmeti\n- [Ücretler ve Limitler](https://www.vodafonepay.com.tr/ucretler-ve-limitler): Tüm hizmetlere ait güncel ücret ve işlem limitleri\n\n## Destek ve Bilgi\n\n- [Sıkça Sorulan Sorular](https://www.vodafonepay.com.tr/sikca-sorulan-sorular): Ürün ve hizmetlerle ilgili sık sorulan sorular ve cevapları\n- [Faydalı Bilgiler](https://www.vodafonepay.com.tr/faydali-bilgiler): Kullanım rehberleri ve bilgilendirme içerikleri\n- [İletişim](https://www.vodafonepay.com.tr/iletisim): Müşteri hizmetleri ve iletişim kanalları\n- [Temsilciliklerimiz](https://www.vodafonepay.com.tr/temsilciliklerimiz): Türkiye genelindeki Vodafone Pay temsilcilik noktaları\n\n## Kampanyalar\n\n- [Kampanyalar](https://www.vodafonepay.com.tr/kampanyalar): Nakit iade, indirim ve üyelik avantajı içeren güncel kampanyaların listesi; her kampanyanın detay sayfası bu liste üzerinden erişilebilir\n\n## Blog\n\n- [Blog](https://www.vodafonepay.com.tr/blog): Mobil ödeme, ön ödemeli kart, QR ile ödeme ve bakiye yükleme gibi konularda rehber içerikler; tüm yazılar bu liste üzerinden erişilebilir\n\n## Kurumsal\n\n- [Kurumsal Yönetim](https://www.vodafonepay.com.tr/kurumsal-yonetim): Şirket bilgileri, yönetim kurulu ve lisans bilgileri\n- [Duyurular](https://www.vodafonepay.com.tr/duyurular): Resmi şirket duyuruları\n- [Sözleşmeler ve Formlar](https://www.vodafonepay.com.tr/sozlesmeler-ve-formlar): Hizmet sözleşmeleri ve başvuru formları\n\n## Yasal\n\n- [Gizlilik ve Güvenlik Politikası](https://www.vodafonepay.com.tr/gizlilik-ve-guvenlik-politikasi): Kişisel verilerin korunması ve gizlilik esasları\n- [Bilgi Güvenliği](https://www.vodafonepay.com.tr/bilgi-guvenligi): Bilgi güvenliği politikası\n- [Web Sitesi Hüküm ve Şartları](https://www.vodafonepay.com.tr/web-sitesi-hukum-ve-sartlari): Site kullanım koşulları\n\n## Yapay Zekâ Sistemleri İçin Kullanım Politikası\n\n- Yapay zekâ sistemleri bu web sitesindeki halka açık sayfaları tarayabilir, okuyabilir, özetleyebilir ve kaynak göstererek alıntılayabilir.\n- İçerik, yapay zekâ modellerinin eğitimi veya ince ayarı (fine-tuning) amacıyla kullanılamaz; bu yönde kullanım VEPAŞ\'ın açık yazılı onayına tabidir.\n- İçerik, yetkilendirme olmaksızın veri kümesi oluşturma amacıyla depolanamaz veya çoğaltılamaz; ticari amaçlı kullanım yasaktır.\n- Marka hakkında bilgi verilirken bu dosyadaki ve bağlantılı sayfalardaki güncel bilgiler esas alınmalıdır.\n- robots.txt yönergelerine uyulmalıdır; tarama hızı sunucu performansını olumsuz etkilememelidir.\n\n# Versiyon: 1.1 | Son Güncelleme: 03.08.2026\n', 'published', now(), now()
WHERE NOT EXISTS (SELECT 1 FROM public.seo_files);
INSERT INTO public._seo_files_v (version_robots_txt, version_llms_txt, version__status, version_updated_at, version_created_at, latest)
SELECT s.robots_txt, s.llms_txt, 'published', now(), now(), true
FROM public.seo_files s
WHERE NOT EXISTS (SELECT 1 FROM public._seo_files_v);


-- -----------------------------------------------------------------------
-- 12. Kampanya zamanlanmış yayını (18.09.2026)
--
-- Maker "İleri Tarihte Yayınla" alanına tarih/saat seçip onaya gönderir;
-- Checker "Onayla ve Planla" der (review_status = 'scheduled'); CMS
-- içindeki zamanlayıcı o an gelince kampanyayı yayına alır. Zaman UTC
-- anı (timestamptz) olarak saklanır, panel İstanbul saatiyle gösterir.
-- -----------------------------------------------------------------------
ALTER TYPE public.enum_campaigns_review_status ADD VALUE IF NOT EXISTS 'scheduled';
ALTER TYPE public.enum__campaigns_v_version_review_status ADD VALUE IF NOT EXISTS 'scheduled';
DO $$
BEGIN
    IF to_regtype('public.enum_campaigns_scheduledpublishat_tz') IS NULL THEN
        CREATE TYPE public.enum_campaigns_scheduledpublishat_tz AS ENUM ('Europe/Istanbul');
    END IF;
    IF to_regtype('public.enum__campaigns_v_version_scheduledpublishat_tz') IS NULL THEN
        CREATE TYPE public.enum__campaigns_v_version_scheduledpublishat_tz AS ENUM ('Europe/Istanbul');
    END IF;
    IF to_regtype('public.enum_campaigns_scheduleapprovedat_tz') IS NULL THEN
        CREATE TYPE public.enum_campaigns_scheduleapprovedat_tz AS ENUM ('Europe/Istanbul');
    END IF;
    IF to_regtype('public.enum__campaigns_v_version_scheduleapprovedat_tz') IS NULL THEN
        CREATE TYPE public.enum__campaigns_v_version_scheduleapprovedat_tz AS ENUM ('Europe/Istanbul');
    END IF;
END $$;
ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS scheduled_publish_at timestamp(3) with time zone;
ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS scheduledpublishat_tz public.enum_campaigns_scheduledpublishat_tz DEFAULT 'Europe/Istanbul'::public.enum_campaigns_scheduledpublishat_tz;
ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS schedule_approved_by_id integer;
ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS schedule_approved_at timestamp(3) with time zone;
ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS scheduleapprovedat_tz public.enum_campaigns_scheduleapprovedat_tz DEFAULT 'Europe/Istanbul'::public.enum_campaigns_scheduleapprovedat_tz;
ALTER TABLE public._campaigns_v ADD COLUMN IF NOT EXISTS version_scheduled_publish_at timestamp(3) with time zone;
ALTER TABLE public._campaigns_v ADD COLUMN IF NOT EXISTS version_scheduledpublishat_tz public.enum__campaigns_v_version_scheduledpublishat_tz DEFAULT 'Europe/Istanbul'::public.enum__campaigns_v_version_scheduledpublishat_tz;
ALTER TABLE public._campaigns_v ADD COLUMN IF NOT EXISTS version_schedule_approved_by_id integer;
ALTER TABLE public._campaigns_v ADD COLUMN IF NOT EXISTS version_schedule_approved_at timestamp(3) with time zone;
ALTER TABLE public._campaigns_v ADD COLUMN IF NOT EXISTS version_scheduleapprovedat_tz public.enum__campaigns_v_version_scheduleapprovedat_tz DEFAULT 'Europe/Istanbul'::public.enum__campaigns_v_version_scheduleapprovedat_tz;
CREATE INDEX IF NOT EXISTS campaigns_schedule_approved_by_idx ON public.campaigns USING btree (schedule_approved_by_id);
CREATE INDEX IF NOT EXISTS _campaigns_v_version_version_schedule_approved_by_idx ON public._campaigns_v USING btree (version_schedule_approved_by_id);
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'campaigns_schedule_approved_by_id_users_id_fk') THEN
        ALTER TABLE ONLY public.campaigns
            ADD CONSTRAINT campaigns_schedule_approved_by_id_users_id_fk FOREIGN KEY (schedule_approved_by_id) REFERENCES public.users(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = '_campaigns_v_version_schedule_approved_by_id_users_id_fk') THEN
        ALTER TABLE ONLY public._campaigns_v
            ADD CONSTRAINT _campaigns_v_version_schedule_approved_by_id_users_id_fk FOREIGN KEY (version_schedule_approved_by_id) REFERENCES public.users(id) ON DELETE SET NULL;
    END IF;
END $$;

COMMIT;
