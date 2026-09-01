-- =============================================================================
-- Clover (Payload CMS) — TEST veritabanı şeması
--
-- KAYNAK: bu dosya elle yazılmadı. Payload/Drizzle'ın yerel geliştirme
-- ortamında KENDİ ürettiği, üzerinde 567 testin geçtiği çalışan şemadan
-- `pg_dump --schema-only` ile birebir çıkarıldı (01.09.2026).
--
-- NEDEN GEREKLİ: Payload'ın push-tabanlı şema senkronu `NODE_ENV=production`
-- olduğunda adapter tarafından kesin olarak devre dışı bırakılıyor
-- (@payloadcms/db-postgres/dist/connect.js:110) ve production standalone
-- imajında `drizzle-kit` paketi hiç bulunmuyor — yani OCP'deki pod tabloları
-- kendi başına oluşturamaz. Bu script o boşluğu tek seferlik dolduruyor.
--
-- İÇERİK: 64 enum tipi, 110 tablo, 193 foreign key, 589 index.
--
-- NASIL UYGULANIR (DBeaver): hedef veritabanına (vpaycms_test_new) bağlan,
-- SQL Editor'de bu dosyayı aç, "Execute script" (Alt+X) ile TAMAMINI çalıştır.
-- Tek tek statement çalıştırma (Ctrl+Enter) YAPMA — sıra önemli, foreign
-- key'ler kendinden önceki tabloları bekliyor.
--
-- BOŞ BİR VERİTABANI BEKLER. Var olan tabloların üzerine yazmaz, "already
-- exists" hatası verir.
-- =============================================================================

SET search_path = public;


--
-- Name: enum__announcements_v_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__announcements_v_version_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum__blog_posts_v_version_post_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__blog_posts_v_version_post_status AS ENUM (
    'active',
    'archived'
);


--
-- Name: enum__blog_posts_v_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__blog_posts_v_version_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum__campaigns_v_version_campaign_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__campaigns_v_version_campaign_status AS ENUM (
    'active',
    'expired'
);


--
-- Name: enum__campaigns_v_version_review_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__campaigns_v_version_review_status AS ENUM (
    'pending',
    'rejected'
);


--
-- Name: enum__campaigns_v_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__campaigns_v_version_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum__campaigns_v_version_unpublish_request; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__campaigns_v_version_unpublish_request AS ENUM (
    'none',
    'pending'
);


--
-- Name: enum__categories_v_version_scope; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__categories_v_version_scope AS ENUM (
    'campaign',
    'blog',
    'faq'
);


--
-- Name: enum__categories_v_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__categories_v_version_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum__cookie_rows_v_version_category; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__cookie_rows_v_version_category AS ENUM (
    'Zorunlu',
    'İşlevsel',
    'Performans (Analitik)',
    'Reklam/Pazarlama'
);


--
-- Name: enum__cookie_rows_v_version_party; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__cookie_rows_v_version_party AS ENUM (
    'Birinci taraf',
    'Üçüncü taraf'
);


--
-- Name: enum__cookie_rows_v_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__cookie_rows_v_version_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum__documents_v_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__documents_v_version_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum__faq_items_v_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__faq_items_v_version_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum__feature_cards_v_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__feature_cards_v_version_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum__fee_rows_v_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__fee_rows_v_version_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum__legal_pages_v_version_groups_documents_source; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__legal_pages_v_version_groups_documents_source AS ENUM (
    'pdf',
    'page'
);


--
-- Name: enum__legal_pages_v_version_slug; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__legal_pages_v_version_slug AS ENUM (
    'gizlilik-ve-guvenlik-politikasi',
    'cerez-politikasi',
    'bilgi-guvenligi',
    'sozlesmeler-ve-formlar',
    'web-sitesi-hukum-ve-sartlari'
);


--
-- Name: enum__legal_pages_v_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__legal_pages_v_version_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum__limit_tables_v_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__limit_tables_v_version_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum__nav_links_v_version_section; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__nav_links_v_version_section AS ENUM (
    'header-products',
    'header-main',
    'footer-kurumsal',
    'footer-yasal'
);


--
-- Name: enum__nav_links_v_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__nav_links_v_version_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum__page_meta_v_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__page_meta_v_version_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum__pages_v_blocks_image_with_text_image_side; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__pages_v_blocks_image_with_text_image_side AS ENUM (
    'left',
    'right'
);


--
-- Name: enum__pages_v_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__pages_v_version_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum__pages_v_version_visibility; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__pages_v_version_visibility AS ENUM (
    'public',
    'private'
);


--
-- Name: enum__product_heroes_v_version_page; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__product_heroes_v_version_page AS ENUM (
    'anasayfa',
    'vodafone-pay-uygulama',
    'vodafone-pay-kart',
    'qr-ile-faturana-yansit',
    'faturana-yansit',
    'aninda-bakiye'
);


--
-- Name: enum__product_heroes_v_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__product_heroes_v_version_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum__representatives_v_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__representatives_v_version_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum__step_cards_v_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum__step_cards_v_version_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum_announcements_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_announcements_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum_audit_logs_action; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_audit_logs_action AS ENUM (
    'login',
    'login_failed',
    'logout',
    'create',
    'update',
    'publish',
    'rejected',
    'delete',
    'unlock',
    'locked',
    'role_changed',
    'export',
    'denied'
);


--
-- Name: enum_blog_posts_post_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_blog_posts_post_status AS ENUM (
    'active',
    'archived'
);


--
-- Name: enum_blog_posts_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_blog_posts_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum_campaigns_campaign_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_campaigns_campaign_status AS ENUM (
    'active',
    'expired'
);


--
-- Name: enum_campaigns_review_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_campaigns_review_status AS ENUM (
    'pending',
    'rejected'
);


--
-- Name: enum_campaigns_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_campaigns_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum_campaigns_unpublish_request; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_campaigns_unpublish_request AS ENUM (
    'none',
    'pending'
);


--
-- Name: enum_categories_scope; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_categories_scope AS ENUM (
    'campaign',
    'blog',
    'faq'
);


--
-- Name: enum_categories_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_categories_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum_cookie_rows_category; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_cookie_rows_category AS ENUM (
    'Zorunlu',
    'İşlevsel',
    'Performans (Analitik)',
    'Reklam/Pazarlama'
);


--
-- Name: enum_cookie_rows_party; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_cookie_rows_party AS ENUM (
    'Birinci taraf',
    'Üçüncü taraf'
);


--
-- Name: enum_cookie_rows_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_cookie_rows_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum_documents_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_documents_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum_faq_items_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_faq_items_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum_feature_cards_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_feature_cards_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum_fee_rows_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_fee_rows_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum_legal_pages_groups_documents_source; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_legal_pages_groups_documents_source AS ENUM (
    'pdf',
    'page'
);


--
-- Name: enum_legal_pages_slug; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_legal_pages_slug AS ENUM (
    'gizlilik-ve-guvenlik-politikasi',
    'cerez-politikasi',
    'bilgi-guvenligi',
    'sozlesmeler-ve-formlar',
    'web-sitesi-hukum-ve-sartlari'
);


--
-- Name: enum_legal_pages_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_legal_pages_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum_limit_tables_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_limit_tables_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum_media_media_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_media_media_type AS ENUM (
    'image',
    'video'
);


--
-- Name: enum_nav_links_section; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_nav_links_section AS ENUM (
    'header-products',
    'header-main',
    'footer-kurumsal',
    'footer-yasal'
);


--
-- Name: enum_nav_links_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_nav_links_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum_page_meta_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_page_meta_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum_pages_blocks_image_with_text_image_side; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_pages_blocks_image_with_text_image_side AS ENUM (
    'left',
    'right'
);


--
-- Name: enum_pages_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_pages_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum_pages_visibility; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_pages_visibility AS ENUM (
    'public',
    'private'
);


--
-- Name: enum_product_heroes_page; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_product_heroes_page AS ENUM (
    'anasayfa',
    'vodafone-pay-uygulama',
    'vodafone-pay-kart',
    'qr-ile-faturana-yansit',
    'faturana-yansit',
    'aninda-bakiye'
);


--
-- Name: enum_product_heroes_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_product_heroes_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum_representatives_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_representatives_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum_step_cards_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_step_cards_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: enum_users_preferred_locale; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_users_preferred_locale AS ENUM (
    'tr',
    'en'
);


--
-- Name: enum_users_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_users_role AS ENUM (
    'new_vertical_maker',
    'new_vertical_checker',
    'growth_checker',
    'growth_maker'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _announcements_v; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._announcements_v (
    id integer NOT NULL,
    parent_id integer,
    version_title character varying,
    version_body character varying,
    version_deeplink character varying,
    version_order numeric,
    version_updated_at timestamp(3) with time zone,
    version_created_at timestamp(3) with time zone,
    version__status public.enum__announcements_v_version_status DEFAULT 'draft'::public.enum__announcements_v_version_status,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    latest boolean,
    version_created_by_id integer
);


--
-- Name: _announcements_v_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._announcements_v_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _announcements_v_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._announcements_v_id_seq OWNED BY public._announcements_v.id;


--
-- Name: _blog_posts_v; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._blog_posts_v (
    id integer NOT NULL,
    parent_id integer,
    version_title character varying,
    version_slug character varying,
    version_cover_image_id integer,
    version_body jsonb,
    version_category_id integer,
    version_cta_label character varying DEFAULT 'Detayları gör'::character varying,
    version_published_date timestamp(3) with time zone,
    version_post_status public.enum__blog_posts_v_version_post_status DEFAULT 'active'::public.enum__blog_posts_v_version_post_status,
    version_seo_title character varying,
    version_seo_description character varying,
    version_seo_keywords character varying,
    version_deeplink character varying,
    version_updated_at timestamp(3) with time zone,
    version_created_at timestamp(3) with time zone,
    version__status public.enum__blog_posts_v_version_status DEFAULT 'draft'::public.enum__blog_posts_v_version_status,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    latest boolean,
    version_created_by_id integer
);


--
-- Name: _blog_posts_v_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._blog_posts_v_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _blog_posts_v_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._blog_posts_v_id_seq OWNED BY public._blog_posts_v.id;


--
-- Name: _campaigns_v; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._campaigns_v (
    id integer NOT NULL,
    parent_id integer,
    version_created_by_id integer,
    version_force_live_edit boolean DEFAULT false,
    version_review_status public.enum__campaigns_v_version_review_status DEFAULT 'pending'::public.enum__campaigns_v_version_review_status,
    version_rejection_reason character varying,
    version_rejected_at timestamp(3) with time zone,
    version_rejected_by_id integer,
    version_unpublish_request public.enum__campaigns_v_version_unpublish_request DEFAULT 'none'::public.enum__campaigns_v_version_unpublish_request,
    version_unpublish_requested_by_id integer,
    version_unpublish_requested_at timestamp(3) with time zone,
    version_title character varying,
    version_slug character varying,
    version_description character varying,
    version_image_id integer,
    version_body jsonb,
    version_terms jsonb,
    version_category_id integer,
    version_campaign_status public.enum__campaigns_v_version_campaign_status DEFAULT 'active'::public.enum__campaigns_v_version_campaign_status,
    version_featured boolean DEFAULT false,
    version_cta_label character varying DEFAULT 'Detayları gör'::character varying,
    version_cta_url character varying,
    version_seo_title character varying,
    version_seo_description character varying,
    version_seo_keywords character varying,
    version_start_date timestamp(3) with time zone,
    version_end_date timestamp(3) with time zone,
    version_show_in_footer boolean DEFAULT false,
    version_footer_order numeric,
    version_updated_at timestamp(3) with time zone,
    version_created_at timestamp(3) with time zone,
    version__status public.enum__campaigns_v_version_status DEFAULT 'draft'::public.enum__campaigns_v_version_status,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    latest boolean
);


--
-- Name: _campaigns_v_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._campaigns_v_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _campaigns_v_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._campaigns_v_id_seq OWNED BY public._campaigns_v.id;


--
-- Name: _categories_v; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._categories_v (
    id integer NOT NULL,
    parent_id integer,
    version_scope public.enum__categories_v_version_scope,
    version_label character varying,
    version_slug character varying,
    version_order numeric,
    version_created_by_id integer,
    version_updated_at timestamp(3) with time zone,
    version_created_at timestamp(3) with time zone,
    version__status public.enum__categories_v_version_status DEFAULT 'draft'::public.enum__categories_v_version_status,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    latest boolean
);


--
-- Name: _categories_v_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._categories_v_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _categories_v_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._categories_v_id_seq OWNED BY public._categories_v.id;


--
-- Name: _cookie_rows_v; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._cookie_rows_v (
    id integer NOT NULL,
    parent_id integer,
    version_name character varying,
    version_provider character varying,
    version_party public.enum__cookie_rows_v_version_party,
    version_category public.enum__cookie_rows_v_version_category,
    version_description character varying,
    version_duration character varying,
    version_updated_at timestamp(3) with time zone,
    version_created_at timestamp(3) with time zone,
    version__status public.enum__cookie_rows_v_version_status DEFAULT 'draft'::public.enum__cookie_rows_v_version_status,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    latest boolean,
    version_created_by_id integer
);


--
-- Name: _cookie_rows_v_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._cookie_rows_v_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _cookie_rows_v_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._cookie_rows_v_id_seq OWNED BY public._cookie_rows_v.id;


--
-- Name: _documents_v; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._documents_v (
    id integer NOT NULL,
    parent_id integer,
    version_url character varying,
    version_thumbnail_u_r_l character varying,
    version_filename character varying,
    version_mime_type character varying,
    version_filesize numeric,
    version_width numeric,
    version_height numeric,
    version_focal_x numeric,
    version_focal_y numeric,
    version_created_by_id integer,
    version_updated_at timestamp(3) with time zone,
    version_created_at timestamp(3) with time zone,
    version__status public.enum__documents_v_version_status DEFAULT 'draft'::public.enum__documents_v_version_status,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    latest boolean
);


--
-- Name: _documents_v_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._documents_v_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _documents_v_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._documents_v_id_seq OWNED BY public._documents_v.id;


--
-- Name: _faq_items_v; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._faq_items_v (
    id integer NOT NULL,
    parent_id integer,
    version_question character varying,
    version_answer character varying,
    version_deeplink character varying,
    version_category_id integer,
    version_show_on_homepage boolean DEFAULT false,
    version_homepage_order numeric,
    version_order numeric,
    version_show_in_footer boolean DEFAULT false,
    version_footer_order numeric,
    version_updated_at timestamp(3) with time zone,
    version_created_at timestamp(3) with time zone,
    version__status public.enum__faq_items_v_version_status DEFAULT 'draft'::public.enum__faq_items_v_version_status,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    latest boolean,
    version_created_by_id integer
);


--
-- Name: _faq_items_v_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._faq_items_v_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _faq_items_v_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._faq_items_v_id_seq OWNED BY public._faq_items_v.id;


--
-- Name: _fee_rows_v; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._fee_rows_v (
    id integer NOT NULL,
    parent_id integer,
    version_label character varying,
    version_value character varying,
    version_order numeric,
    version_updated_at timestamp(3) with time zone,
    version_created_at timestamp(3) with time zone,
    version__status public.enum__fee_rows_v_version_status DEFAULT 'draft'::public.enum__fee_rows_v_version_status,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    latest boolean,
    version_created_by_id integer
);


--
-- Name: _fee_rows_v_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._fee_rows_v_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _fee_rows_v_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._fee_rows_v_id_seq OWNED BY public._fee_rows_v.id;


--
-- Name: _legal_pages_v; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._legal_pages_v (
    id integer NOT NULL,
    parent_id integer,
    version_slug public.enum__legal_pages_v_version_slug,
    version_title character varying,
    version_intro jsonb,
    version_hero_image_id integer,
    version_deeplink character varying,
    version_updated_at timestamp(3) with time zone,
    version_created_at timestamp(3) with time zone,
    version__status public.enum__legal_pages_v_version_status DEFAULT 'draft'::public.enum__legal_pages_v_version_status,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    latest boolean,
    version_created_by_id integer
);


--
-- Name: _legal_pages_v_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._legal_pages_v_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _legal_pages_v_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._legal_pages_v_id_seq OWNED BY public._legal_pages_v.id;


--
-- Name: _legal_pages_v_version_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._legal_pages_v_version_groups (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    id integer NOT NULL,
    label character varying,
    _uuid character varying
);


--
-- Name: _legal_pages_v_version_groups_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._legal_pages_v_version_groups_documents (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    id integer NOT NULL,
    prefix character varying,
    label character varying,
    source public.enum__legal_pages_v_version_groups_documents_source DEFAULT 'pdf'::public.enum__legal_pages_v_version_groups_documents_source,
    file_id integer,
    slug character varying,
    body jsonb,
    enabled boolean DEFAULT true,
    _uuid character varying
);


--
-- Name: _legal_pages_v_version_groups_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._legal_pages_v_version_groups_documents_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _legal_pages_v_version_groups_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._legal_pages_v_version_groups_documents_id_seq OWNED BY public._legal_pages_v_version_groups_documents.id;


--
-- Name: _legal_pages_v_version_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._legal_pages_v_version_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _legal_pages_v_version_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._legal_pages_v_version_groups_id_seq OWNED BY public._legal_pages_v_version_groups.id;


--
-- Name: _limit_tables_v; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._limit_tables_v (
    id integer NOT NULL,
    parent_id integer,
    version_title character varying,
    version_order numeric,
    version_updated_at timestamp(3) with time zone,
    version_created_at timestamp(3) with time zone,
    version__status public.enum__limit_tables_v_version_status DEFAULT 'draft'::public.enum__limit_tables_v_version_status,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    latest boolean,
    version_created_by_id integer
);


--
-- Name: _limit_tables_v_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._limit_tables_v_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _limit_tables_v_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._limit_tables_v_id_seq OWNED BY public._limit_tables_v.id;


--
-- Name: _limit_tables_v_version_rows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._limit_tables_v_version_rows (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    id integer NOT NULL,
    category character varying,
    period character varying,
    unverified_limit character varying,
    verified_limit character varying,
    _uuid character varying
);


--
-- Name: _limit_tables_v_version_rows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._limit_tables_v_version_rows_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _limit_tables_v_version_rows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._limit_tables_v_version_rows_id_seq OWNED BY public._limit_tables_v_version_rows.id;


--
-- Name: _nav_links_v; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._nav_links_v (
    id integer NOT NULL,
    parent_id integer,
    version_label character varying,
    version_href character varying,
    version_mobile_href character varying,
    version_section public.enum__nav_links_v_version_section,
    version_order numeric,
    version_updated_at timestamp(3) with time zone,
    version_created_at timestamp(3) with time zone,
    version__status public.enum__nav_links_v_version_status DEFAULT 'draft'::public.enum__nav_links_v_version_status,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    latest boolean,
    version_created_by_id integer
);


--
-- Name: _nav_links_v_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._nav_links_v_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _nav_links_v_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._nav_links_v_id_seq OWNED BY public._nav_links_v.id;


--
-- Name: _page_meta_v; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._page_meta_v (
    id integer NOT NULL,
    parent_id integer,
    version_page_key character varying,
    version_breadcrumb_label character varying,
    version_seo_title character varying,
    version_seo_description character varying,
    version_seo_keywords character varying,
    version_og_image_id integer,
    version_updated_at timestamp(3) with time zone,
    version_created_at timestamp(3) with time zone,
    version__status public.enum__page_meta_v_version_status DEFAULT 'draft'::public.enum__page_meta_v_version_status,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    latest boolean,
    version_created_by_id integer
);


--
-- Name: _page_meta_v_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._page_meta_v_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _page_meta_v_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._page_meta_v_id_seq OWNED BY public._page_meta_v.id;


--
-- Name: _pages_v; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v (
    id integer NOT NULL,
    parent_id integer,
    version_title character varying,
    version_slug character varying,
    version_seo_title character varying,
    version_seo_description character varying,
    version_seo_keywords character varying,
    version_og_image_id integer,
    version_parent_id integer,
    version_visibility public.enum__pages_v_version_visibility DEFAULT 'public'::public.enum__pages_v_version_visibility,
    version_created_by_id integer,
    version_deeplink character varying,
    version_updated_at timestamp(3) with time zone,
    version_created_at timestamp(3) with time zone,
    version__status public.enum__pages_v_version_status DEFAULT 'draft'::public.enum__pages_v_version_status,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    latest boolean,
    version_show_in_products_menu boolean DEFAULT false,
    version_products_menu_label character varying,
    version_products_menu_order numeric
);


--
-- Name: _pages_v_blocks_blog_grid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_blog_grid (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    category character varying,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_blog_grid_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_blog_grid_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_blog_grid_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_blog_grid_id_seq OWNED BY public._pages_v_blocks_blog_grid.id;


--
-- Name: _pages_v_blocks_campaign_grid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_campaign_grid (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    category character varying,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_campaign_grid_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_campaign_grid_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_campaign_grid_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_campaign_grid_id_seq OWNED BY public._pages_v_blocks_campaign_grid.id;


--
-- Name: _pages_v_blocks_contact_info; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_contact_info (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_contact_info_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_contact_info_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_contact_info_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_contact_info_id_seq OWNED BY public._pages_v_blocks_contact_info.id;


--
-- Name: _pages_v_blocks_faq_list; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_faq_list (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    category character varying,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_faq_list_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_faq_list_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_faq_list_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_faq_list_id_seq OWNED BY public._pages_v_blocks_faq_list.id;


--
-- Name: _pages_v_blocks_feature_highlights; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_feature_highlights (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    media_id integer,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_feature_highlights_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_feature_highlights_features (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    id integer NOT NULL,
    icon_id integer,
    title character varying,
    description character varying,
    _uuid character varying
);


--
-- Name: _pages_v_blocks_feature_highlights_features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_feature_highlights_features_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_feature_highlights_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_feature_highlights_features_id_seq OWNED BY public._pages_v_blocks_feature_highlights_features.id;


--
-- Name: _pages_v_blocks_feature_highlights_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_feature_highlights_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_feature_highlights_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_feature_highlights_id_seq OWNED BY public._pages_v_blocks_feature_highlights.id;


--
-- Name: _pages_v_blocks_hero; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_hero (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    subheading character varying,
    image_id integer,
    cta_label character varying,
    cta_url character varying,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_hero_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_hero_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_hero_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_hero_id_seq OWNED BY public._pages_v_blocks_hero.id;


--
-- Name: _pages_v_blocks_how_to_earn; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_how_to_earn (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    image_id integer,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_how_to_earn_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_how_to_earn_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_how_to_earn_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_how_to_earn_id_seq OWNED BY public._pages_v_blocks_how_to_earn.id;


--
-- Name: _pages_v_blocks_how_to_earn_steps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_how_to_earn_steps (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    id integer NOT NULL,
    icon_id integer,
    title character varying,
    description character varying,
    _uuid character varying
);


--
-- Name: _pages_v_blocks_how_to_earn_steps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_how_to_earn_steps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_how_to_earn_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_how_to_earn_steps_id_seq OWNED BY public._pages_v_blocks_how_to_earn_steps.id;


--
-- Name: _pages_v_blocks_icon_cards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_icon_cards (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    _uuid character varying,
    block_name character varying,
    description character varying
);


--
-- Name: _pages_v_blocks_icon_cards_cards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_icon_cards_cards (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    id integer NOT NULL,
    icon_id integer,
    title character varying,
    text character varying,
    _uuid character varying
);


--
-- Name: _pages_v_blocks_icon_cards_cards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_icon_cards_cards_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_icon_cards_cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_icon_cards_cards_id_seq OWNED BY public._pages_v_blocks_icon_cards_cards.id;


--
-- Name: _pages_v_blocks_icon_cards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_icon_cards_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_icon_cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_icon_cards_id_seq OWNED BY public._pages_v_blocks_icon_cards.id;


--
-- Name: _pages_v_blocks_image_text_slides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_image_text_slides (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    _uuid character varying,
    block_name character varying,
    intro character varying,
    side_image_id integer
);


--
-- Name: _pages_v_blocks_image_text_slides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_image_text_slides_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_image_text_slides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_image_text_slides_id_seq OWNED BY public._pages_v_blocks_image_text_slides.id;


--
-- Name: _pages_v_blocks_image_text_slides_slides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_image_text_slides_slides (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    id integer NOT NULL,
    image_id integer,
    text character varying,
    _uuid character varying
);


--
-- Name: _pages_v_blocks_image_text_slides_slides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_image_text_slides_slides_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_image_text_slides_slides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_image_text_slides_slides_id_seq OWNED BY public._pages_v_blocks_image_text_slides_slides.id;


--
-- Name: _pages_v_blocks_image_with_text; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_image_with_text (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    text character varying,
    image_id integer,
    image_side public.enum__pages_v_blocks_image_with_text_image_side DEFAULT 'left'::public.enum__pages_v_blocks_image_with_text_image_side,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_image_with_text_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_image_with_text_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_image_with_text_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_image_with_text_id_seq OWNED BY public._pages_v_blocks_image_with_text.id;


--
-- Name: _pages_v_blocks_lead_form_cta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_lead_form_cta (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_lead_form_cta_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_lead_form_cta_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_lead_form_cta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_lead_form_cta_id_seq OWNED BY public._pages_v_blocks_lead_form_cta.id;


--
-- Name: _pages_v_blocks_logo_grid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_logo_grid (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_logo_grid_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_logo_grid_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_logo_grid_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_logo_grid_id_seq OWNED BY public._pages_v_blocks_logo_grid.id;


--
-- Name: _pages_v_blocks_logo_grid_logos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_logo_grid_logos (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    id integer NOT NULL,
    name character varying,
    logo_id integer,
    link_url character varying,
    _uuid character varying
);


--
-- Name: _pages_v_blocks_logo_grid_logos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_logo_grid_logos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_logo_grid_logos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_logo_grid_logos_id_seq OWNED BY public._pages_v_blocks_logo_grid_logos.id;


--
-- Name: _pages_v_blocks_media_panel; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_media_panel (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    text character varying,
    background_image_id integer,
    youtube_id character varying,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_media_panel_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_media_panel_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_media_panel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_media_panel_id_seq OWNED BY public._pages_v_blocks_media_panel.id;


--
-- Name: _pages_v_blocks_prices_and_limits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_prices_and_limits (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_prices_and_limits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_prices_and_limits_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_prices_and_limits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_prices_and_limits_id_seq OWNED BY public._pages_v_blocks_prices_and_limits.id;


--
-- Name: _pages_v_blocks_profile_grid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_profile_grid (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_profile_grid_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_profile_grid_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_profile_grid_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_profile_grid_id_seq OWNED BY public._pages_v_blocks_profile_grid.id;


--
-- Name: _pages_v_blocks_profile_grid_people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_profile_grid_people (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    id integer NOT NULL,
    photo_id integer,
    name character varying,
    title character varying,
    _uuid character varying
);


--
-- Name: _pages_v_blocks_profile_grid_people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_profile_grid_people_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_profile_grid_people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_profile_grid_people_id_seq OWNED BY public._pages_v_blocks_profile_grid_people.id;


--
-- Name: _pages_v_blocks_representatives; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_representatives (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    "limit" numeric,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_representatives_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_representatives_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_representatives_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_representatives_id_seq OWNED BY public._pages_v_blocks_representatives.id;


--
-- Name: _pages_v_blocks_rich_text; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_rich_text (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    body jsonb,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_rich_text_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_rich_text_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_rich_text_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_rich_text_id_seq OWNED BY public._pages_v_blocks_rich_text.id;


--
-- Name: _pages_v_blocks_step_phones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_step_phones (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    description character varying,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_step_phones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_step_phones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_step_phones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_step_phones_id_seq OWNED BY public._pages_v_blocks_step_phones.id;


--
-- Name: _pages_v_blocks_step_phones_steps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_step_phones_steps (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    id integer NOT NULL,
    image_id integer,
    title character varying,
    description character varying,
    _uuid character varying
);


--
-- Name: _pages_v_blocks_step_phones_steps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_step_phones_steps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_step_phones_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_step_phones_steps_id_seq OWNED BY public._pages_v_blocks_step_phones_steps.id;


--
-- Name: _pages_v_blocks_steps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_steps (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_steps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_steps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_steps_id_seq OWNED BY public._pages_v_blocks_steps.id;


--
-- Name: _pages_v_blocks_steps_steps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_steps_steps (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    id integer NOT NULL,
    number character varying,
    text character varying,
    image_id integer,
    _uuid character varying
);


--
-- Name: _pages_v_blocks_steps_steps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_steps_steps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_steps_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_steps_steps_id_seq OWNED BY public._pages_v_blocks_steps_steps.id;


--
-- Name: _pages_v_blocks_video; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_video (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    youtube_id character varying,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_video_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_video_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_video_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_video_id_seq OWNED BY public._pages_v_blocks_video.id;


--
-- Name: _pages_v_blocks_video_list; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_video_list (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    heading character varying,
    _uuid character varying,
    block_name character varying,
    subheading character varying,
    dark_background_image_id integer
);


--
-- Name: _pages_v_blocks_video_list_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_video_list_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_video_list_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_video_list_id_seq OWNED BY public._pages_v_blocks_video_list.id;


--
-- Name: _pages_v_blocks_video_list_videos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_video_list_videos (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    id integer NOT NULL,
    title character varying,
    youtube_id character varying,
    _uuid character varying
);


--
-- Name: _pages_v_blocks_video_list_videos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_video_list_videos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_video_list_videos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_video_list_videos_id_seq OWNED BY public._pages_v_blocks_video_list_videos.id;


--
-- Name: _pages_v_blocks_videos_with_tabs_marker; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._pages_v_blocks_videos_with_tabs_marker (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id integer NOT NULL,
    _uuid character varying,
    block_name character varying
);


--
-- Name: _pages_v_blocks_videos_with_tabs_marker_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_blocks_videos_with_tabs_marker_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_blocks_videos_with_tabs_marker_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_blocks_videos_with_tabs_marker_id_seq OWNED BY public._pages_v_blocks_videos_with_tabs_marker.id;


--
-- Name: _pages_v_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._pages_v_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _pages_v_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._pages_v_id_seq OWNED BY public._pages_v.id;


--
-- Name: _representatives_v; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._representatives_v (
    id integer NOT NULL,
    parent_id integer,
    version_business_name character varying,
    version_rep_code character varying,
    version_activity_description character varying,
    version_phone character varying,
    version_mersis_no character varying,
    version_address character varying,
    version_province character varying,
    version_district character varying,
    version_authorized_person character varying,
    version_qr_code_id integer,
    version_created_by_id integer,
    version_updated_at timestamp(3) with time zone,
    version_created_at timestamp(3) with time zone,
    version__status public.enum__representatives_v_version_status DEFAULT 'draft'::public.enum__representatives_v_version_status,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    latest boolean
);


--
-- Name: _representatives_v_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public._representatives_v_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: _representatives_v_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public._representatives_v_id_seq OWNED BY public._representatives_v.id;


--
-- Name: announcements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.announcements (
    id integer NOT NULL,
    title character varying,
    body character varying,
    deeplink character varying,
    "order" numeric,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    _status public.enum_announcements_status DEFAULT 'draft'::public.enum_announcements_status,
    created_by_id integer
);


--
-- Name: announcements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.announcements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: announcements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.announcements_id_seq OWNED BY public.announcements.id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id integer NOT NULL,
    user_email character varying NOT NULL,
    user_role character varying,
    action public.enum_audit_logs_action NOT NULL,
    collection_slug character varying,
    document_id character varying,
    summary character varying NOT NULL,
    ip character varying,
    user_agent character varying,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL
);


--
-- Name: audit_logs_changes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs_changes (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    id character varying NOT NULL,
    field character varying,
    before character varying,
    after character varying
);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: blog_posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blog_posts (
    id integer NOT NULL,
    title character varying,
    slug character varying,
    cover_image_id integer,
    body jsonb,
    category_id integer,
    cta_label character varying DEFAULT 'Detayları gör'::character varying,
    published_date timestamp(3) with time zone,
    post_status public.enum_blog_posts_post_status DEFAULT 'active'::public.enum_blog_posts_post_status,
    seo_title character varying,
    seo_description character varying,
    seo_keywords character varying,
    deeplink character varying,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    _status public.enum_blog_posts_status DEFAULT 'draft'::public.enum_blog_posts_status,
    created_by_id integer
);


--
-- Name: blog_posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blog_posts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blog_posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blog_posts_id_seq OWNED BY public.blog_posts.id;


--
-- Name: campaigns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campaigns (
    id integer NOT NULL,
    created_by_id integer,
    force_live_edit boolean DEFAULT false,
    review_status public.enum_campaigns_review_status DEFAULT 'pending'::public.enum_campaigns_review_status,
    rejection_reason character varying,
    rejected_at timestamp(3) with time zone,
    rejected_by_id integer,
    unpublish_request public.enum_campaigns_unpublish_request DEFAULT 'none'::public.enum_campaigns_unpublish_request,
    unpublish_requested_by_id integer,
    unpublish_requested_at timestamp(3) with time zone,
    title character varying,
    slug character varying,
    description character varying,
    image_id integer,
    body jsonb,
    terms jsonb,
    category_id integer,
    campaign_status public.enum_campaigns_campaign_status DEFAULT 'active'::public.enum_campaigns_campaign_status,
    featured boolean DEFAULT false,
    cta_label character varying DEFAULT 'Detayları gör'::character varying,
    cta_url character varying,
    seo_title character varying,
    seo_description character varying,
    seo_keywords character varying,
    start_date timestamp(3) with time zone,
    end_date timestamp(3) with time zone,
    show_in_footer boolean DEFAULT false,
    footer_order numeric,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    _status public.enum_campaigns_status DEFAULT 'draft'::public.enum_campaigns_status
);


--
-- Name: campaigns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.campaigns_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campaigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.campaigns_id_seq OWNED BY public.campaigns.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id integer NOT NULL,
    scope public.enum_categories_scope DEFAULT 'campaign'::public.enum_categories_scope NOT NULL,
    label character varying NOT NULL,
    slug character varying NOT NULL,
    "order" numeric,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    _status public.enum_categories_status DEFAULT 'draft'::public.enum_categories_status,
    created_by_id integer
);


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: contact_info; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contact_info (
    id integer NOT NULL,
    company_name character varying NOT NULL,
    trade_registry_no character varying NOT NULL,
    address character varying NOT NULL,
    phone character varying NOT NULL,
    kep_address character varying NOT NULL,
    customer_service_text character varying NOT NULL,
    tcmb_address character varying NOT NULL,
    tcmb_phone character varying NOT NULL,
    tcmb_fax character varying NOT NULL,
    tcmb_kep character varying NOT NULL,
    press_relations_url character varying,
    updated_at timestamp(3) with time zone,
    created_at timestamp(3) with time zone
);


--
-- Name: contact_info_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contact_info_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contact_info_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contact_info_id_seq OWNED BY public.contact_info.id;


--
-- Name: cookie_rows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cookie_rows (
    id integer NOT NULL,
    name character varying,
    provider character varying,
    party public.enum_cookie_rows_party,
    category public.enum_cookie_rows_category,
    description character varying,
    duration character varying,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    _status public.enum_cookie_rows_status DEFAULT 'draft'::public.enum_cookie_rows_status,
    created_by_id integer
);


--
-- Name: cookie_rows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cookie_rows_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cookie_rows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cookie_rows_id_seq OWNED BY public.cookie_rows.id;


--
-- Name: documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documents (
    id integer NOT NULL,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    url character varying,
    thumbnail_u_r_l character varying,
    filename character varying,
    mime_type character varying,
    filesize numeric,
    width numeric,
    height numeric,
    focal_x numeric,
    focal_y numeric,
    _status public.enum_documents_status DEFAULT 'draft'::public.enum_documents_status,
    created_by_id integer
);


--
-- Name: documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.documents_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.documents_id_seq OWNED BY public.documents.id;


--
-- Name: faq_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faq_items (
    id integer NOT NULL,
    question character varying,
    answer character varying,
    deeplink character varying,
    category_id integer,
    show_on_homepage boolean DEFAULT false,
    homepage_order numeric,
    "order" numeric,
    show_in_footer boolean DEFAULT false,
    footer_order numeric,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    _status public.enum_faq_items_status DEFAULT 'draft'::public.enum_faq_items_status,
    created_by_id integer
);


--
-- Name: faq_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.faq_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: faq_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.faq_items_id_seq OWNED BY public.faq_items.id;


--
-- Name: fee_rows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fee_rows (
    id integer NOT NULL,
    label character varying,
    value character varying,
    "order" numeric,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    _status public.enum_fee_rows_status DEFAULT 'draft'::public.enum_fee_rows_status,
    created_by_id integer
);


--
-- Name: fee_rows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fee_rows_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fee_rows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fee_rows_id_seq OWNED BY public.fee_rows.id;


--
-- Name: feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback (
    id integer NOT NULL,
    message character varying NOT NULL,
    area character varying,
    page_path character varying,
    user_email character varying NOT NULL,
    user_role character varying,
    ip character varying,
    user_agent character varying,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL
);


--
-- Name: feedback_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feedback_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feedback_id_seq OWNED BY public.feedback.id;


--
-- Name: legal_pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.legal_pages (
    id integer NOT NULL,
    slug public.enum_legal_pages_slug,
    title character varying,
    intro jsonb,
    hero_image_id integer,
    deeplink character varying,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    _status public.enum_legal_pages_status DEFAULT 'draft'::public.enum_legal_pages_status,
    created_by_id integer
);


--
-- Name: legal_pages_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.legal_pages_groups (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    id character varying NOT NULL,
    label character varying
);


--
-- Name: legal_pages_groups_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.legal_pages_groups_documents (
    _order integer NOT NULL,
    _parent_id character varying NOT NULL,
    id character varying NOT NULL,
    prefix character varying,
    label character varying,
    source public.enum_legal_pages_groups_documents_source DEFAULT 'pdf'::public.enum_legal_pages_groups_documents_source,
    file_id integer,
    slug character varying,
    body jsonb,
    enabled boolean DEFAULT true
);


--
-- Name: legal_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.legal_pages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: legal_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.legal_pages_id_seq OWNED BY public.legal_pages.id;


--
-- Name: limit_tables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.limit_tables (
    id integer NOT NULL,
    title character varying,
    "order" numeric,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    _status public.enum_limit_tables_status DEFAULT 'draft'::public.enum_limit_tables_status,
    created_by_id integer
);


--
-- Name: limit_tables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.limit_tables_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: limit_tables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.limit_tables_id_seq OWNED BY public.limit_tables.id;


--
-- Name: limit_tables_rows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.limit_tables_rows (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    id character varying NOT NULL,
    category character varying,
    period character varying,
    unverified_limit character varying,
    verified_limit character varying
);


--
-- Name: media; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media (
    id integer NOT NULL,
    alt character varying NOT NULL,
    caption character varying,
    media_type public.enum_media_media_type,
    uploaded_by_id integer,
    usage_url character varying,
    usage_note character varying,
    size_override_confirmed boolean DEFAULT false,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    url character varying,
    thumbnail_u_r_l character varying,
    filename character varying,
    mime_type character varying,
    filesize numeric,
    width numeric,
    height numeric,
    focal_x numeric,
    focal_y numeric,
    sizes_thumbnail_url character varying,
    sizes_thumbnail_width numeric,
    sizes_thumbnail_height numeric,
    sizes_thumbnail_mime_type character varying,
    sizes_thumbnail_filesize numeric,
    sizes_thumbnail_filename character varying,
    sizes_card_url character varying,
    sizes_card_width numeric,
    sizes_card_height numeric,
    sizes_card_mime_type character varying,
    sizes_card_filesize numeric,
    sizes_card_filename character varying,
    sizes_hero_url character varying,
    sizes_hero_width numeric,
    sizes_hero_height numeric,
    sizes_hero_mime_type character varying,
    sizes_hero_filesize numeric,
    sizes_hero_filename character varying
);


--
-- Name: media_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.media_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: media_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.media_id_seq OWNED BY public.media.id;


--
-- Name: nav_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nav_links (
    id integer NOT NULL,
    label character varying,
    href character varying,
    mobile_href character varying,
    section public.enum_nav_links_section,
    "order" numeric,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    _status public.enum_nav_links_status DEFAULT 'draft'::public.enum_nav_links_status,
    created_by_id integer
);


--
-- Name: nav_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nav_links_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nav_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nav_links_id_seq OWNED BY public.nav_links.id;


--
-- Name: page_meta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.page_meta (
    id integer NOT NULL,
    page_key character varying,
    breadcrumb_label character varying,
    seo_title character varying,
    seo_description character varying,
    seo_keywords character varying,
    og_image_id integer,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    _status public.enum_page_meta_status DEFAULT 'draft'::public.enum_page_meta_status,
    created_by_id integer
);


--
-- Name: page_meta_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.page_meta_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: page_meta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.page_meta_id_seq OWNED BY public.page_meta.id;


--
-- Name: pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages (
    id integer NOT NULL,
    title character varying,
    slug character varying,
    seo_title character varying,
    seo_description character varying,
    seo_keywords character varying,
    og_image_id integer,
    parent_id integer,
    visibility public.enum_pages_visibility DEFAULT 'public'::public.enum_pages_visibility,
    created_by_id integer,
    deeplink character varying,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    _status public.enum_pages_status DEFAULT 'draft'::public.enum_pages_status,
    show_in_products_menu boolean DEFAULT false,
    products_menu_label character varying,
    products_menu_order numeric
);


--
-- Name: pages_blocks_blog_grid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_blog_grid (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    category character varying,
    block_name character varying
);


--
-- Name: pages_blocks_campaign_grid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_campaign_grid (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    category character varying,
    block_name character varying
);


--
-- Name: pages_blocks_contact_info; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_contact_info (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    block_name character varying
);


--
-- Name: pages_blocks_faq_list; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_faq_list (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    category character varying,
    block_name character varying
);


--
-- Name: pages_blocks_feature_highlights; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_feature_highlights (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    media_id integer,
    block_name character varying
);


--
-- Name: pages_blocks_feature_highlights_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_feature_highlights_features (
    _order integer NOT NULL,
    _parent_id character varying NOT NULL,
    id character varying NOT NULL,
    icon_id integer,
    title character varying,
    description character varying
);


--
-- Name: pages_blocks_hero; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_hero (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    subheading character varying,
    image_id integer,
    cta_label character varying,
    cta_url character varying,
    block_name character varying
);


--
-- Name: pages_blocks_how_to_earn; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_how_to_earn (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    image_id integer,
    block_name character varying
);


--
-- Name: pages_blocks_how_to_earn_steps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_how_to_earn_steps (
    _order integer NOT NULL,
    _parent_id character varying NOT NULL,
    id character varying NOT NULL,
    icon_id integer,
    title character varying,
    description character varying
);


--
-- Name: pages_blocks_icon_cards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_icon_cards (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    block_name character varying,
    description character varying
);


--
-- Name: pages_blocks_icon_cards_cards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_icon_cards_cards (
    _order integer NOT NULL,
    _parent_id character varying NOT NULL,
    id character varying NOT NULL,
    icon_id integer,
    title character varying,
    text character varying
);


--
-- Name: pages_blocks_image_text_slides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_image_text_slides (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    block_name character varying,
    intro character varying,
    side_image_id integer
);


--
-- Name: pages_blocks_image_text_slides_slides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_image_text_slides_slides (
    _order integer NOT NULL,
    _parent_id character varying NOT NULL,
    id character varying NOT NULL,
    image_id integer,
    text character varying
);


--
-- Name: pages_blocks_image_with_text; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_image_with_text (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    text character varying,
    image_id integer,
    image_side public.enum_pages_blocks_image_with_text_image_side DEFAULT 'left'::public.enum_pages_blocks_image_with_text_image_side,
    block_name character varying
);


--
-- Name: pages_blocks_lead_form_cta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_lead_form_cta (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    block_name character varying
);


--
-- Name: pages_blocks_logo_grid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_logo_grid (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    block_name character varying
);


--
-- Name: pages_blocks_logo_grid_logos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_logo_grid_logos (
    _order integer NOT NULL,
    _parent_id character varying NOT NULL,
    id character varying NOT NULL,
    name character varying,
    logo_id integer,
    link_url character varying
);


--
-- Name: pages_blocks_media_panel; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_media_panel (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    text character varying,
    background_image_id integer,
    youtube_id character varying,
    block_name character varying
);


--
-- Name: pages_blocks_prices_and_limits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_prices_and_limits (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    block_name character varying
);


--
-- Name: pages_blocks_profile_grid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_profile_grid (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    block_name character varying
);


--
-- Name: pages_blocks_profile_grid_people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_profile_grid_people (
    _order integer NOT NULL,
    _parent_id character varying NOT NULL,
    id character varying NOT NULL,
    photo_id integer,
    name character varying,
    title character varying
);


--
-- Name: pages_blocks_representatives; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_representatives (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    "limit" numeric,
    block_name character varying
);


--
-- Name: pages_blocks_rich_text; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_rich_text (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    body jsonb,
    block_name character varying
);


--
-- Name: pages_blocks_step_phones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_step_phones (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    description character varying,
    block_name character varying
);


--
-- Name: pages_blocks_step_phones_steps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_step_phones_steps (
    _order integer NOT NULL,
    _parent_id character varying NOT NULL,
    id character varying NOT NULL,
    image_id integer,
    title character varying,
    description character varying
);


--
-- Name: pages_blocks_steps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_steps (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    block_name character varying
);


--
-- Name: pages_blocks_steps_steps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_steps_steps (
    _order integer NOT NULL,
    _parent_id character varying NOT NULL,
    id character varying NOT NULL,
    number character varying,
    text character varying,
    image_id integer
);


--
-- Name: pages_blocks_video; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_video (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    youtube_id character varying,
    block_name character varying
);


--
-- Name: pages_blocks_video_list; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_video_list (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    heading character varying,
    block_name character varying,
    subheading character varying,
    dark_background_image_id integer
);


--
-- Name: pages_blocks_video_list_videos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_video_list_videos (
    _order integer NOT NULL,
    _parent_id character varying NOT NULL,
    id character varying NOT NULL,
    title character varying,
    youtube_id character varying
);


--
-- Name: pages_blocks_videos_with_tabs_marker; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages_blocks_videos_with_tabs_marker (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    _path text NOT NULL,
    id character varying NOT NULL,
    block_name character varying
);


--
-- Name: pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pages_id_seq OWNED BY public.pages.id;


--
-- Name: payload_kv; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payload_kv (
    id integer NOT NULL,
    key character varying NOT NULL,
    data jsonb NOT NULL
);


--
-- Name: payload_kv_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payload_kv_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payload_kv_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payload_kv_id_seq OWNED BY public.payload_kv.id;


--
-- Name: payload_locked_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payload_locked_documents (
    id integer NOT NULL,
    global_slug character varying,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL
);


--
-- Name: payload_locked_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payload_locked_documents_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payload_locked_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payload_locked_documents_id_seq OWNED BY public.payload_locked_documents.id;


--
-- Name: payload_locked_documents_rels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payload_locked_documents_rels (
    id integer NOT NULL,
    "order" integer,
    parent_id integer NOT NULL,
    path character varying NOT NULL,
    users_id integer,
    media_id integer,
    documents_id integer,
    audit_logs_id integer,
    translations_id integer,
    categories_id integer,
    campaigns_id integer,
    pages_id integer,
    faq_items_id integer,
    blog_posts_id integer,
    representatives_id integer,
    announcements_id integer,
    fee_rows_id integer,
    limit_tables_id integer,
    nav_links_id integer,
    legal_pages_id integer,
    cookie_rows_id integer,
    page_meta_id integer,
    feedback_id integer
);


--
-- Name: payload_locked_documents_rels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payload_locked_documents_rels_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payload_locked_documents_rels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payload_locked_documents_rels_id_seq OWNED BY public.payload_locked_documents_rels.id;


--
-- Name: payload_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payload_migrations (
    id integer NOT NULL,
    name character varying,
    batch numeric,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL
);


--
-- Name: payload_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payload_migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payload_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payload_migrations_id_seq OWNED BY public.payload_migrations.id;


--
-- Name: payload_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payload_preferences (
    id integer NOT NULL,
    key character varying,
    value jsonb,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL
);


--
-- Name: payload_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payload_preferences_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payload_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payload_preferences_id_seq OWNED BY public.payload_preferences.id;


--
-- Name: payload_preferences_rels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payload_preferences_rels (
    id integer NOT NULL,
    "order" integer,
    parent_id integer NOT NULL,
    path character varying NOT NULL,
    users_id integer
);


--
-- Name: payload_preferences_rels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payload_preferences_rels_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payload_preferences_rels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payload_preferences_rels_id_seq OWNED BY public.payload_preferences_rels.id;


--
-- Name: representatives; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.representatives (
    id integer NOT NULL,
    business_name character varying NOT NULL,
    rep_code character varying,
    activity_description character varying,
    phone character varying,
    mersis_no character varying,
    address character varying NOT NULL,
    province character varying NOT NULL,
    district character varying NOT NULL,
    authorized_person character varying,
    qr_code_id integer,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    _status public.enum_representatives_status DEFAULT 'draft'::public.enum_representatives_status,
    created_by_id integer
);


--
-- Name: representatives_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.representatives_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: representatives_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.representatives_id_seq OWNED BY public.representatives.id;


--
-- Name: translations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.translations (
    id integer NOT NULL,
    key character varying NOT NULL,
    tr character varying NOT NULL,
    en character varying NOT NULL,
    is_customized boolean DEFAULT false,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL
);


--
-- Name: translations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.translations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.translations_id_seq OWNED BY public.translations.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying,
    role public.enum_users_role DEFAULT 'growth_maker'::public.enum_users_role NOT NULL,
    avatar_id integer,
    delegate_to_id integer,
    delegation_expires_at timestamp(3) with time zone,
    preferred_locale public.enum_users_preferred_locale DEFAULT 'tr'::public.enum_users_preferred_locale,
    last_login_at timestamp(3) with time zone,
    last_login_ip character varying,
    last_login_user_agent character varying,
    updated_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    created_at timestamp(3) with time zone DEFAULT now() NOT NULL,
    email character varying NOT NULL,
    reset_password_token character varying,
    reset_password_expiration timestamp(3) with time zone,
    salt character varying,
    hash character varying,
    login_attempts numeric DEFAULT 0,
    lock_until timestamp(3) with time zone
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: users_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users_sessions (
    _order integer NOT NULL,
    _parent_id integer NOT NULL,
    id character varying NOT NULL,
    created_at timestamp(3) with time zone,
    expires_at timestamp(3) with time zone NOT NULL
);


--
-- Name: _announcements_v id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._announcements_v ALTER COLUMN id SET DEFAULT nextval('public._announcements_v_id_seq'::regclass);


--
-- Name: _blog_posts_v id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._blog_posts_v ALTER COLUMN id SET DEFAULT nextval('public._blog_posts_v_id_seq'::regclass);


--
-- Name: _campaigns_v id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._campaigns_v ALTER COLUMN id SET DEFAULT nextval('public._campaigns_v_id_seq'::regclass);


--
-- Name: _categories_v id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._categories_v ALTER COLUMN id SET DEFAULT nextval('public._categories_v_id_seq'::regclass);


--
-- Name: _cookie_rows_v id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._cookie_rows_v ALTER COLUMN id SET DEFAULT nextval('public._cookie_rows_v_id_seq'::regclass);


--
-- Name: _documents_v id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._documents_v ALTER COLUMN id SET DEFAULT nextval('public._documents_v_id_seq'::regclass);


--
-- Name: _faq_items_v id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._faq_items_v ALTER COLUMN id SET DEFAULT nextval('public._faq_items_v_id_seq'::regclass);


--
-- Name: _fee_rows_v id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._fee_rows_v ALTER COLUMN id SET DEFAULT nextval('public._fee_rows_v_id_seq'::regclass);


--
-- Name: _legal_pages_v id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._legal_pages_v ALTER COLUMN id SET DEFAULT nextval('public._legal_pages_v_id_seq'::regclass);


--
-- Name: _legal_pages_v_version_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._legal_pages_v_version_groups ALTER COLUMN id SET DEFAULT nextval('public._legal_pages_v_version_groups_id_seq'::regclass);


--
-- Name: _legal_pages_v_version_groups_documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._legal_pages_v_version_groups_documents ALTER COLUMN id SET DEFAULT nextval('public._legal_pages_v_version_groups_documents_id_seq'::regclass);


--
-- Name: _limit_tables_v id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._limit_tables_v ALTER COLUMN id SET DEFAULT nextval('public._limit_tables_v_id_seq'::regclass);


--
-- Name: _limit_tables_v_version_rows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._limit_tables_v_version_rows ALTER COLUMN id SET DEFAULT nextval('public._limit_tables_v_version_rows_id_seq'::regclass);


--
-- Name: _nav_links_v id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._nav_links_v ALTER COLUMN id SET DEFAULT nextval('public._nav_links_v_id_seq'::regclass);


--
-- Name: _page_meta_v id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._page_meta_v ALTER COLUMN id SET DEFAULT nextval('public._page_meta_v_id_seq'::regclass);


--
-- Name: _pages_v id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v ALTER COLUMN id SET DEFAULT nextval('public._pages_v_id_seq'::regclass);


--
-- Name: _pages_v_blocks_blog_grid id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_blog_grid ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_blog_grid_id_seq'::regclass);


--
-- Name: _pages_v_blocks_campaign_grid id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_campaign_grid ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_campaign_grid_id_seq'::regclass);


--
-- Name: _pages_v_blocks_contact_info id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_contact_info ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_contact_info_id_seq'::regclass);


--
-- Name: _pages_v_blocks_faq_list id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_faq_list ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_faq_list_id_seq'::regclass);


--
-- Name: _pages_v_blocks_feature_highlights id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_feature_highlights ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_feature_highlights_id_seq'::regclass);


--
-- Name: _pages_v_blocks_feature_highlights_features id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_feature_highlights_features ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_feature_highlights_features_id_seq'::regclass);


--
-- Name: _pages_v_blocks_hero id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_hero ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_hero_id_seq'::regclass);


--
-- Name: _pages_v_blocks_how_to_earn id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_how_to_earn ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_how_to_earn_id_seq'::regclass);


--
-- Name: _pages_v_blocks_how_to_earn_steps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_how_to_earn_steps ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_how_to_earn_steps_id_seq'::regclass);


--
-- Name: _pages_v_blocks_icon_cards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_icon_cards ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_icon_cards_id_seq'::regclass);


--
-- Name: _pages_v_blocks_icon_cards_cards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_icon_cards_cards ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_icon_cards_cards_id_seq'::regclass);


--
-- Name: _pages_v_blocks_image_text_slides id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_image_text_slides ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_image_text_slides_id_seq'::regclass);


--
-- Name: _pages_v_blocks_image_text_slides_slides id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_image_text_slides_slides ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_image_text_slides_slides_id_seq'::regclass);


--
-- Name: _pages_v_blocks_image_with_text id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_image_with_text ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_image_with_text_id_seq'::regclass);


--
-- Name: _pages_v_blocks_lead_form_cta id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_lead_form_cta ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_lead_form_cta_id_seq'::regclass);


--
-- Name: _pages_v_blocks_logo_grid id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_logo_grid ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_logo_grid_id_seq'::regclass);


--
-- Name: _pages_v_blocks_logo_grid_logos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_logo_grid_logos ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_logo_grid_logos_id_seq'::regclass);


--
-- Name: _pages_v_blocks_media_panel id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_media_panel ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_media_panel_id_seq'::regclass);


--
-- Name: _pages_v_blocks_prices_and_limits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_prices_and_limits ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_prices_and_limits_id_seq'::regclass);


--
-- Name: _pages_v_blocks_profile_grid id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_profile_grid ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_profile_grid_id_seq'::regclass);


--
-- Name: _pages_v_blocks_profile_grid_people id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_profile_grid_people ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_profile_grid_people_id_seq'::regclass);


--
-- Name: _pages_v_blocks_representatives id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_representatives ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_representatives_id_seq'::regclass);


--
-- Name: _pages_v_blocks_rich_text id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_rich_text ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_rich_text_id_seq'::regclass);


--
-- Name: _pages_v_blocks_step_phones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_step_phones ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_step_phones_id_seq'::regclass);


--
-- Name: _pages_v_blocks_step_phones_steps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_step_phones_steps ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_step_phones_steps_id_seq'::regclass);


--
-- Name: _pages_v_blocks_steps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_steps ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_steps_id_seq'::regclass);


--
-- Name: _pages_v_blocks_steps_steps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_steps_steps ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_steps_steps_id_seq'::regclass);


--
-- Name: _pages_v_blocks_video id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_video ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_video_id_seq'::regclass);


--
-- Name: _pages_v_blocks_video_list id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_video_list ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_video_list_id_seq'::regclass);


--
-- Name: _pages_v_blocks_video_list_videos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_video_list_videos ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_video_list_videos_id_seq'::regclass);


--
-- Name: _pages_v_blocks_videos_with_tabs_marker id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_videos_with_tabs_marker ALTER COLUMN id SET DEFAULT nextval('public._pages_v_blocks_videos_with_tabs_marker_id_seq'::regclass);


--
-- Name: _representatives_v id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._representatives_v ALTER COLUMN id SET DEFAULT nextval('public._representatives_v_id_seq'::regclass);


--
-- Name: announcements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements ALTER COLUMN id SET DEFAULT nextval('public.announcements_id_seq'::regclass);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: blog_posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blog_posts ALTER COLUMN id SET DEFAULT nextval('public.blog_posts_id_seq'::regclass);


--
-- Name: campaigns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns ALTER COLUMN id SET DEFAULT nextval('public.campaigns_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: contact_info id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_info ALTER COLUMN id SET DEFAULT nextval('public.contact_info_id_seq'::regclass);


--
-- Name: cookie_rows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cookie_rows ALTER COLUMN id SET DEFAULT nextval('public.cookie_rows_id_seq'::regclass);


--
-- Name: documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents ALTER COLUMN id SET DEFAULT nextval('public.documents_id_seq'::regclass);


--
-- Name: faq_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faq_items ALTER COLUMN id SET DEFAULT nextval('public.faq_items_id_seq'::regclass);


--
-- Name: fee_rows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fee_rows ALTER COLUMN id SET DEFAULT nextval('public.fee_rows_id_seq'::regclass);


--
-- Name: feedback id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback ALTER COLUMN id SET DEFAULT nextval('public.feedback_id_seq'::regclass);


--
-- Name: legal_pages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legal_pages ALTER COLUMN id SET DEFAULT nextval('public.legal_pages_id_seq'::regclass);


--
-- Name: limit_tables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.limit_tables ALTER COLUMN id SET DEFAULT nextval('public.limit_tables_id_seq'::regclass);


--
-- Name: media id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media ALTER COLUMN id SET DEFAULT nextval('public.media_id_seq'::regclass);


--
-- Name: nav_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nav_links ALTER COLUMN id SET DEFAULT nextval('public.nav_links_id_seq'::regclass);


--
-- Name: page_meta id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_meta ALTER COLUMN id SET DEFAULT nextval('public.page_meta_id_seq'::regclass);


--
-- Name: pages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages ALTER COLUMN id SET DEFAULT nextval('public.pages_id_seq'::regclass);


--
-- Name: payload_kv id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_kv ALTER COLUMN id SET DEFAULT nextval('public.payload_kv_id_seq'::regclass);


--
-- Name: payload_locked_documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents ALTER COLUMN id SET DEFAULT nextval('public.payload_locked_documents_id_seq'::regclass);


--
-- Name: payload_locked_documents_rels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels ALTER COLUMN id SET DEFAULT nextval('public.payload_locked_documents_rels_id_seq'::regclass);


--
-- Name: payload_migrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_migrations ALTER COLUMN id SET DEFAULT nextval('public.payload_migrations_id_seq'::regclass);


--
-- Name: payload_preferences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_preferences ALTER COLUMN id SET DEFAULT nextval('public.payload_preferences_id_seq'::regclass);


--
-- Name: payload_preferences_rels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_preferences_rels ALTER COLUMN id SET DEFAULT nextval('public.payload_preferences_rels_id_seq'::regclass);


--
-- Name: representatives id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.representatives ALTER COLUMN id SET DEFAULT nextval('public.representatives_id_seq'::regclass);


--
-- Name: translations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.translations ALTER COLUMN id SET DEFAULT nextval('public.translations_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: _announcements_v _announcements_v_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._announcements_v
    ADD CONSTRAINT _announcements_v_pkey PRIMARY KEY (id);


--
-- Name: _blog_posts_v _blog_posts_v_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._blog_posts_v
    ADD CONSTRAINT _blog_posts_v_pkey PRIMARY KEY (id);


--
-- Name: _campaigns_v _campaigns_v_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._campaigns_v
    ADD CONSTRAINT _campaigns_v_pkey PRIMARY KEY (id);


--
-- Name: _categories_v _categories_v_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._categories_v
    ADD CONSTRAINT _categories_v_pkey PRIMARY KEY (id);


--
-- Name: _cookie_rows_v _cookie_rows_v_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._cookie_rows_v
    ADD CONSTRAINT _cookie_rows_v_pkey PRIMARY KEY (id);


--
-- Name: _documents_v _documents_v_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._documents_v
    ADD CONSTRAINT _documents_v_pkey PRIMARY KEY (id);


--
-- Name: _faq_items_v _faq_items_v_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._faq_items_v
    ADD CONSTRAINT _faq_items_v_pkey PRIMARY KEY (id);


--
-- Name: _fee_rows_v _fee_rows_v_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._fee_rows_v
    ADD CONSTRAINT _fee_rows_v_pkey PRIMARY KEY (id);


--
-- Name: _legal_pages_v _legal_pages_v_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._legal_pages_v
    ADD CONSTRAINT _legal_pages_v_pkey PRIMARY KEY (id);


--
-- Name: _legal_pages_v_version_groups_documents _legal_pages_v_version_groups_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._legal_pages_v_version_groups_documents
    ADD CONSTRAINT _legal_pages_v_version_groups_documents_pkey PRIMARY KEY (id);


--
-- Name: _legal_pages_v_version_groups _legal_pages_v_version_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._legal_pages_v_version_groups
    ADD CONSTRAINT _legal_pages_v_version_groups_pkey PRIMARY KEY (id);


--
-- Name: _limit_tables_v _limit_tables_v_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._limit_tables_v
    ADD CONSTRAINT _limit_tables_v_pkey PRIMARY KEY (id);


--
-- Name: _limit_tables_v_version_rows _limit_tables_v_version_rows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._limit_tables_v_version_rows
    ADD CONSTRAINT _limit_tables_v_version_rows_pkey PRIMARY KEY (id);


--
-- Name: _nav_links_v _nav_links_v_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._nav_links_v
    ADD CONSTRAINT _nav_links_v_pkey PRIMARY KEY (id);


--
-- Name: _page_meta_v _page_meta_v_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._page_meta_v
    ADD CONSTRAINT _page_meta_v_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_blog_grid _pages_v_blocks_blog_grid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_blog_grid
    ADD CONSTRAINT _pages_v_blocks_blog_grid_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_campaign_grid _pages_v_blocks_campaign_grid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_campaign_grid
    ADD CONSTRAINT _pages_v_blocks_campaign_grid_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_contact_info _pages_v_blocks_contact_info_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_contact_info
    ADD CONSTRAINT _pages_v_blocks_contact_info_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_faq_list _pages_v_blocks_faq_list_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_faq_list
    ADD CONSTRAINT _pages_v_blocks_faq_list_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_feature_highlights_features _pages_v_blocks_feature_highlights_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_feature_highlights_features
    ADD CONSTRAINT _pages_v_blocks_feature_highlights_features_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_feature_highlights _pages_v_blocks_feature_highlights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_feature_highlights
    ADD CONSTRAINT _pages_v_blocks_feature_highlights_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_hero _pages_v_blocks_hero_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_hero
    ADD CONSTRAINT _pages_v_blocks_hero_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_how_to_earn _pages_v_blocks_how_to_earn_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_how_to_earn
    ADD CONSTRAINT _pages_v_blocks_how_to_earn_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_how_to_earn_steps _pages_v_blocks_how_to_earn_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_how_to_earn_steps
    ADD CONSTRAINT _pages_v_blocks_how_to_earn_steps_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_icon_cards_cards _pages_v_blocks_icon_cards_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_icon_cards_cards
    ADD CONSTRAINT _pages_v_blocks_icon_cards_cards_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_icon_cards _pages_v_blocks_icon_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_icon_cards
    ADD CONSTRAINT _pages_v_blocks_icon_cards_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_image_text_slides _pages_v_blocks_image_text_slides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_image_text_slides
    ADD CONSTRAINT _pages_v_blocks_image_text_slides_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_image_text_slides_slides _pages_v_blocks_image_text_slides_slides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_image_text_slides_slides
    ADD CONSTRAINT _pages_v_blocks_image_text_slides_slides_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_image_with_text _pages_v_blocks_image_with_text_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_image_with_text
    ADD CONSTRAINT _pages_v_blocks_image_with_text_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_lead_form_cta _pages_v_blocks_lead_form_cta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_lead_form_cta
    ADD CONSTRAINT _pages_v_blocks_lead_form_cta_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_logo_grid_logos _pages_v_blocks_logo_grid_logos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_logo_grid_logos
    ADD CONSTRAINT _pages_v_blocks_logo_grid_logos_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_logo_grid _pages_v_blocks_logo_grid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_logo_grid
    ADD CONSTRAINT _pages_v_blocks_logo_grid_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_media_panel _pages_v_blocks_media_panel_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_media_panel
    ADD CONSTRAINT _pages_v_blocks_media_panel_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_prices_and_limits _pages_v_blocks_prices_and_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_prices_and_limits
    ADD CONSTRAINT _pages_v_blocks_prices_and_limits_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_profile_grid_people _pages_v_blocks_profile_grid_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_profile_grid_people
    ADD CONSTRAINT _pages_v_blocks_profile_grid_people_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_profile_grid _pages_v_blocks_profile_grid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_profile_grid
    ADD CONSTRAINT _pages_v_blocks_profile_grid_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_representatives _pages_v_blocks_representatives_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_representatives
    ADD CONSTRAINT _pages_v_blocks_representatives_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_rich_text _pages_v_blocks_rich_text_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_rich_text
    ADD CONSTRAINT _pages_v_blocks_rich_text_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_step_phones _pages_v_blocks_step_phones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_step_phones
    ADD CONSTRAINT _pages_v_blocks_step_phones_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_step_phones_steps _pages_v_blocks_step_phones_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_step_phones_steps
    ADD CONSTRAINT _pages_v_blocks_step_phones_steps_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_steps _pages_v_blocks_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_steps
    ADD CONSTRAINT _pages_v_blocks_steps_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_steps_steps _pages_v_blocks_steps_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_steps_steps
    ADD CONSTRAINT _pages_v_blocks_steps_steps_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_video_list _pages_v_blocks_video_list_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_video_list
    ADD CONSTRAINT _pages_v_blocks_video_list_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_video_list_videos _pages_v_blocks_video_list_videos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_video_list_videos
    ADD CONSTRAINT _pages_v_blocks_video_list_videos_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_video _pages_v_blocks_video_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_video
    ADD CONSTRAINT _pages_v_blocks_video_pkey PRIMARY KEY (id);


--
-- Name: _pages_v_blocks_videos_with_tabs_marker _pages_v_blocks_videos_with_tabs_marker_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_videos_with_tabs_marker
    ADD CONSTRAINT _pages_v_blocks_videos_with_tabs_marker_pkey PRIMARY KEY (id);


--
-- Name: _pages_v _pages_v_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v
    ADD CONSTRAINT _pages_v_pkey PRIMARY KEY (id);


--
-- Name: _representatives_v _representatives_v_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._representatives_v
    ADD CONSTRAINT _representatives_v_pkey PRIMARY KEY (id);


--
-- Name: announcements announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_pkey PRIMARY KEY (id);


--
-- Name: audit_logs_changes audit_logs_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs_changes
    ADD CONSTRAINT audit_logs_changes_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: blog_posts blog_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blog_posts
    ADD CONSTRAINT blog_posts_pkey PRIMARY KEY (id);


--
-- Name: campaigns campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: contact_info contact_info_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_info
    ADD CONSTRAINT contact_info_pkey PRIMARY KEY (id);


--
-- Name: cookie_rows cookie_rows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cookie_rows
    ADD CONSTRAINT cookie_rows_pkey PRIMARY KEY (id);


--
-- Name: documents documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- Name: faq_items faq_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faq_items
    ADD CONSTRAINT faq_items_pkey PRIMARY KEY (id);


--
-- Name: fee_rows fee_rows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fee_rows
    ADD CONSTRAINT fee_rows_pkey PRIMARY KEY (id);


--
-- Name: feedback feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_pkey PRIMARY KEY (id);


--
-- Name: legal_pages_groups_documents legal_pages_groups_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legal_pages_groups_documents
    ADD CONSTRAINT legal_pages_groups_documents_pkey PRIMARY KEY (id);


--
-- Name: legal_pages_groups legal_pages_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legal_pages_groups
    ADD CONSTRAINT legal_pages_groups_pkey PRIMARY KEY (id);


--
-- Name: legal_pages legal_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legal_pages
    ADD CONSTRAINT legal_pages_pkey PRIMARY KEY (id);


--
-- Name: limit_tables limit_tables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.limit_tables
    ADD CONSTRAINT limit_tables_pkey PRIMARY KEY (id);


--
-- Name: limit_tables_rows limit_tables_rows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.limit_tables_rows
    ADD CONSTRAINT limit_tables_rows_pkey PRIMARY KEY (id);


--
-- Name: media media_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_pkey PRIMARY KEY (id);


--
-- Name: nav_links nav_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nav_links
    ADD CONSTRAINT nav_links_pkey PRIMARY KEY (id);


--
-- Name: page_meta page_meta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_meta
    ADD CONSTRAINT page_meta_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_blog_grid pages_blocks_blog_grid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_blog_grid
    ADD CONSTRAINT pages_blocks_blog_grid_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_campaign_grid pages_blocks_campaign_grid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_campaign_grid
    ADD CONSTRAINT pages_blocks_campaign_grid_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_contact_info pages_blocks_contact_info_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_contact_info
    ADD CONSTRAINT pages_blocks_contact_info_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_faq_list pages_blocks_faq_list_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_faq_list
    ADD CONSTRAINT pages_blocks_faq_list_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_feature_highlights_features pages_blocks_feature_highlights_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_feature_highlights_features
    ADD CONSTRAINT pages_blocks_feature_highlights_features_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_feature_highlights pages_blocks_feature_highlights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_feature_highlights
    ADD CONSTRAINT pages_blocks_feature_highlights_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_hero pages_blocks_hero_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_hero
    ADD CONSTRAINT pages_blocks_hero_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_how_to_earn pages_blocks_how_to_earn_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_how_to_earn
    ADD CONSTRAINT pages_blocks_how_to_earn_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_how_to_earn_steps pages_blocks_how_to_earn_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_how_to_earn_steps
    ADD CONSTRAINT pages_blocks_how_to_earn_steps_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_icon_cards_cards pages_blocks_icon_cards_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_icon_cards_cards
    ADD CONSTRAINT pages_blocks_icon_cards_cards_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_icon_cards pages_blocks_icon_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_icon_cards
    ADD CONSTRAINT pages_blocks_icon_cards_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_image_text_slides pages_blocks_image_text_slides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_image_text_slides
    ADD CONSTRAINT pages_blocks_image_text_slides_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_image_text_slides_slides pages_blocks_image_text_slides_slides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_image_text_slides_slides
    ADD CONSTRAINT pages_blocks_image_text_slides_slides_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_image_with_text pages_blocks_image_with_text_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_image_with_text
    ADD CONSTRAINT pages_blocks_image_with_text_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_lead_form_cta pages_blocks_lead_form_cta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_lead_form_cta
    ADD CONSTRAINT pages_blocks_lead_form_cta_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_logo_grid_logos pages_blocks_logo_grid_logos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_logo_grid_logos
    ADD CONSTRAINT pages_blocks_logo_grid_logos_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_logo_grid pages_blocks_logo_grid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_logo_grid
    ADD CONSTRAINT pages_blocks_logo_grid_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_media_panel pages_blocks_media_panel_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_media_panel
    ADD CONSTRAINT pages_blocks_media_panel_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_prices_and_limits pages_blocks_prices_and_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_prices_and_limits
    ADD CONSTRAINT pages_blocks_prices_and_limits_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_profile_grid_people pages_blocks_profile_grid_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_profile_grid_people
    ADD CONSTRAINT pages_blocks_profile_grid_people_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_profile_grid pages_blocks_profile_grid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_profile_grid
    ADD CONSTRAINT pages_blocks_profile_grid_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_representatives pages_blocks_representatives_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_representatives
    ADD CONSTRAINT pages_blocks_representatives_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_rich_text pages_blocks_rich_text_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_rich_text
    ADD CONSTRAINT pages_blocks_rich_text_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_step_phones pages_blocks_step_phones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_step_phones
    ADD CONSTRAINT pages_blocks_step_phones_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_step_phones_steps pages_blocks_step_phones_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_step_phones_steps
    ADD CONSTRAINT pages_blocks_step_phones_steps_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_steps pages_blocks_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_steps
    ADD CONSTRAINT pages_blocks_steps_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_steps_steps pages_blocks_steps_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_steps_steps
    ADD CONSTRAINT pages_blocks_steps_steps_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_video_list pages_blocks_video_list_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_video_list
    ADD CONSTRAINT pages_blocks_video_list_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_video_list_videos pages_blocks_video_list_videos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_video_list_videos
    ADD CONSTRAINT pages_blocks_video_list_videos_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_video pages_blocks_video_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_video
    ADD CONSTRAINT pages_blocks_video_pkey PRIMARY KEY (id);


--
-- Name: pages_blocks_videos_with_tabs_marker pages_blocks_videos_with_tabs_marker_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_videos_with_tabs_marker
    ADD CONSTRAINT pages_blocks_videos_with_tabs_marker_pkey PRIMARY KEY (id);


--
-- Name: pages pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_pkey PRIMARY KEY (id);


--
-- Name: payload_kv payload_kv_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_kv
    ADD CONSTRAINT payload_kv_pkey PRIMARY KEY (id);


--
-- Name: payload_locked_documents payload_locked_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents
    ADD CONSTRAINT payload_locked_documents_pkey PRIMARY KEY (id);


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_pkey PRIMARY KEY (id);


--
-- Name: payload_migrations payload_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_migrations
    ADD CONSTRAINT payload_migrations_pkey PRIMARY KEY (id);


--
-- Name: payload_preferences payload_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_preferences
    ADD CONSTRAINT payload_preferences_pkey PRIMARY KEY (id);


--
-- Name: payload_preferences_rels payload_preferences_rels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_preferences_rels
    ADD CONSTRAINT payload_preferences_rels_pkey PRIMARY KEY (id);


--
-- Name: representatives representatives_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.representatives
    ADD CONSTRAINT representatives_pkey PRIMARY KEY (id);


--
-- Name: translations translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.translations
    ADD CONSTRAINT translations_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_sessions users_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_sessions
    ADD CONSTRAINT users_sessions_pkey PRIMARY KEY (id);


--
-- Name: _announcements_v_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _announcements_v_created_at_idx ON public._announcements_v USING btree (created_at);


--
-- Name: _announcements_v_latest_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _announcements_v_latest_idx ON public._announcements_v USING btree (latest);


--
-- Name: _announcements_v_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _announcements_v_parent_idx ON public._announcements_v USING btree (parent_id);


--
-- Name: _announcements_v_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _announcements_v_updated_at_idx ON public._announcements_v USING btree (updated_at);


--
-- Name: _announcements_v_version_version__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _announcements_v_version_version__status_idx ON public._announcements_v USING btree (version__status);


--
-- Name: _announcements_v_version_version_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _announcements_v_version_version_created_at_idx ON public._announcements_v USING btree (version_created_at);


--
-- Name: _announcements_v_version_version_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _announcements_v_version_version_created_by_idx ON public._announcements_v USING btree (version_created_by_id);


--
-- Name: _announcements_v_version_version_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _announcements_v_version_version_updated_at_idx ON public._announcements_v USING btree (version_updated_at);


--
-- Name: _blog_posts_v_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _blog_posts_v_created_at_idx ON public._blog_posts_v USING btree (created_at);


--
-- Name: _blog_posts_v_latest_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _blog_posts_v_latest_idx ON public._blog_posts_v USING btree (latest);


--
-- Name: _blog_posts_v_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _blog_posts_v_parent_idx ON public._blog_posts_v USING btree (parent_id);


--
-- Name: _blog_posts_v_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _blog_posts_v_updated_at_idx ON public._blog_posts_v USING btree (updated_at);


--
-- Name: _blog_posts_v_version_version__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _blog_posts_v_version_version__status_idx ON public._blog_posts_v USING btree (version__status);


--
-- Name: _blog_posts_v_version_version_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _blog_posts_v_version_version_category_idx ON public._blog_posts_v USING btree (version_category_id);


--
-- Name: _blog_posts_v_version_version_cover_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _blog_posts_v_version_version_cover_image_idx ON public._blog_posts_v USING btree (version_cover_image_id);


--
-- Name: _blog_posts_v_version_version_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _blog_posts_v_version_version_created_at_idx ON public._blog_posts_v USING btree (version_created_at);


--
-- Name: _blog_posts_v_version_version_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _blog_posts_v_version_version_created_by_idx ON public._blog_posts_v USING btree (version_created_by_id);


--
-- Name: _blog_posts_v_version_version_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _blog_posts_v_version_version_slug_idx ON public._blog_posts_v USING btree (version_slug);


--
-- Name: _blog_posts_v_version_version_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _blog_posts_v_version_version_updated_at_idx ON public._blog_posts_v USING btree (version_updated_at);


--
-- Name: _campaigns_v_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _campaigns_v_created_at_idx ON public._campaigns_v USING btree (created_at);


--
-- Name: _campaigns_v_latest_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _campaigns_v_latest_idx ON public._campaigns_v USING btree (latest);


--
-- Name: _campaigns_v_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _campaigns_v_parent_idx ON public._campaigns_v USING btree (parent_id);


--
-- Name: _campaigns_v_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _campaigns_v_updated_at_idx ON public._campaigns_v USING btree (updated_at);


--
-- Name: _campaigns_v_version_version__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _campaigns_v_version_version__status_idx ON public._campaigns_v USING btree (version__status);


--
-- Name: _campaigns_v_version_version_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _campaigns_v_version_version_category_idx ON public._campaigns_v USING btree (version_category_id);


--
-- Name: _campaigns_v_version_version_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _campaigns_v_version_version_created_at_idx ON public._campaigns_v USING btree (version_created_at);


--
-- Name: _campaigns_v_version_version_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _campaigns_v_version_version_created_by_idx ON public._campaigns_v USING btree (version_created_by_id);


--
-- Name: _campaigns_v_version_version_footer_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _campaigns_v_version_version_footer_order_idx ON public._campaigns_v USING btree (version_footer_order);


--
-- Name: _campaigns_v_version_version_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _campaigns_v_version_version_image_idx ON public._campaigns_v USING btree (version_image_id);


--
-- Name: _campaigns_v_version_version_rejected_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _campaigns_v_version_version_rejected_by_idx ON public._campaigns_v USING btree (version_rejected_by_id);


--
-- Name: _campaigns_v_version_version_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _campaigns_v_version_version_slug_idx ON public._campaigns_v USING btree (version_slug);


--
-- Name: _campaigns_v_version_version_unpublish_requested_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _campaigns_v_version_version_unpublish_requested_by_idx ON public._campaigns_v USING btree (version_unpublish_requested_by_id);


--
-- Name: _campaigns_v_version_version_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _campaigns_v_version_version_updated_at_idx ON public._campaigns_v USING btree (version_updated_at);


--
-- Name: _categories_v_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _categories_v_created_at_idx ON public._categories_v USING btree (created_at);


--
-- Name: _categories_v_latest_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _categories_v_latest_idx ON public._categories_v USING btree (latest);


--
-- Name: _categories_v_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _categories_v_parent_idx ON public._categories_v USING btree (parent_id);


--
-- Name: _categories_v_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _categories_v_updated_at_idx ON public._categories_v USING btree (updated_at);


--
-- Name: _categories_v_version_version_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _categories_v_version_version_created_at_idx ON public._categories_v USING btree (version_created_at);


--
-- Name: _categories_v_version_version_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _categories_v_version_version_created_by_idx ON public._categories_v USING btree (version_created_by_id);


--
-- Name: _categories_v_version_version_scope_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _categories_v_version_version_scope_idx ON public._categories_v USING btree (version_scope);


--
-- Name: _categories_v_version_version_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _categories_v_version_version_status_idx ON public._categories_v USING btree (version__status);


--
-- Name: _categories_v_version_version_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _categories_v_version_version_updated_at_idx ON public._categories_v USING btree (version_updated_at);


--
-- Name: _cookie_rows_v_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _cookie_rows_v_created_at_idx ON public._cookie_rows_v USING btree (created_at);


--
-- Name: _cookie_rows_v_latest_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _cookie_rows_v_latest_idx ON public._cookie_rows_v USING btree (latest);


--
-- Name: _cookie_rows_v_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _cookie_rows_v_parent_idx ON public._cookie_rows_v USING btree (parent_id);


--
-- Name: _cookie_rows_v_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _cookie_rows_v_updated_at_idx ON public._cookie_rows_v USING btree (updated_at);


--
-- Name: _cookie_rows_v_version_version__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _cookie_rows_v_version_version__status_idx ON public._cookie_rows_v USING btree (version__status);


--
-- Name: _cookie_rows_v_version_version_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _cookie_rows_v_version_version_created_at_idx ON public._cookie_rows_v USING btree (version_created_at);


--
-- Name: _cookie_rows_v_version_version_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _cookie_rows_v_version_version_created_by_idx ON public._cookie_rows_v USING btree (version_created_by_id);


--
-- Name: _cookie_rows_v_version_version_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _cookie_rows_v_version_version_updated_at_idx ON public._cookie_rows_v USING btree (version_updated_at);


--
-- Name: _documents_v_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _documents_v_created_at_idx ON public._documents_v USING btree (created_at);


--
-- Name: _documents_v_latest_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _documents_v_latest_idx ON public._documents_v USING btree (latest);


--
-- Name: _documents_v_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _documents_v_parent_idx ON public._documents_v USING btree (parent_id);


--
-- Name: _documents_v_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _documents_v_updated_at_idx ON public._documents_v USING btree (updated_at);


--
-- Name: _documents_v_version_version_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _documents_v_version_version_created_at_idx ON public._documents_v USING btree (version_created_at);


--
-- Name: _documents_v_version_version_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _documents_v_version_version_created_by_idx ON public._documents_v USING btree (version_created_by_id);


--
-- Name: _documents_v_version_version_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _documents_v_version_version_status_idx ON public._documents_v USING btree (version__status);


--
-- Name: _documents_v_version_version_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _documents_v_version_version_updated_at_idx ON public._documents_v USING btree (version_updated_at);


--
-- Name: _faq_items_v_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _faq_items_v_created_at_idx ON public._faq_items_v USING btree (created_at);


--
-- Name: _faq_items_v_latest_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _faq_items_v_latest_idx ON public._faq_items_v USING btree (latest);


--
-- Name: _faq_items_v_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _faq_items_v_parent_idx ON public._faq_items_v USING btree (parent_id);


--
-- Name: _faq_items_v_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _faq_items_v_updated_at_idx ON public._faq_items_v USING btree (updated_at);


--
-- Name: _faq_items_v_version_version__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _faq_items_v_version_version__status_idx ON public._faq_items_v USING btree (version__status);


--
-- Name: _faq_items_v_version_version_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _faq_items_v_version_version_category_idx ON public._faq_items_v USING btree (version_category_id);


--
-- Name: _faq_items_v_version_version_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _faq_items_v_version_version_created_at_idx ON public._faq_items_v USING btree (version_created_at);


--
-- Name: _faq_items_v_version_version_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _faq_items_v_version_version_created_by_idx ON public._faq_items_v USING btree (version_created_by_id);


--
-- Name: _faq_items_v_version_version_footer_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _faq_items_v_version_version_footer_order_idx ON public._faq_items_v USING btree (version_footer_order);


--
-- Name: _faq_items_v_version_version_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _faq_items_v_version_version_updated_at_idx ON public._faq_items_v USING btree (version_updated_at);


--
-- Name: _fee_rows_v_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _fee_rows_v_created_at_idx ON public._fee_rows_v USING btree (created_at);


--
-- Name: _fee_rows_v_latest_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _fee_rows_v_latest_idx ON public._fee_rows_v USING btree (latest);


--
-- Name: _fee_rows_v_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _fee_rows_v_parent_idx ON public._fee_rows_v USING btree (parent_id);


--
-- Name: _fee_rows_v_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _fee_rows_v_updated_at_idx ON public._fee_rows_v USING btree (updated_at);


--
-- Name: _fee_rows_v_version_version__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _fee_rows_v_version_version__status_idx ON public._fee_rows_v USING btree (version__status);


--
-- Name: _fee_rows_v_version_version_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _fee_rows_v_version_version_created_at_idx ON public._fee_rows_v USING btree (version_created_at);


--
-- Name: _fee_rows_v_version_version_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _fee_rows_v_version_version_created_by_idx ON public._fee_rows_v USING btree (version_created_by_id);


--
-- Name: _fee_rows_v_version_version_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _fee_rows_v_version_version_updated_at_idx ON public._fee_rows_v USING btree (version_updated_at);


--
-- Name: _legal_pages_v_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _legal_pages_v_created_at_idx ON public._legal_pages_v USING btree (created_at);


--
-- Name: _legal_pages_v_latest_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _legal_pages_v_latest_idx ON public._legal_pages_v USING btree (latest);


--
-- Name: _legal_pages_v_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _legal_pages_v_parent_idx ON public._legal_pages_v USING btree (parent_id);


--
-- Name: _legal_pages_v_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _legal_pages_v_updated_at_idx ON public._legal_pages_v USING btree (updated_at);


--
-- Name: _legal_pages_v_version_groups_documents_file_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _legal_pages_v_version_groups_documents_file_idx ON public._legal_pages_v_version_groups_documents USING btree (file_id);


--
-- Name: _legal_pages_v_version_groups_documents_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _legal_pages_v_version_groups_documents_order_idx ON public._legal_pages_v_version_groups_documents USING btree (_order);


--
-- Name: _legal_pages_v_version_groups_documents_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _legal_pages_v_version_groups_documents_parent_id_idx ON public._legal_pages_v_version_groups_documents USING btree (_parent_id);


--
-- Name: _legal_pages_v_version_groups_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _legal_pages_v_version_groups_order_idx ON public._legal_pages_v_version_groups USING btree (_order);


--
-- Name: _legal_pages_v_version_groups_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _legal_pages_v_version_groups_parent_id_idx ON public._legal_pages_v_version_groups USING btree (_parent_id);


--
-- Name: _legal_pages_v_version_version__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _legal_pages_v_version_version__status_idx ON public._legal_pages_v USING btree (version__status);


--
-- Name: _legal_pages_v_version_version_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _legal_pages_v_version_version_created_at_idx ON public._legal_pages_v USING btree (version_created_at);


--
-- Name: _legal_pages_v_version_version_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _legal_pages_v_version_version_created_by_idx ON public._legal_pages_v USING btree (version_created_by_id);


--
-- Name: _legal_pages_v_version_version_hero_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _legal_pages_v_version_version_hero_image_idx ON public._legal_pages_v USING btree (version_hero_image_id);


--
-- Name: _legal_pages_v_version_version_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _legal_pages_v_version_version_slug_idx ON public._legal_pages_v USING btree (version_slug);


--
-- Name: _legal_pages_v_version_version_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _legal_pages_v_version_version_updated_at_idx ON public._legal_pages_v USING btree (version_updated_at);


--
-- Name: _limit_tables_v_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _limit_tables_v_created_at_idx ON public._limit_tables_v USING btree (created_at);


--
-- Name: _limit_tables_v_latest_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _limit_tables_v_latest_idx ON public._limit_tables_v USING btree (latest);


--
-- Name: _limit_tables_v_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _limit_tables_v_parent_idx ON public._limit_tables_v USING btree (parent_id);


--
-- Name: _limit_tables_v_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _limit_tables_v_updated_at_idx ON public._limit_tables_v USING btree (updated_at);


--
-- Name: _limit_tables_v_version_rows_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _limit_tables_v_version_rows_order_idx ON public._limit_tables_v_version_rows USING btree (_order);


--
-- Name: _limit_tables_v_version_rows_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _limit_tables_v_version_rows_parent_id_idx ON public._limit_tables_v_version_rows USING btree (_parent_id);


--
-- Name: _limit_tables_v_version_version__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _limit_tables_v_version_version__status_idx ON public._limit_tables_v USING btree (version__status);


--
-- Name: _limit_tables_v_version_version_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _limit_tables_v_version_version_created_at_idx ON public._limit_tables_v USING btree (version_created_at);


--
-- Name: _limit_tables_v_version_version_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _limit_tables_v_version_version_created_by_idx ON public._limit_tables_v USING btree (version_created_by_id);


--
-- Name: _limit_tables_v_version_version_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _limit_tables_v_version_version_updated_at_idx ON public._limit_tables_v USING btree (version_updated_at);


--
-- Name: _nav_links_v_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _nav_links_v_created_at_idx ON public._nav_links_v USING btree (created_at);


--
-- Name: _nav_links_v_latest_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _nav_links_v_latest_idx ON public._nav_links_v USING btree (latest);


--
-- Name: _nav_links_v_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _nav_links_v_parent_idx ON public._nav_links_v USING btree (parent_id);


--
-- Name: _nav_links_v_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _nav_links_v_updated_at_idx ON public._nav_links_v USING btree (updated_at);


--
-- Name: _nav_links_v_version_version__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _nav_links_v_version_version__status_idx ON public._nav_links_v USING btree (version__status);


--
-- Name: _nav_links_v_version_version_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _nav_links_v_version_version_created_at_idx ON public._nav_links_v USING btree (version_created_at);


--
-- Name: _nav_links_v_version_version_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _nav_links_v_version_version_created_by_idx ON public._nav_links_v USING btree (version_created_by_id);


--
-- Name: _nav_links_v_version_version_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _nav_links_v_version_version_updated_at_idx ON public._nav_links_v USING btree (version_updated_at);


--
-- Name: _page_meta_v_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _page_meta_v_created_at_idx ON public._page_meta_v USING btree (created_at);


--
-- Name: _page_meta_v_latest_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _page_meta_v_latest_idx ON public._page_meta_v USING btree (latest);


--
-- Name: _page_meta_v_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _page_meta_v_parent_idx ON public._page_meta_v USING btree (parent_id);


--
-- Name: _page_meta_v_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _page_meta_v_updated_at_idx ON public._page_meta_v USING btree (updated_at);


--
-- Name: _page_meta_v_version_version__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _page_meta_v_version_version__status_idx ON public._page_meta_v USING btree (version__status);


--
-- Name: _page_meta_v_version_version_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _page_meta_v_version_version_created_at_idx ON public._page_meta_v USING btree (version_created_at);


--
-- Name: _page_meta_v_version_version_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _page_meta_v_version_version_created_by_idx ON public._page_meta_v USING btree (version_created_by_id);


--
-- Name: _page_meta_v_version_version_og_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _page_meta_v_version_version_og_image_idx ON public._page_meta_v USING btree (version_og_image_id);


--
-- Name: _page_meta_v_version_version_page_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _page_meta_v_version_version_page_key_idx ON public._page_meta_v USING btree (version_page_key);


--
-- Name: _page_meta_v_version_version_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _page_meta_v_version_version_updated_at_idx ON public._page_meta_v USING btree (version_updated_at);


--
-- Name: _pages_v_blocks_blog_grid_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_blog_grid_order_idx ON public._pages_v_blocks_blog_grid USING btree (_order);


--
-- Name: _pages_v_blocks_blog_grid_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_blog_grid_parent_id_idx ON public._pages_v_blocks_blog_grid USING btree (_parent_id);


--
-- Name: _pages_v_blocks_blog_grid_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_blog_grid_path_idx ON public._pages_v_blocks_blog_grid USING btree (_path);


--
-- Name: _pages_v_blocks_campaign_grid_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_campaign_grid_order_idx ON public._pages_v_blocks_campaign_grid USING btree (_order);


--
-- Name: _pages_v_blocks_campaign_grid_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_campaign_grid_parent_id_idx ON public._pages_v_blocks_campaign_grid USING btree (_parent_id);


--
-- Name: _pages_v_blocks_campaign_grid_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_campaign_grid_path_idx ON public._pages_v_blocks_campaign_grid USING btree (_path);


--
-- Name: _pages_v_blocks_contact_info_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_contact_info_order_idx ON public._pages_v_blocks_contact_info USING btree (_order);


--
-- Name: _pages_v_blocks_contact_info_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_contact_info_parent_id_idx ON public._pages_v_blocks_contact_info USING btree (_parent_id);


--
-- Name: _pages_v_blocks_contact_info_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_contact_info_path_idx ON public._pages_v_blocks_contact_info USING btree (_path);


--
-- Name: _pages_v_blocks_faq_list_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_faq_list_order_idx ON public._pages_v_blocks_faq_list USING btree (_order);


--
-- Name: _pages_v_blocks_faq_list_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_faq_list_parent_id_idx ON public._pages_v_blocks_faq_list USING btree (_parent_id);


--
-- Name: _pages_v_blocks_faq_list_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_faq_list_path_idx ON public._pages_v_blocks_faq_list USING btree (_path);


--
-- Name: _pages_v_blocks_feature_highlights_features_icon_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_feature_highlights_features_icon_idx ON public._pages_v_blocks_feature_highlights_features USING btree (icon_id);


--
-- Name: _pages_v_blocks_feature_highlights_features_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_feature_highlights_features_order_idx ON public._pages_v_blocks_feature_highlights_features USING btree (_order);


--
-- Name: _pages_v_blocks_feature_highlights_features_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_feature_highlights_features_parent_id_idx ON public._pages_v_blocks_feature_highlights_features USING btree (_parent_id);


--
-- Name: _pages_v_blocks_feature_highlights_media_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_feature_highlights_media_idx ON public._pages_v_blocks_feature_highlights USING btree (media_id);


--
-- Name: _pages_v_blocks_feature_highlights_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_feature_highlights_order_idx ON public._pages_v_blocks_feature_highlights USING btree (_order);


--
-- Name: _pages_v_blocks_feature_highlights_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_feature_highlights_parent_id_idx ON public._pages_v_blocks_feature_highlights USING btree (_parent_id);


--
-- Name: _pages_v_blocks_feature_highlights_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_feature_highlights_path_idx ON public._pages_v_blocks_feature_highlights USING btree (_path);


--
-- Name: _pages_v_blocks_hero_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_hero_image_idx ON public._pages_v_blocks_hero USING btree (image_id);


--
-- Name: _pages_v_blocks_hero_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_hero_order_idx ON public._pages_v_blocks_hero USING btree (_order);


--
-- Name: _pages_v_blocks_hero_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_hero_parent_id_idx ON public._pages_v_blocks_hero USING btree (_parent_id);


--
-- Name: _pages_v_blocks_hero_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_hero_path_idx ON public._pages_v_blocks_hero USING btree (_path);


--
-- Name: _pages_v_blocks_how_to_earn_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_how_to_earn_image_idx ON public._pages_v_blocks_how_to_earn USING btree (image_id);


--
-- Name: _pages_v_blocks_how_to_earn_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_how_to_earn_order_idx ON public._pages_v_blocks_how_to_earn USING btree (_order);


--
-- Name: _pages_v_blocks_how_to_earn_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_how_to_earn_parent_id_idx ON public._pages_v_blocks_how_to_earn USING btree (_parent_id);


--
-- Name: _pages_v_blocks_how_to_earn_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_how_to_earn_path_idx ON public._pages_v_blocks_how_to_earn USING btree (_path);


--
-- Name: _pages_v_blocks_how_to_earn_steps_icon_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_how_to_earn_steps_icon_idx ON public._pages_v_blocks_how_to_earn_steps USING btree (icon_id);


--
-- Name: _pages_v_blocks_how_to_earn_steps_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_how_to_earn_steps_order_idx ON public._pages_v_blocks_how_to_earn_steps USING btree (_order);


--
-- Name: _pages_v_blocks_how_to_earn_steps_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_how_to_earn_steps_parent_id_idx ON public._pages_v_blocks_how_to_earn_steps USING btree (_parent_id);


--
-- Name: _pages_v_blocks_icon_cards_cards_icon_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_icon_cards_cards_icon_idx ON public._pages_v_blocks_icon_cards_cards USING btree (icon_id);


--
-- Name: _pages_v_blocks_icon_cards_cards_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_icon_cards_cards_order_idx ON public._pages_v_blocks_icon_cards_cards USING btree (_order);


--
-- Name: _pages_v_blocks_icon_cards_cards_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_icon_cards_cards_parent_id_idx ON public._pages_v_blocks_icon_cards_cards USING btree (_parent_id);


--
-- Name: _pages_v_blocks_icon_cards_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_icon_cards_order_idx ON public._pages_v_blocks_icon_cards USING btree (_order);


--
-- Name: _pages_v_blocks_icon_cards_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_icon_cards_parent_id_idx ON public._pages_v_blocks_icon_cards USING btree (_parent_id);


--
-- Name: _pages_v_blocks_icon_cards_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_icon_cards_path_idx ON public._pages_v_blocks_icon_cards USING btree (_path);


--
-- Name: _pages_v_blocks_image_text_slides_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_image_text_slides_order_idx ON public._pages_v_blocks_image_text_slides USING btree (_order);


--
-- Name: _pages_v_blocks_image_text_slides_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_image_text_slides_parent_id_idx ON public._pages_v_blocks_image_text_slides USING btree (_parent_id);


--
-- Name: _pages_v_blocks_image_text_slides_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_image_text_slides_path_idx ON public._pages_v_blocks_image_text_slides USING btree (_path);


--
-- Name: _pages_v_blocks_image_text_slides_side_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_image_text_slides_side_image_idx ON public._pages_v_blocks_image_text_slides USING btree (side_image_id);


--
-- Name: _pages_v_blocks_image_text_slides_slides_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_image_text_slides_slides_image_idx ON public._pages_v_blocks_image_text_slides_slides USING btree (image_id);


--
-- Name: _pages_v_blocks_image_text_slides_slides_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_image_text_slides_slides_order_idx ON public._pages_v_blocks_image_text_slides_slides USING btree (_order);


--
-- Name: _pages_v_blocks_image_text_slides_slides_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_image_text_slides_slides_parent_id_idx ON public._pages_v_blocks_image_text_slides_slides USING btree (_parent_id);


--
-- Name: _pages_v_blocks_image_with_text_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_image_with_text_image_idx ON public._pages_v_blocks_image_with_text USING btree (image_id);


--
-- Name: _pages_v_blocks_image_with_text_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_image_with_text_order_idx ON public._pages_v_blocks_image_with_text USING btree (_order);


--
-- Name: _pages_v_blocks_image_with_text_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_image_with_text_parent_id_idx ON public._pages_v_blocks_image_with_text USING btree (_parent_id);


--
-- Name: _pages_v_blocks_image_with_text_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_image_with_text_path_idx ON public._pages_v_blocks_image_with_text USING btree (_path);


--
-- Name: _pages_v_blocks_lead_form_cta_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_lead_form_cta_order_idx ON public._pages_v_blocks_lead_form_cta USING btree (_order);


--
-- Name: _pages_v_blocks_lead_form_cta_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_lead_form_cta_parent_id_idx ON public._pages_v_blocks_lead_form_cta USING btree (_parent_id);


--
-- Name: _pages_v_blocks_lead_form_cta_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_lead_form_cta_path_idx ON public._pages_v_blocks_lead_form_cta USING btree (_path);


--
-- Name: _pages_v_blocks_logo_grid_logos_logo_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_logo_grid_logos_logo_idx ON public._pages_v_blocks_logo_grid_logos USING btree (logo_id);


--
-- Name: _pages_v_blocks_logo_grid_logos_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_logo_grid_logos_order_idx ON public._pages_v_blocks_logo_grid_logos USING btree (_order);


--
-- Name: _pages_v_blocks_logo_grid_logos_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_logo_grid_logos_parent_id_idx ON public._pages_v_blocks_logo_grid_logos USING btree (_parent_id);


--
-- Name: _pages_v_blocks_logo_grid_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_logo_grid_order_idx ON public._pages_v_blocks_logo_grid USING btree (_order);


--
-- Name: _pages_v_blocks_logo_grid_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_logo_grid_parent_id_idx ON public._pages_v_blocks_logo_grid USING btree (_parent_id);


--
-- Name: _pages_v_blocks_logo_grid_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_logo_grid_path_idx ON public._pages_v_blocks_logo_grid USING btree (_path);


--
-- Name: _pages_v_blocks_media_panel_background_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_media_panel_background_image_idx ON public._pages_v_blocks_media_panel USING btree (background_image_id);


--
-- Name: _pages_v_blocks_media_panel_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_media_panel_order_idx ON public._pages_v_blocks_media_panel USING btree (_order);


--
-- Name: _pages_v_blocks_media_panel_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_media_panel_parent_id_idx ON public._pages_v_blocks_media_panel USING btree (_parent_id);


--
-- Name: _pages_v_blocks_media_panel_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_media_panel_path_idx ON public._pages_v_blocks_media_panel USING btree (_path);


--
-- Name: _pages_v_blocks_prices_and_limits_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_prices_and_limits_order_idx ON public._pages_v_blocks_prices_and_limits USING btree (_order);


--
-- Name: _pages_v_blocks_prices_and_limits_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_prices_and_limits_parent_id_idx ON public._pages_v_blocks_prices_and_limits USING btree (_parent_id);


--
-- Name: _pages_v_blocks_prices_and_limits_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_prices_and_limits_path_idx ON public._pages_v_blocks_prices_and_limits USING btree (_path);


--
-- Name: _pages_v_blocks_profile_grid_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_profile_grid_order_idx ON public._pages_v_blocks_profile_grid USING btree (_order);


--
-- Name: _pages_v_blocks_profile_grid_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_profile_grid_parent_id_idx ON public._pages_v_blocks_profile_grid USING btree (_parent_id);


--
-- Name: _pages_v_blocks_profile_grid_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_profile_grid_path_idx ON public._pages_v_blocks_profile_grid USING btree (_path);


--
-- Name: _pages_v_blocks_profile_grid_people_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_profile_grid_people_order_idx ON public._pages_v_blocks_profile_grid_people USING btree (_order);


--
-- Name: _pages_v_blocks_profile_grid_people_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_profile_grid_people_parent_id_idx ON public._pages_v_blocks_profile_grid_people USING btree (_parent_id);


--
-- Name: _pages_v_blocks_profile_grid_people_photo_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_profile_grid_people_photo_idx ON public._pages_v_blocks_profile_grid_people USING btree (photo_id);


--
-- Name: _pages_v_blocks_representatives_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_representatives_order_idx ON public._pages_v_blocks_representatives USING btree (_order);


--
-- Name: _pages_v_blocks_representatives_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_representatives_parent_id_idx ON public._pages_v_blocks_representatives USING btree (_parent_id);


--
-- Name: _pages_v_blocks_representatives_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_representatives_path_idx ON public._pages_v_blocks_representatives USING btree (_path);


--
-- Name: _pages_v_blocks_rich_text_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_rich_text_order_idx ON public._pages_v_blocks_rich_text USING btree (_order);


--
-- Name: _pages_v_blocks_rich_text_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_rich_text_parent_id_idx ON public._pages_v_blocks_rich_text USING btree (_parent_id);


--
-- Name: _pages_v_blocks_rich_text_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_rich_text_path_idx ON public._pages_v_blocks_rich_text USING btree (_path);


--
-- Name: _pages_v_blocks_step_phones_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_step_phones_order_idx ON public._pages_v_blocks_step_phones USING btree (_order);


--
-- Name: _pages_v_blocks_step_phones_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_step_phones_parent_id_idx ON public._pages_v_blocks_step_phones USING btree (_parent_id);


--
-- Name: _pages_v_blocks_step_phones_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_step_phones_path_idx ON public._pages_v_blocks_step_phones USING btree (_path);


--
-- Name: _pages_v_blocks_step_phones_steps_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_step_phones_steps_image_idx ON public._pages_v_blocks_step_phones_steps USING btree (image_id);


--
-- Name: _pages_v_blocks_step_phones_steps_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_step_phones_steps_order_idx ON public._pages_v_blocks_step_phones_steps USING btree (_order);


--
-- Name: _pages_v_blocks_step_phones_steps_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_step_phones_steps_parent_id_idx ON public._pages_v_blocks_step_phones_steps USING btree (_parent_id);


--
-- Name: _pages_v_blocks_steps_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_steps_order_idx ON public._pages_v_blocks_steps USING btree (_order);


--
-- Name: _pages_v_blocks_steps_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_steps_parent_id_idx ON public._pages_v_blocks_steps USING btree (_parent_id);


--
-- Name: _pages_v_blocks_steps_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_steps_path_idx ON public._pages_v_blocks_steps USING btree (_path);


--
-- Name: _pages_v_blocks_steps_steps_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_steps_steps_image_idx ON public._pages_v_blocks_steps_steps USING btree (image_id);


--
-- Name: _pages_v_blocks_steps_steps_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_steps_steps_order_idx ON public._pages_v_blocks_steps_steps USING btree (_order);


--
-- Name: _pages_v_blocks_steps_steps_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_steps_steps_parent_id_idx ON public._pages_v_blocks_steps_steps USING btree (_parent_id);


--
-- Name: _pages_v_blocks_video_list_dark_bg_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_video_list_dark_bg_image_idx ON public._pages_v_blocks_video_list USING btree (dark_background_image_id);


--
-- Name: _pages_v_blocks_video_list_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_video_list_order_idx ON public._pages_v_blocks_video_list USING btree (_order);


--
-- Name: _pages_v_blocks_video_list_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_video_list_parent_id_idx ON public._pages_v_blocks_video_list USING btree (_parent_id);


--
-- Name: _pages_v_blocks_video_list_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_video_list_path_idx ON public._pages_v_blocks_video_list USING btree (_path);


--
-- Name: _pages_v_blocks_video_list_videos_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_video_list_videos_order_idx ON public._pages_v_blocks_video_list_videos USING btree (_order);


--
-- Name: _pages_v_blocks_video_list_videos_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_video_list_videos_parent_id_idx ON public._pages_v_blocks_video_list_videos USING btree (_parent_id);


--
-- Name: _pages_v_blocks_video_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_video_order_idx ON public._pages_v_blocks_video USING btree (_order);


--
-- Name: _pages_v_blocks_video_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_video_parent_id_idx ON public._pages_v_blocks_video USING btree (_parent_id);


--
-- Name: _pages_v_blocks_video_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_video_path_idx ON public._pages_v_blocks_video USING btree (_path);


--
-- Name: _pages_v_blocks_videos_with_tabs_marker_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_videos_with_tabs_marker_order_idx ON public._pages_v_blocks_videos_with_tabs_marker USING btree (_order);


--
-- Name: _pages_v_blocks_videos_with_tabs_marker_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_videos_with_tabs_marker_parent_id_idx ON public._pages_v_blocks_videos_with_tabs_marker USING btree (_parent_id);


--
-- Name: _pages_v_blocks_videos_with_tabs_marker_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_blocks_videos_with_tabs_marker_path_idx ON public._pages_v_blocks_videos_with_tabs_marker USING btree (_path);


--
-- Name: _pages_v_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_created_at_idx ON public._pages_v USING btree (created_at);


--
-- Name: _pages_v_latest_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_latest_idx ON public._pages_v USING btree (latest);


--
-- Name: _pages_v_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_parent_idx ON public._pages_v USING btree (parent_id);


--
-- Name: _pages_v_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_updated_at_idx ON public._pages_v USING btree (updated_at);


--
-- Name: _pages_v_version_version__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_version_version__status_idx ON public._pages_v USING btree (version__status);


--
-- Name: _pages_v_version_version_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_version_version_created_at_idx ON public._pages_v USING btree (version_created_at);


--
-- Name: _pages_v_version_version_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_version_version_created_by_idx ON public._pages_v USING btree (version_created_by_id);


--
-- Name: _pages_v_version_version_og_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_version_version_og_image_idx ON public._pages_v USING btree (version_og_image_id);


--
-- Name: _pages_v_version_version_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_version_version_parent_idx ON public._pages_v USING btree (version_parent_id);


--
-- Name: _pages_v_version_version_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_version_version_slug_idx ON public._pages_v USING btree (version_slug);


--
-- Name: _pages_v_version_version_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _pages_v_version_version_updated_at_idx ON public._pages_v USING btree (version_updated_at);


--
-- Name: _representatives_v_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _representatives_v_created_at_idx ON public._representatives_v USING btree (created_at);


--
-- Name: _representatives_v_latest_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _representatives_v_latest_idx ON public._representatives_v USING btree (latest);


--
-- Name: _representatives_v_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _representatives_v_parent_idx ON public._representatives_v USING btree (parent_id);


--
-- Name: _representatives_v_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _representatives_v_updated_at_idx ON public._representatives_v USING btree (updated_at);


--
-- Name: _representatives_v_version_qr_code_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _representatives_v_version_qr_code_idx ON public._representatives_v USING btree (version_qr_code_id);


--
-- Name: _representatives_v_version_version_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _representatives_v_version_version_created_at_idx ON public._representatives_v USING btree (version_created_at);


--
-- Name: _representatives_v_version_version_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _representatives_v_version_version_created_by_idx ON public._representatives_v USING btree (version_created_by_id);


--
-- Name: _representatives_v_version_version_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _representatives_v_version_version_status_idx ON public._representatives_v USING btree (version__status);


--
-- Name: _representatives_v_version_version_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX _representatives_v_version_version_updated_at_idx ON public._representatives_v USING btree (version_updated_at);


--
-- Name: announcements__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX announcements__status_idx ON public.announcements USING btree (_status);


--
-- Name: announcements_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX announcements_created_at_idx ON public.announcements USING btree (created_at);


--
-- Name: announcements_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX announcements_created_by_idx ON public.announcements USING btree (created_by_id);


--
-- Name: announcements_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX announcements_updated_at_idx ON public.announcements USING btree (updated_at);


--
-- Name: audit_logs_changes_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_logs_changes_order_idx ON public.audit_logs_changes USING btree (_order);


--
-- Name: audit_logs_changes_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_logs_changes_parent_id_idx ON public.audit_logs_changes USING btree (_parent_id);


--
-- Name: audit_logs_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_logs_created_at_idx ON public.audit_logs USING btree (created_at);


--
-- Name: audit_logs_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_logs_updated_at_idx ON public.audit_logs USING btree (updated_at);


--
-- Name: blog_posts__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX blog_posts__status_idx ON public.blog_posts USING btree (_status);


--
-- Name: blog_posts_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX blog_posts_category_idx ON public.blog_posts USING btree (category_id);


--
-- Name: blog_posts_cover_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX blog_posts_cover_image_idx ON public.blog_posts USING btree (cover_image_id);


--
-- Name: blog_posts_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX blog_posts_created_at_idx ON public.blog_posts USING btree (created_at);


--
-- Name: blog_posts_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX blog_posts_created_by_idx ON public.blog_posts USING btree (created_by_id);


--
-- Name: blog_posts_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX blog_posts_slug_idx ON public.blog_posts USING btree (slug);


--
-- Name: blog_posts_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX blog_posts_updated_at_idx ON public.blog_posts USING btree (updated_at);


--
-- Name: campaigns__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX campaigns__status_idx ON public.campaigns USING btree (_status);


--
-- Name: campaigns_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX campaigns_category_idx ON public.campaigns USING btree (category_id);


--
-- Name: campaigns_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX campaigns_created_at_idx ON public.campaigns USING btree (created_at);


--
-- Name: campaigns_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX campaigns_created_by_idx ON public.campaigns USING btree (created_by_id);


--
-- Name: campaigns_footer_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX campaigns_footer_order_idx ON public.campaigns USING btree (footer_order);


--
-- Name: campaigns_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX campaigns_image_idx ON public.campaigns USING btree (image_id);


--
-- Name: campaigns_rejected_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX campaigns_rejected_by_idx ON public.campaigns USING btree (rejected_by_id);


--
-- Name: campaigns_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX campaigns_slug_idx ON public.campaigns USING btree (slug);


--
-- Name: campaigns_unpublish_requested_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX campaigns_unpublish_requested_by_idx ON public.campaigns USING btree (unpublish_requested_by_id);


--
-- Name: campaigns_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX campaigns_updated_at_idx ON public.campaigns USING btree (updated_at);


--
-- Name: categories__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX categories__status_idx ON public.categories USING btree (_status);


--
-- Name: categories_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX categories_created_at_idx ON public.categories USING btree (created_at);


--
-- Name: categories_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX categories_created_by_idx ON public.categories USING btree (created_by_id);


--
-- Name: categories_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX categories_updated_at_idx ON public.categories USING btree (updated_at);


--
-- Name: cookie_rows__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cookie_rows__status_idx ON public.cookie_rows USING btree (_status);


--
-- Name: cookie_rows_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cookie_rows_created_at_idx ON public.cookie_rows USING btree (created_at);


--
-- Name: cookie_rows_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cookie_rows_created_by_idx ON public.cookie_rows USING btree (created_by_id);


--
-- Name: cookie_rows_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cookie_rows_updated_at_idx ON public.cookie_rows USING btree (updated_at);


--
-- Name: documents__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX documents__status_idx ON public.documents USING btree (_status);


--
-- Name: documents_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX documents_created_at_idx ON public.documents USING btree (created_at);


--
-- Name: documents_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX documents_created_by_idx ON public.documents USING btree (created_by_id);


--
-- Name: documents_filename_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX documents_filename_idx ON public.documents USING btree (filename);


--
-- Name: documents_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX documents_updated_at_idx ON public.documents USING btree (updated_at);


--
-- Name: faq_items__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX faq_items__status_idx ON public.faq_items USING btree (_status);


--
-- Name: faq_items_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX faq_items_category_idx ON public.faq_items USING btree (category_id);


--
-- Name: faq_items_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX faq_items_created_at_idx ON public.faq_items USING btree (created_at);


--
-- Name: faq_items_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX faq_items_created_by_idx ON public.faq_items USING btree (created_by_id);


--
-- Name: faq_items_footer_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX faq_items_footer_order_idx ON public.faq_items USING btree (footer_order);


--
-- Name: faq_items_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX faq_items_updated_at_idx ON public.faq_items USING btree (updated_at);


--
-- Name: fee_rows__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fee_rows__status_idx ON public.fee_rows USING btree (_status);


--
-- Name: fee_rows_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fee_rows_created_at_idx ON public.fee_rows USING btree (created_at);


--
-- Name: fee_rows_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fee_rows_created_by_idx ON public.fee_rows USING btree (created_by_id);


--
-- Name: fee_rows_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fee_rows_updated_at_idx ON public.fee_rows USING btree (updated_at);


--
-- Name: feedback_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX feedback_created_at_idx ON public.feedback USING btree (created_at);


--
-- Name: feedback_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX feedback_updated_at_idx ON public.feedback USING btree (updated_at);


--
-- Name: legal_pages__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX legal_pages__status_idx ON public.legal_pages USING btree (_status);


--
-- Name: legal_pages_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX legal_pages_created_at_idx ON public.legal_pages USING btree (created_at);


--
-- Name: legal_pages_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX legal_pages_created_by_idx ON public.legal_pages USING btree (created_by_id);


--
-- Name: legal_pages_groups_documents_file_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX legal_pages_groups_documents_file_idx ON public.legal_pages_groups_documents USING btree (file_id);


--
-- Name: legal_pages_groups_documents_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX legal_pages_groups_documents_order_idx ON public.legal_pages_groups_documents USING btree (_order);


--
-- Name: legal_pages_groups_documents_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX legal_pages_groups_documents_parent_id_idx ON public.legal_pages_groups_documents USING btree (_parent_id);


--
-- Name: legal_pages_groups_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX legal_pages_groups_order_idx ON public.legal_pages_groups USING btree (_order);


--
-- Name: legal_pages_groups_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX legal_pages_groups_parent_id_idx ON public.legal_pages_groups USING btree (_parent_id);


--
-- Name: legal_pages_hero_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX legal_pages_hero_image_idx ON public.legal_pages USING btree (hero_image_id);


--
-- Name: legal_pages_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX legal_pages_slug_idx ON public.legal_pages USING btree (slug);


--
-- Name: legal_pages_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX legal_pages_updated_at_idx ON public.legal_pages USING btree (updated_at);


--
-- Name: limit_tables__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX limit_tables__status_idx ON public.limit_tables USING btree (_status);


--
-- Name: limit_tables_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX limit_tables_created_at_idx ON public.limit_tables USING btree (created_at);


--
-- Name: limit_tables_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX limit_tables_created_by_idx ON public.limit_tables USING btree (created_by_id);


--
-- Name: limit_tables_rows_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX limit_tables_rows_order_idx ON public.limit_tables_rows USING btree (_order);


--
-- Name: limit_tables_rows_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX limit_tables_rows_parent_id_idx ON public.limit_tables_rows USING btree (_parent_id);


--
-- Name: limit_tables_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX limit_tables_updated_at_idx ON public.limit_tables USING btree (updated_at);


--
-- Name: media_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX media_created_at_idx ON public.media USING btree (created_at);


--
-- Name: media_filename_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX media_filename_idx ON public.media USING btree (filename);


--
-- Name: media_sizes_card_sizes_card_filename_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX media_sizes_card_sizes_card_filename_idx ON public.media USING btree (sizes_card_filename);


--
-- Name: media_sizes_hero_sizes_hero_filename_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX media_sizes_hero_sizes_hero_filename_idx ON public.media USING btree (sizes_hero_filename);


--
-- Name: media_sizes_thumbnail_sizes_thumbnail_filename_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX media_sizes_thumbnail_sizes_thumbnail_filename_idx ON public.media USING btree (sizes_thumbnail_filename);


--
-- Name: media_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX media_updated_at_idx ON public.media USING btree (updated_at);


--
-- Name: media_uploaded_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX media_uploaded_by_idx ON public.media USING btree (uploaded_by_id);


--
-- Name: nav_links__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX nav_links__status_idx ON public.nav_links USING btree (_status);


--
-- Name: nav_links_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX nav_links_created_at_idx ON public.nav_links USING btree (created_at);


--
-- Name: nav_links_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX nav_links_created_by_idx ON public.nav_links USING btree (created_by_id);


--
-- Name: nav_links_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX nav_links_updated_at_idx ON public.nav_links USING btree (updated_at);


--
-- Name: page_meta__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX page_meta__status_idx ON public.page_meta USING btree (_status);


--
-- Name: page_meta_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX page_meta_created_at_idx ON public.page_meta USING btree (created_at);


--
-- Name: page_meta_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX page_meta_created_by_idx ON public.page_meta USING btree (created_by_id);


--
-- Name: page_meta_og_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX page_meta_og_image_idx ON public.page_meta USING btree (og_image_id);


--
-- Name: page_meta_page_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX page_meta_page_key_idx ON public.page_meta USING btree (page_key);


--
-- Name: page_meta_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX page_meta_updated_at_idx ON public.page_meta USING btree (updated_at);


--
-- Name: pages__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages__status_idx ON public.pages USING btree (_status);


--
-- Name: pages_blocks_blog_grid_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_blog_grid_order_idx ON public.pages_blocks_blog_grid USING btree (_order);


--
-- Name: pages_blocks_blog_grid_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_blog_grid_parent_id_idx ON public.pages_blocks_blog_grid USING btree (_parent_id);


--
-- Name: pages_blocks_blog_grid_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_blog_grid_path_idx ON public.pages_blocks_blog_grid USING btree (_path);


--
-- Name: pages_blocks_campaign_grid_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_campaign_grid_order_idx ON public.pages_blocks_campaign_grid USING btree (_order);


--
-- Name: pages_blocks_campaign_grid_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_campaign_grid_parent_id_idx ON public.pages_blocks_campaign_grid USING btree (_parent_id);


--
-- Name: pages_blocks_campaign_grid_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_campaign_grid_path_idx ON public.pages_blocks_campaign_grid USING btree (_path);


--
-- Name: pages_blocks_contact_info_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_contact_info_order_idx ON public.pages_blocks_contact_info USING btree (_order);


--
-- Name: pages_blocks_contact_info_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_contact_info_parent_id_idx ON public.pages_blocks_contact_info USING btree (_parent_id);


--
-- Name: pages_blocks_contact_info_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_contact_info_path_idx ON public.pages_blocks_contact_info USING btree (_path);


--
-- Name: pages_blocks_faq_list_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_faq_list_order_idx ON public.pages_blocks_faq_list USING btree (_order);


--
-- Name: pages_blocks_faq_list_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_faq_list_parent_id_idx ON public.pages_blocks_faq_list USING btree (_parent_id);


--
-- Name: pages_blocks_faq_list_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_faq_list_path_idx ON public.pages_blocks_faq_list USING btree (_path);


--
-- Name: pages_blocks_feature_highlights_features_icon_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_feature_highlights_features_icon_idx ON public.pages_blocks_feature_highlights_features USING btree (icon_id);


--
-- Name: pages_blocks_feature_highlights_features_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_feature_highlights_features_order_idx ON public.pages_blocks_feature_highlights_features USING btree (_order);


--
-- Name: pages_blocks_feature_highlights_features_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_feature_highlights_features_parent_id_idx ON public.pages_blocks_feature_highlights_features USING btree (_parent_id);


--
-- Name: pages_blocks_feature_highlights_media_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_feature_highlights_media_idx ON public.pages_blocks_feature_highlights USING btree (media_id);


--
-- Name: pages_blocks_feature_highlights_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_feature_highlights_order_idx ON public.pages_blocks_feature_highlights USING btree (_order);


--
-- Name: pages_blocks_feature_highlights_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_feature_highlights_parent_id_idx ON public.pages_blocks_feature_highlights USING btree (_parent_id);


--
-- Name: pages_blocks_feature_highlights_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_feature_highlights_path_idx ON public.pages_blocks_feature_highlights USING btree (_path);


--
-- Name: pages_blocks_hero_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_hero_image_idx ON public.pages_blocks_hero USING btree (image_id);


--
-- Name: pages_blocks_hero_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_hero_order_idx ON public.pages_blocks_hero USING btree (_order);


--
-- Name: pages_blocks_hero_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_hero_parent_id_idx ON public.pages_blocks_hero USING btree (_parent_id);


--
-- Name: pages_blocks_hero_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_hero_path_idx ON public.pages_blocks_hero USING btree (_path);


--
-- Name: pages_blocks_how_to_earn_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_how_to_earn_image_idx ON public.pages_blocks_how_to_earn USING btree (image_id);


--
-- Name: pages_blocks_how_to_earn_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_how_to_earn_order_idx ON public.pages_blocks_how_to_earn USING btree (_order);


--
-- Name: pages_blocks_how_to_earn_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_how_to_earn_parent_id_idx ON public.pages_blocks_how_to_earn USING btree (_parent_id);


--
-- Name: pages_blocks_how_to_earn_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_how_to_earn_path_idx ON public.pages_blocks_how_to_earn USING btree (_path);


--
-- Name: pages_blocks_how_to_earn_steps_icon_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_how_to_earn_steps_icon_idx ON public.pages_blocks_how_to_earn_steps USING btree (icon_id);


--
-- Name: pages_blocks_how_to_earn_steps_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_how_to_earn_steps_order_idx ON public.pages_blocks_how_to_earn_steps USING btree (_order);


--
-- Name: pages_blocks_how_to_earn_steps_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_how_to_earn_steps_parent_id_idx ON public.pages_blocks_how_to_earn_steps USING btree (_parent_id);


--
-- Name: pages_blocks_icon_cards_cards_icon_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_icon_cards_cards_icon_idx ON public.pages_blocks_icon_cards_cards USING btree (icon_id);


--
-- Name: pages_blocks_icon_cards_cards_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_icon_cards_cards_order_idx ON public.pages_blocks_icon_cards_cards USING btree (_order);


--
-- Name: pages_blocks_icon_cards_cards_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_icon_cards_cards_parent_id_idx ON public.pages_blocks_icon_cards_cards USING btree (_parent_id);


--
-- Name: pages_blocks_icon_cards_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_icon_cards_order_idx ON public.pages_blocks_icon_cards USING btree (_order);


--
-- Name: pages_blocks_icon_cards_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_icon_cards_parent_id_idx ON public.pages_blocks_icon_cards USING btree (_parent_id);


--
-- Name: pages_blocks_icon_cards_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_icon_cards_path_idx ON public.pages_blocks_icon_cards USING btree (_path);


--
-- Name: pages_blocks_image_text_slides_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_image_text_slides_order_idx ON public.pages_blocks_image_text_slides USING btree (_order);


--
-- Name: pages_blocks_image_text_slides_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_image_text_slides_parent_id_idx ON public.pages_blocks_image_text_slides USING btree (_parent_id);


--
-- Name: pages_blocks_image_text_slides_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_image_text_slides_path_idx ON public.pages_blocks_image_text_slides USING btree (_path);


--
-- Name: pages_blocks_image_text_slides_side_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_image_text_slides_side_image_idx ON public.pages_blocks_image_text_slides USING btree (side_image_id);


--
-- Name: pages_blocks_image_text_slides_slides_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_image_text_slides_slides_image_idx ON public.pages_blocks_image_text_slides_slides USING btree (image_id);


--
-- Name: pages_blocks_image_text_slides_slides_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_image_text_slides_slides_order_idx ON public.pages_blocks_image_text_slides_slides USING btree (_order);


--
-- Name: pages_blocks_image_text_slides_slides_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_image_text_slides_slides_parent_id_idx ON public.pages_blocks_image_text_slides_slides USING btree (_parent_id);


--
-- Name: pages_blocks_image_with_text_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_image_with_text_image_idx ON public.pages_blocks_image_with_text USING btree (image_id);


--
-- Name: pages_blocks_image_with_text_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_image_with_text_order_idx ON public.pages_blocks_image_with_text USING btree (_order);


--
-- Name: pages_blocks_image_with_text_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_image_with_text_parent_id_idx ON public.pages_blocks_image_with_text USING btree (_parent_id);


--
-- Name: pages_blocks_image_with_text_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_image_with_text_path_idx ON public.pages_blocks_image_with_text USING btree (_path);


--
-- Name: pages_blocks_lead_form_cta_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_lead_form_cta_order_idx ON public.pages_blocks_lead_form_cta USING btree (_order);


--
-- Name: pages_blocks_lead_form_cta_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_lead_form_cta_parent_id_idx ON public.pages_blocks_lead_form_cta USING btree (_parent_id);


--
-- Name: pages_blocks_lead_form_cta_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_lead_form_cta_path_idx ON public.pages_blocks_lead_form_cta USING btree (_path);


--
-- Name: pages_blocks_logo_grid_logos_logo_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_logo_grid_logos_logo_idx ON public.pages_blocks_logo_grid_logos USING btree (logo_id);


--
-- Name: pages_blocks_logo_grid_logos_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_logo_grid_logos_order_idx ON public.pages_blocks_logo_grid_logos USING btree (_order);


--
-- Name: pages_blocks_logo_grid_logos_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_logo_grid_logos_parent_id_idx ON public.pages_blocks_logo_grid_logos USING btree (_parent_id);


--
-- Name: pages_blocks_logo_grid_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_logo_grid_order_idx ON public.pages_blocks_logo_grid USING btree (_order);


--
-- Name: pages_blocks_logo_grid_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_logo_grid_parent_id_idx ON public.pages_blocks_logo_grid USING btree (_parent_id);


--
-- Name: pages_blocks_logo_grid_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_logo_grid_path_idx ON public.pages_blocks_logo_grid USING btree (_path);


--
-- Name: pages_blocks_media_panel_background_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_media_panel_background_image_idx ON public.pages_blocks_media_panel USING btree (background_image_id);


--
-- Name: pages_blocks_media_panel_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_media_panel_order_idx ON public.pages_blocks_media_panel USING btree (_order);


--
-- Name: pages_blocks_media_panel_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_media_panel_parent_id_idx ON public.pages_blocks_media_panel USING btree (_parent_id);


--
-- Name: pages_blocks_media_panel_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_media_panel_path_idx ON public.pages_blocks_media_panel USING btree (_path);


--
-- Name: pages_blocks_prices_and_limits_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_prices_and_limits_order_idx ON public.pages_blocks_prices_and_limits USING btree (_order);


--
-- Name: pages_blocks_prices_and_limits_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_prices_and_limits_parent_id_idx ON public.pages_blocks_prices_and_limits USING btree (_parent_id);


--
-- Name: pages_blocks_prices_and_limits_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_prices_and_limits_path_idx ON public.pages_blocks_prices_and_limits USING btree (_path);


--
-- Name: pages_blocks_profile_grid_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_profile_grid_order_idx ON public.pages_blocks_profile_grid USING btree (_order);


--
-- Name: pages_blocks_profile_grid_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_profile_grid_parent_id_idx ON public.pages_blocks_profile_grid USING btree (_parent_id);


--
-- Name: pages_blocks_profile_grid_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_profile_grid_path_idx ON public.pages_blocks_profile_grid USING btree (_path);


--
-- Name: pages_blocks_profile_grid_people_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_profile_grid_people_order_idx ON public.pages_blocks_profile_grid_people USING btree (_order);


--
-- Name: pages_blocks_profile_grid_people_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_profile_grid_people_parent_id_idx ON public.pages_blocks_profile_grid_people USING btree (_parent_id);


--
-- Name: pages_blocks_profile_grid_people_photo_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_profile_grid_people_photo_idx ON public.pages_blocks_profile_grid_people USING btree (photo_id);


--
-- Name: pages_blocks_representatives_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_representatives_order_idx ON public.pages_blocks_representatives USING btree (_order);


--
-- Name: pages_blocks_representatives_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_representatives_parent_id_idx ON public.pages_blocks_representatives USING btree (_parent_id);


--
-- Name: pages_blocks_representatives_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_representatives_path_idx ON public.pages_blocks_representatives USING btree (_path);


--
-- Name: pages_blocks_rich_text_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_rich_text_order_idx ON public.pages_blocks_rich_text USING btree (_order);


--
-- Name: pages_blocks_rich_text_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_rich_text_parent_id_idx ON public.pages_blocks_rich_text USING btree (_parent_id);


--
-- Name: pages_blocks_rich_text_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_rich_text_path_idx ON public.pages_blocks_rich_text USING btree (_path);


--
-- Name: pages_blocks_step_phones_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_step_phones_order_idx ON public.pages_blocks_step_phones USING btree (_order);


--
-- Name: pages_blocks_step_phones_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_step_phones_parent_id_idx ON public.pages_blocks_step_phones USING btree (_parent_id);


--
-- Name: pages_blocks_step_phones_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_step_phones_path_idx ON public.pages_blocks_step_phones USING btree (_path);


--
-- Name: pages_blocks_step_phones_steps_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_step_phones_steps_image_idx ON public.pages_blocks_step_phones_steps USING btree (image_id);


--
-- Name: pages_blocks_step_phones_steps_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_step_phones_steps_order_idx ON public.pages_blocks_step_phones_steps USING btree (_order);


--
-- Name: pages_blocks_step_phones_steps_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_step_phones_steps_parent_id_idx ON public.pages_blocks_step_phones_steps USING btree (_parent_id);


--
-- Name: pages_blocks_steps_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_steps_order_idx ON public.pages_blocks_steps USING btree (_order);


--
-- Name: pages_blocks_steps_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_steps_parent_id_idx ON public.pages_blocks_steps USING btree (_parent_id);


--
-- Name: pages_blocks_steps_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_steps_path_idx ON public.pages_blocks_steps USING btree (_path);


--
-- Name: pages_blocks_steps_steps_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_steps_steps_image_idx ON public.pages_blocks_steps_steps USING btree (image_id);


--
-- Name: pages_blocks_steps_steps_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_steps_steps_order_idx ON public.pages_blocks_steps_steps USING btree (_order);


--
-- Name: pages_blocks_steps_steps_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_steps_steps_parent_id_idx ON public.pages_blocks_steps_steps USING btree (_parent_id);


--
-- Name: pages_blocks_video_list_dark_bg_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_video_list_dark_bg_image_idx ON public.pages_blocks_video_list USING btree (dark_background_image_id);


--
-- Name: pages_blocks_video_list_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_video_list_order_idx ON public.pages_blocks_video_list USING btree (_order);


--
-- Name: pages_blocks_video_list_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_video_list_parent_id_idx ON public.pages_blocks_video_list USING btree (_parent_id);


--
-- Name: pages_blocks_video_list_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_video_list_path_idx ON public.pages_blocks_video_list USING btree (_path);


--
-- Name: pages_blocks_video_list_videos_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_video_list_videos_order_idx ON public.pages_blocks_video_list_videos USING btree (_order);


--
-- Name: pages_blocks_video_list_videos_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_video_list_videos_parent_id_idx ON public.pages_blocks_video_list_videos USING btree (_parent_id);


--
-- Name: pages_blocks_video_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_video_order_idx ON public.pages_blocks_video USING btree (_order);


--
-- Name: pages_blocks_video_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_video_parent_id_idx ON public.pages_blocks_video USING btree (_parent_id);


--
-- Name: pages_blocks_video_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_video_path_idx ON public.pages_blocks_video USING btree (_path);


--
-- Name: pages_blocks_videos_with_tabs_marker_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_videos_with_tabs_marker_order_idx ON public.pages_blocks_videos_with_tabs_marker USING btree (_order);


--
-- Name: pages_blocks_videos_with_tabs_marker_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_videos_with_tabs_marker_parent_id_idx ON public.pages_blocks_videos_with_tabs_marker USING btree (_parent_id);


--
-- Name: pages_blocks_videos_with_tabs_marker_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_blocks_videos_with_tabs_marker_path_idx ON public.pages_blocks_videos_with_tabs_marker USING btree (_path);


--
-- Name: pages_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_created_at_idx ON public.pages USING btree (created_at);


--
-- Name: pages_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_created_by_idx ON public.pages USING btree (created_by_id);


--
-- Name: pages_og_image_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_og_image_idx ON public.pages USING btree (og_image_id);


--
-- Name: pages_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_parent_idx ON public.pages USING btree (parent_id);


--
-- Name: pages_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX pages_slug_idx ON public.pages USING btree (slug);


--
-- Name: pages_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pages_updated_at_idx ON public.pages USING btree (updated_at);


--
-- Name: payload_kv_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX payload_kv_key_idx ON public.payload_kv USING btree (key);


--
-- Name: payload_locked_documents_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_created_at_idx ON public.payload_locked_documents USING btree (created_at);


--
-- Name: payload_locked_documents_global_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_global_slug_idx ON public.payload_locked_documents USING btree (global_slug);


--
-- Name: payload_locked_documents_rels_announcements_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_announcements_id_idx ON public.payload_locked_documents_rels USING btree (announcements_id);


--
-- Name: payload_locked_documents_rels_audit_logs_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_audit_logs_id_idx ON public.payload_locked_documents_rels USING btree (audit_logs_id);


--
-- Name: payload_locked_documents_rels_blog_posts_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_blog_posts_id_idx ON public.payload_locked_documents_rels USING btree (blog_posts_id);


--
-- Name: payload_locked_documents_rels_campaigns_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_campaigns_id_idx ON public.payload_locked_documents_rels USING btree (campaigns_id);


--
-- Name: payload_locked_documents_rels_categories_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_categories_id_idx ON public.payload_locked_documents_rels USING btree (categories_id);


--
-- Name: payload_locked_documents_rels_cookie_rows_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_cookie_rows_id_idx ON public.payload_locked_documents_rels USING btree (cookie_rows_id);


--
-- Name: payload_locked_documents_rels_documents_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_documents_id_idx ON public.payload_locked_documents_rels USING btree (documents_id);


--
-- Name: payload_locked_documents_rels_faq_items_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_faq_items_id_idx ON public.payload_locked_documents_rels USING btree (faq_items_id);


--
-- Name: payload_locked_documents_rels_fee_rows_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_fee_rows_id_idx ON public.payload_locked_documents_rels USING btree (fee_rows_id);


--
-- Name: payload_locked_documents_rels_feedback_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_feedback_id_idx ON public.payload_locked_documents_rels USING btree (feedback_id);


--
-- Name: payload_locked_documents_rels_legal_pages_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_legal_pages_id_idx ON public.payload_locked_documents_rels USING btree (legal_pages_id);


--
-- Name: payload_locked_documents_rels_limit_tables_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_limit_tables_id_idx ON public.payload_locked_documents_rels USING btree (limit_tables_id);


--
-- Name: payload_locked_documents_rels_media_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_media_id_idx ON public.payload_locked_documents_rels USING btree (media_id);


--
-- Name: payload_locked_documents_rels_nav_links_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_nav_links_id_idx ON public.payload_locked_documents_rels USING btree (nav_links_id);


--
-- Name: payload_locked_documents_rels_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_order_idx ON public.payload_locked_documents_rels USING btree ("order");


--
-- Name: payload_locked_documents_rels_page_meta_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_page_meta_id_idx ON public.payload_locked_documents_rels USING btree (page_meta_id);


--
-- Name: payload_locked_documents_rels_pages_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_pages_id_idx ON public.payload_locked_documents_rels USING btree (pages_id);


--
-- Name: payload_locked_documents_rels_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_parent_idx ON public.payload_locked_documents_rels USING btree (parent_id);


--
-- Name: payload_locked_documents_rels_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_path_idx ON public.payload_locked_documents_rels USING btree (path);


--
-- Name: payload_locked_documents_rels_representatives_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_representatives_id_idx ON public.payload_locked_documents_rels USING btree (representatives_id);


--
-- Name: payload_locked_documents_rels_translations_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_translations_id_idx ON public.payload_locked_documents_rels USING btree (translations_id);


--
-- Name: payload_locked_documents_rels_users_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_rels_users_id_idx ON public.payload_locked_documents_rels USING btree (users_id);


--
-- Name: payload_locked_documents_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_locked_documents_updated_at_idx ON public.payload_locked_documents USING btree (updated_at);


--
-- Name: payload_migrations_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_migrations_created_at_idx ON public.payload_migrations USING btree (created_at);


--
-- Name: payload_migrations_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_migrations_updated_at_idx ON public.payload_migrations USING btree (updated_at);


--
-- Name: payload_preferences_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_preferences_created_at_idx ON public.payload_preferences USING btree (created_at);


--
-- Name: payload_preferences_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_preferences_key_idx ON public.payload_preferences USING btree (key);


--
-- Name: payload_preferences_rels_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_preferences_rels_order_idx ON public.payload_preferences_rels USING btree ("order");


--
-- Name: payload_preferences_rels_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_preferences_rels_parent_idx ON public.payload_preferences_rels USING btree (parent_id);


--
-- Name: payload_preferences_rels_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_preferences_rels_path_idx ON public.payload_preferences_rels USING btree (path);


--
-- Name: payload_preferences_rels_users_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_preferences_rels_users_id_idx ON public.payload_preferences_rels USING btree (users_id);


--
-- Name: payload_preferences_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payload_preferences_updated_at_idx ON public.payload_preferences USING btree (updated_at);


--
-- Name: representatives__status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX representatives__status_idx ON public.representatives USING btree (_status);


--
-- Name: representatives_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX representatives_created_at_idx ON public.representatives USING btree (created_at);


--
-- Name: representatives_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX representatives_created_by_idx ON public.representatives USING btree (created_by_id);


--
-- Name: representatives_qr_code_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX representatives_qr_code_idx ON public.representatives USING btree (qr_code_id);


--
-- Name: representatives_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX representatives_updated_at_idx ON public.representatives USING btree (updated_at);


--
-- Name: scope_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX scope_slug_idx ON public.categories USING btree (scope, slug);


--
-- Name: translations_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX translations_created_at_idx ON public.translations USING btree (created_at);


--
-- Name: translations_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX translations_key_idx ON public.translations USING btree (key);


--
-- Name: translations_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX translations_updated_at_idx ON public.translations USING btree (updated_at);


--
-- Name: users_avatar_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_avatar_idx ON public.users USING btree (avatar_id);


--
-- Name: users_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_created_at_idx ON public.users USING btree (created_at);


--
-- Name: users_delegate_to_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_delegate_to_idx ON public.users USING btree (delegate_to_id);


--
-- Name: users_email_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_idx ON public.users USING btree (email);


--
-- Name: users_sessions_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_sessions_order_idx ON public.users_sessions USING btree (_order);


--
-- Name: users_sessions_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_sessions_parent_id_idx ON public.users_sessions USING btree (_parent_id);


--
-- Name: users_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_updated_at_idx ON public.users USING btree (updated_at);


--
-- Name: _announcements_v _announcements_v_parent_id_announcements_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._announcements_v
    ADD CONSTRAINT _announcements_v_parent_id_announcements_id_fk FOREIGN KEY (parent_id) REFERENCES public.announcements(id) ON DELETE SET NULL;


--
-- Name: _announcements_v _announcements_v_version_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._announcements_v
    ADD CONSTRAINT _announcements_v_version_created_by_id_users_id_fk FOREIGN KEY (version_created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: _blog_posts_v _blog_posts_v_parent_id_blog_posts_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._blog_posts_v
    ADD CONSTRAINT _blog_posts_v_parent_id_blog_posts_id_fk FOREIGN KEY (parent_id) REFERENCES public.blog_posts(id) ON DELETE SET NULL;


--
-- Name: _blog_posts_v _blog_posts_v_version_category_id_categories_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._blog_posts_v
    ADD CONSTRAINT _blog_posts_v_version_category_id_categories_id_fk FOREIGN KEY (version_category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: _blog_posts_v _blog_posts_v_version_cover_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._blog_posts_v
    ADD CONSTRAINT _blog_posts_v_version_cover_image_id_media_id_fk FOREIGN KEY (version_cover_image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _blog_posts_v _blog_posts_v_version_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._blog_posts_v
    ADD CONSTRAINT _blog_posts_v_version_created_by_id_users_id_fk FOREIGN KEY (version_created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: _campaigns_v _campaigns_v_parent_id_campaigns_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._campaigns_v
    ADD CONSTRAINT _campaigns_v_parent_id_campaigns_id_fk FOREIGN KEY (parent_id) REFERENCES public.campaigns(id) ON DELETE SET NULL;


--
-- Name: _campaigns_v _campaigns_v_version_category_id_categories_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._campaigns_v
    ADD CONSTRAINT _campaigns_v_version_category_id_categories_id_fk FOREIGN KEY (version_category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: _campaigns_v _campaigns_v_version_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._campaigns_v
    ADD CONSTRAINT _campaigns_v_version_created_by_id_users_id_fk FOREIGN KEY (version_created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: _campaigns_v _campaigns_v_version_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._campaigns_v
    ADD CONSTRAINT _campaigns_v_version_image_id_media_id_fk FOREIGN KEY (version_image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _campaigns_v _campaigns_v_version_rejected_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._campaigns_v
    ADD CONSTRAINT _campaigns_v_version_rejected_by_id_users_id_fk FOREIGN KEY (version_rejected_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: _campaigns_v _campaigns_v_version_unpublish_requested_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._campaigns_v
    ADD CONSTRAINT _campaigns_v_version_unpublish_requested_by_id_users_id_fk FOREIGN KEY (version_unpublish_requested_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: _categories_v _categories_v_parent_id_categories_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._categories_v
    ADD CONSTRAINT _categories_v_parent_id_categories_id_fk FOREIGN KEY (parent_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: _categories_v _categories_v_version_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._categories_v
    ADD CONSTRAINT _categories_v_version_created_by_id_users_id_fk FOREIGN KEY (version_created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: _cookie_rows_v _cookie_rows_v_parent_id_cookie_rows_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._cookie_rows_v
    ADD CONSTRAINT _cookie_rows_v_parent_id_cookie_rows_id_fk FOREIGN KEY (parent_id) REFERENCES public.cookie_rows(id) ON DELETE SET NULL;


--
-- Name: _cookie_rows_v _cookie_rows_v_version_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._cookie_rows_v
    ADD CONSTRAINT _cookie_rows_v_version_created_by_id_users_id_fk FOREIGN KEY (version_created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: _documents_v _documents_v_parent_id_documents_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._documents_v
    ADD CONSTRAINT _documents_v_parent_id_documents_id_fk FOREIGN KEY (parent_id) REFERENCES public.documents(id) ON DELETE SET NULL;


--
-- Name: _documents_v _documents_v_version_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._documents_v
    ADD CONSTRAINT _documents_v_version_created_by_id_users_id_fk FOREIGN KEY (version_created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: _faq_items_v _faq_items_v_parent_id_faq_items_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._faq_items_v
    ADD CONSTRAINT _faq_items_v_parent_id_faq_items_id_fk FOREIGN KEY (parent_id) REFERENCES public.faq_items(id) ON DELETE SET NULL;


--
-- Name: _faq_items_v _faq_items_v_version_category_id_categories_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._faq_items_v
    ADD CONSTRAINT _faq_items_v_version_category_id_categories_id_fk FOREIGN KEY (version_category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: _faq_items_v _faq_items_v_version_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._faq_items_v
    ADD CONSTRAINT _faq_items_v_version_created_by_id_users_id_fk FOREIGN KEY (version_created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: _fee_rows_v _fee_rows_v_parent_id_fee_rows_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._fee_rows_v
    ADD CONSTRAINT _fee_rows_v_parent_id_fee_rows_id_fk FOREIGN KEY (parent_id) REFERENCES public.fee_rows(id) ON DELETE SET NULL;


--
-- Name: _fee_rows_v _fee_rows_v_version_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._fee_rows_v
    ADD CONSTRAINT _fee_rows_v_version_created_by_id_users_id_fk FOREIGN KEY (version_created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: _legal_pages_v _legal_pages_v_parent_id_legal_pages_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._legal_pages_v
    ADD CONSTRAINT _legal_pages_v_parent_id_legal_pages_id_fk FOREIGN KEY (parent_id) REFERENCES public.legal_pages(id) ON DELETE SET NULL;


--
-- Name: _legal_pages_v _legal_pages_v_version_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._legal_pages_v
    ADD CONSTRAINT _legal_pages_v_version_created_by_id_users_id_fk FOREIGN KEY (version_created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: _legal_pages_v_version_groups_documents _legal_pages_v_version_groups_documents_file_id_documents_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._legal_pages_v_version_groups_documents
    ADD CONSTRAINT _legal_pages_v_version_groups_documents_file_id_documents_id_fk FOREIGN KEY (file_id) REFERENCES public.documents(id) ON DELETE SET NULL;


--
-- Name: _legal_pages_v_version_groups_documents _legal_pages_v_version_groups_documents_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._legal_pages_v_version_groups_documents
    ADD CONSTRAINT _legal_pages_v_version_groups_documents_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._legal_pages_v_version_groups(id) ON DELETE CASCADE;


--
-- Name: _legal_pages_v_version_groups _legal_pages_v_version_groups_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._legal_pages_v_version_groups
    ADD CONSTRAINT _legal_pages_v_version_groups_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._legal_pages_v(id) ON DELETE CASCADE;


--
-- Name: _legal_pages_v _legal_pages_v_version_hero_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._legal_pages_v
    ADD CONSTRAINT _legal_pages_v_version_hero_image_id_media_id_fk FOREIGN KEY (version_hero_image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _limit_tables_v _limit_tables_v_parent_id_limit_tables_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._limit_tables_v
    ADD CONSTRAINT _limit_tables_v_parent_id_limit_tables_id_fk FOREIGN KEY (parent_id) REFERENCES public.limit_tables(id) ON DELETE SET NULL;


--
-- Name: _limit_tables_v _limit_tables_v_version_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._limit_tables_v
    ADD CONSTRAINT _limit_tables_v_version_created_by_id_users_id_fk FOREIGN KEY (version_created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: _limit_tables_v_version_rows _limit_tables_v_version_rows_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._limit_tables_v_version_rows
    ADD CONSTRAINT _limit_tables_v_version_rows_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._limit_tables_v(id) ON DELETE CASCADE;


--
-- Name: _nav_links_v _nav_links_v_parent_id_nav_links_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._nav_links_v
    ADD CONSTRAINT _nav_links_v_parent_id_nav_links_id_fk FOREIGN KEY (parent_id) REFERENCES public.nav_links(id) ON DELETE SET NULL;


--
-- Name: _nav_links_v _nav_links_v_version_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._nav_links_v
    ADD CONSTRAINT _nav_links_v_version_created_by_id_users_id_fk FOREIGN KEY (version_created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: _page_meta_v _page_meta_v_parent_id_page_meta_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._page_meta_v
    ADD CONSTRAINT _page_meta_v_parent_id_page_meta_id_fk FOREIGN KEY (parent_id) REFERENCES public.page_meta(id) ON DELETE SET NULL;


--
-- Name: _page_meta_v _page_meta_v_version_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._page_meta_v
    ADD CONSTRAINT _page_meta_v_version_created_by_id_users_id_fk FOREIGN KEY (version_created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: _page_meta_v _page_meta_v_version_og_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._page_meta_v
    ADD CONSTRAINT _page_meta_v_version_og_image_id_media_id_fk FOREIGN KEY (version_og_image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _pages_v_blocks_blog_grid _pages_v_blocks_blog_grid_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_blog_grid
    ADD CONSTRAINT _pages_v_blocks_blog_grid_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_campaign_grid _pages_v_blocks_campaign_grid_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_campaign_grid
    ADD CONSTRAINT _pages_v_blocks_campaign_grid_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_contact_info _pages_v_blocks_contact_info_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_contact_info
    ADD CONSTRAINT _pages_v_blocks_contact_info_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_faq_list _pages_v_blocks_faq_list_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_faq_list
    ADD CONSTRAINT _pages_v_blocks_faq_list_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_feature_highlights_features _pages_v_blocks_feature_highlights_features_icon_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_feature_highlights_features
    ADD CONSTRAINT _pages_v_blocks_feature_highlights_features_icon_id_media_id_fk FOREIGN KEY (icon_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _pages_v_blocks_feature_highlights_features _pages_v_blocks_feature_highlights_features_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_feature_highlights_features
    ADD CONSTRAINT _pages_v_blocks_feature_highlights_features_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v_blocks_feature_highlights(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_feature_highlights _pages_v_blocks_feature_highlights_media_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_feature_highlights
    ADD CONSTRAINT _pages_v_blocks_feature_highlights_media_id_media_id_fk FOREIGN KEY (media_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _pages_v_blocks_feature_highlights _pages_v_blocks_feature_highlights_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_feature_highlights
    ADD CONSTRAINT _pages_v_blocks_feature_highlights_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_hero _pages_v_blocks_hero_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_hero
    ADD CONSTRAINT _pages_v_blocks_hero_image_id_media_id_fk FOREIGN KEY (image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _pages_v_blocks_hero _pages_v_blocks_hero_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_hero
    ADD CONSTRAINT _pages_v_blocks_hero_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_how_to_earn _pages_v_blocks_how_to_earn_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_how_to_earn
    ADD CONSTRAINT _pages_v_blocks_how_to_earn_image_id_media_id_fk FOREIGN KEY (image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _pages_v_blocks_how_to_earn _pages_v_blocks_how_to_earn_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_how_to_earn
    ADD CONSTRAINT _pages_v_blocks_how_to_earn_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_how_to_earn_steps _pages_v_blocks_how_to_earn_steps_icon_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_how_to_earn_steps
    ADD CONSTRAINT _pages_v_blocks_how_to_earn_steps_icon_id_media_id_fk FOREIGN KEY (icon_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _pages_v_blocks_how_to_earn_steps _pages_v_blocks_how_to_earn_steps_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_how_to_earn_steps
    ADD CONSTRAINT _pages_v_blocks_how_to_earn_steps_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v_blocks_how_to_earn(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_icon_cards_cards _pages_v_blocks_icon_cards_cards_icon_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_icon_cards_cards
    ADD CONSTRAINT _pages_v_blocks_icon_cards_cards_icon_id_media_id_fk FOREIGN KEY (icon_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _pages_v_blocks_icon_cards_cards _pages_v_blocks_icon_cards_cards_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_icon_cards_cards
    ADD CONSTRAINT _pages_v_blocks_icon_cards_cards_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v_blocks_icon_cards(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_icon_cards _pages_v_blocks_icon_cards_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_icon_cards
    ADD CONSTRAINT _pages_v_blocks_icon_cards_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_image_text_slides _pages_v_blocks_image_text_slides_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_image_text_slides
    ADD CONSTRAINT _pages_v_blocks_image_text_slides_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_image_text_slides _pages_v_blocks_image_text_slides_side_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_image_text_slides
    ADD CONSTRAINT _pages_v_blocks_image_text_slides_side_image_id_media_id_fk FOREIGN KEY (side_image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _pages_v_blocks_image_text_slides_slides _pages_v_blocks_image_text_slides_slides_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_image_text_slides_slides
    ADD CONSTRAINT _pages_v_blocks_image_text_slides_slides_image_id_media_id_fk FOREIGN KEY (image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _pages_v_blocks_image_text_slides_slides _pages_v_blocks_image_text_slides_slides_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_image_text_slides_slides
    ADD CONSTRAINT _pages_v_blocks_image_text_slides_slides_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v_blocks_image_text_slides(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_image_with_text _pages_v_blocks_image_with_text_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_image_with_text
    ADD CONSTRAINT _pages_v_blocks_image_with_text_image_id_media_id_fk FOREIGN KEY (image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _pages_v_blocks_image_with_text _pages_v_blocks_image_with_text_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_image_with_text
    ADD CONSTRAINT _pages_v_blocks_image_with_text_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_lead_form_cta _pages_v_blocks_lead_form_cta_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_lead_form_cta
    ADD CONSTRAINT _pages_v_blocks_lead_form_cta_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_logo_grid_logos _pages_v_blocks_logo_grid_logos_logo_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_logo_grid_logos
    ADD CONSTRAINT _pages_v_blocks_logo_grid_logos_logo_id_media_id_fk FOREIGN KEY (logo_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _pages_v_blocks_logo_grid_logos _pages_v_blocks_logo_grid_logos_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_logo_grid_logos
    ADD CONSTRAINT _pages_v_blocks_logo_grid_logos_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v_blocks_logo_grid(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_logo_grid _pages_v_blocks_logo_grid_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_logo_grid
    ADD CONSTRAINT _pages_v_blocks_logo_grid_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_media_panel _pages_v_blocks_media_panel_background_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_media_panel
    ADD CONSTRAINT _pages_v_blocks_media_panel_background_image_id_media_id_fk FOREIGN KEY (background_image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _pages_v_blocks_media_panel _pages_v_blocks_media_panel_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_media_panel
    ADD CONSTRAINT _pages_v_blocks_media_panel_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_prices_and_limits _pages_v_blocks_prices_and_limits_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_prices_and_limits
    ADD CONSTRAINT _pages_v_blocks_prices_and_limits_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_profile_grid _pages_v_blocks_profile_grid_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_profile_grid
    ADD CONSTRAINT _pages_v_blocks_profile_grid_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_profile_grid_people _pages_v_blocks_profile_grid_people_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_profile_grid_people
    ADD CONSTRAINT _pages_v_blocks_profile_grid_people_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v_blocks_profile_grid(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_profile_grid_people _pages_v_blocks_profile_grid_people_photo_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_profile_grid_people
    ADD CONSTRAINT _pages_v_blocks_profile_grid_people_photo_id_media_id_fk FOREIGN KEY (photo_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _pages_v_blocks_representatives _pages_v_blocks_representatives_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_representatives
    ADD CONSTRAINT _pages_v_blocks_representatives_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_rich_text _pages_v_blocks_rich_text_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_rich_text
    ADD CONSTRAINT _pages_v_blocks_rich_text_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_step_phones _pages_v_blocks_step_phones_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_step_phones
    ADD CONSTRAINT _pages_v_blocks_step_phones_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_step_phones_steps _pages_v_blocks_step_phones_steps_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_step_phones_steps
    ADD CONSTRAINT _pages_v_blocks_step_phones_steps_image_id_media_id_fk FOREIGN KEY (image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _pages_v_blocks_step_phones_steps _pages_v_blocks_step_phones_steps_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_step_phones_steps
    ADD CONSTRAINT _pages_v_blocks_step_phones_steps_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v_blocks_step_phones(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_steps _pages_v_blocks_steps_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_steps
    ADD CONSTRAINT _pages_v_blocks_steps_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_steps_steps _pages_v_blocks_steps_steps_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_steps_steps
    ADD CONSTRAINT _pages_v_blocks_steps_steps_image_id_media_id_fk FOREIGN KEY (image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _pages_v_blocks_steps_steps _pages_v_blocks_steps_steps_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_steps_steps
    ADD CONSTRAINT _pages_v_blocks_steps_steps_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v_blocks_steps(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_video_list _pages_v_blocks_video_list_dark_bg_image_id_media_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_video_list
    ADD CONSTRAINT _pages_v_blocks_video_list_dark_bg_image_id_media_fk FOREIGN KEY (dark_background_image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _pages_v_blocks_video_list _pages_v_blocks_video_list_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_video_list
    ADD CONSTRAINT _pages_v_blocks_video_list_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_video_list_videos _pages_v_blocks_video_list_videos_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_video_list_videos
    ADD CONSTRAINT _pages_v_blocks_video_list_videos_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v_blocks_video_list(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_video _pages_v_blocks_video_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_video
    ADD CONSTRAINT _pages_v_blocks_video_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v_blocks_videos_with_tabs_marker _pages_v_blocks_videos_with_tabs_marker_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v_blocks_videos_with_tabs_marker
    ADD CONSTRAINT _pages_v_blocks_videos_with_tabs_marker_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public._pages_v(id) ON DELETE CASCADE;


--
-- Name: _pages_v _pages_v_parent_id_pages_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v
    ADD CONSTRAINT _pages_v_parent_id_pages_id_fk FOREIGN KEY (parent_id) REFERENCES public.pages(id) ON DELETE SET NULL;


--
-- Name: _pages_v _pages_v_version_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v
    ADD CONSTRAINT _pages_v_version_created_by_id_users_id_fk FOREIGN KEY (version_created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: _pages_v _pages_v_version_og_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v
    ADD CONSTRAINT _pages_v_version_og_image_id_media_id_fk FOREIGN KEY (version_og_image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: _pages_v _pages_v_version_parent_id_pages_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._pages_v
    ADD CONSTRAINT _pages_v_version_parent_id_pages_id_fk FOREIGN KEY (version_parent_id) REFERENCES public.pages(id) ON DELETE SET NULL;


--
-- Name: _representatives_v _representatives_v_parent_id_representatives_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._representatives_v
    ADD CONSTRAINT _representatives_v_parent_id_representatives_id_fk FOREIGN KEY (parent_id) REFERENCES public.representatives(id) ON DELETE SET NULL;


--
-- Name: _representatives_v _representatives_v_version_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._representatives_v
    ADD CONSTRAINT _representatives_v_version_created_by_id_users_id_fk FOREIGN KEY (version_created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: _representatives_v _representatives_v_version_qr_code_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._representatives_v
    ADD CONSTRAINT _representatives_v_version_qr_code_id_media_id_fk FOREIGN KEY (version_qr_code_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: announcements announcements_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_created_by_id_users_id_fk FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: audit_logs_changes audit_logs_changes_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs_changes
    ADD CONSTRAINT audit_logs_changes_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.audit_logs(id) ON DELETE CASCADE;


--
-- Name: blog_posts blog_posts_category_id_categories_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blog_posts
    ADD CONSTRAINT blog_posts_category_id_categories_id_fk FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: blog_posts blog_posts_cover_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blog_posts
    ADD CONSTRAINT blog_posts_cover_image_id_media_id_fk FOREIGN KEY (cover_image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: blog_posts blog_posts_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blog_posts
    ADD CONSTRAINT blog_posts_created_by_id_users_id_fk FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: campaigns campaigns_category_id_categories_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_category_id_categories_id_fk FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: campaigns campaigns_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_created_by_id_users_id_fk FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: campaigns campaigns_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_image_id_media_id_fk FOREIGN KEY (image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: campaigns campaigns_rejected_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_rejected_by_id_users_id_fk FOREIGN KEY (rejected_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: campaigns campaigns_unpublish_requested_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_unpublish_requested_by_id_users_id_fk FOREIGN KEY (unpublish_requested_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: categories categories_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_created_by_id_users_id_fk FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: cookie_rows cookie_rows_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cookie_rows
    ADD CONSTRAINT cookie_rows_created_by_id_users_id_fk FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: documents documents_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_created_by_id_users_id_fk FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: faq_items faq_items_category_id_categories_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faq_items
    ADD CONSTRAINT faq_items_category_id_categories_id_fk FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: faq_items faq_items_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faq_items
    ADD CONSTRAINT faq_items_created_by_id_users_id_fk FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: fee_rows fee_rows_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fee_rows
    ADD CONSTRAINT fee_rows_created_by_id_users_id_fk FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: legal_pages legal_pages_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legal_pages
    ADD CONSTRAINT legal_pages_created_by_id_users_id_fk FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: legal_pages_groups_documents legal_pages_groups_documents_file_id_documents_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legal_pages_groups_documents
    ADD CONSTRAINT legal_pages_groups_documents_file_id_documents_id_fk FOREIGN KEY (file_id) REFERENCES public.documents(id) ON DELETE SET NULL;


--
-- Name: legal_pages_groups_documents legal_pages_groups_documents_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legal_pages_groups_documents
    ADD CONSTRAINT legal_pages_groups_documents_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.legal_pages_groups(id) ON DELETE CASCADE;


--
-- Name: legal_pages_groups legal_pages_groups_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legal_pages_groups
    ADD CONSTRAINT legal_pages_groups_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.legal_pages(id) ON DELETE CASCADE;


--
-- Name: legal_pages legal_pages_hero_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legal_pages
    ADD CONSTRAINT legal_pages_hero_image_id_media_id_fk FOREIGN KEY (hero_image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: limit_tables limit_tables_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.limit_tables
    ADD CONSTRAINT limit_tables_created_by_id_users_id_fk FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: limit_tables_rows limit_tables_rows_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.limit_tables_rows
    ADD CONSTRAINT limit_tables_rows_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.limit_tables(id) ON DELETE CASCADE;


--
-- Name: media media_uploaded_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_uploaded_by_id_users_id_fk FOREIGN KEY (uploaded_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: nav_links nav_links_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nav_links
    ADD CONSTRAINT nav_links_created_by_id_users_id_fk FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: page_meta page_meta_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_meta
    ADD CONSTRAINT page_meta_created_by_id_users_id_fk FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: page_meta page_meta_og_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_meta
    ADD CONSTRAINT page_meta_og_image_id_media_id_fk FOREIGN KEY (og_image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: pages_blocks_blog_grid pages_blocks_blog_grid_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_blog_grid
    ADD CONSTRAINT pages_blocks_blog_grid_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_campaign_grid pages_blocks_campaign_grid_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_campaign_grid
    ADD CONSTRAINT pages_blocks_campaign_grid_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_contact_info pages_blocks_contact_info_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_contact_info
    ADD CONSTRAINT pages_blocks_contact_info_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_faq_list pages_blocks_faq_list_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_faq_list
    ADD CONSTRAINT pages_blocks_faq_list_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_feature_highlights_features pages_blocks_feature_highlights_features_icon_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_feature_highlights_features
    ADD CONSTRAINT pages_blocks_feature_highlights_features_icon_id_media_id_fk FOREIGN KEY (icon_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: pages_blocks_feature_highlights_features pages_blocks_feature_highlights_features_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_feature_highlights_features
    ADD CONSTRAINT pages_blocks_feature_highlights_features_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages_blocks_feature_highlights(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_feature_highlights pages_blocks_feature_highlights_media_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_feature_highlights
    ADD CONSTRAINT pages_blocks_feature_highlights_media_id_media_id_fk FOREIGN KEY (media_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: pages_blocks_feature_highlights pages_blocks_feature_highlights_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_feature_highlights
    ADD CONSTRAINT pages_blocks_feature_highlights_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_hero pages_blocks_hero_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_hero
    ADD CONSTRAINT pages_blocks_hero_image_id_media_id_fk FOREIGN KEY (image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: pages_blocks_hero pages_blocks_hero_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_hero
    ADD CONSTRAINT pages_blocks_hero_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_how_to_earn pages_blocks_how_to_earn_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_how_to_earn
    ADD CONSTRAINT pages_blocks_how_to_earn_image_id_media_id_fk FOREIGN KEY (image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: pages_blocks_how_to_earn pages_blocks_how_to_earn_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_how_to_earn
    ADD CONSTRAINT pages_blocks_how_to_earn_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_how_to_earn_steps pages_blocks_how_to_earn_steps_icon_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_how_to_earn_steps
    ADD CONSTRAINT pages_blocks_how_to_earn_steps_icon_id_media_id_fk FOREIGN KEY (icon_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: pages_blocks_how_to_earn_steps pages_blocks_how_to_earn_steps_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_how_to_earn_steps
    ADD CONSTRAINT pages_blocks_how_to_earn_steps_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages_blocks_how_to_earn(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_icon_cards_cards pages_blocks_icon_cards_cards_icon_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_icon_cards_cards
    ADD CONSTRAINT pages_blocks_icon_cards_cards_icon_id_media_id_fk FOREIGN KEY (icon_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: pages_blocks_icon_cards_cards pages_blocks_icon_cards_cards_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_icon_cards_cards
    ADD CONSTRAINT pages_blocks_icon_cards_cards_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages_blocks_icon_cards(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_icon_cards pages_blocks_icon_cards_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_icon_cards
    ADD CONSTRAINT pages_blocks_icon_cards_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_image_text_slides pages_blocks_image_text_slides_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_image_text_slides
    ADD CONSTRAINT pages_blocks_image_text_slides_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_image_text_slides pages_blocks_image_text_slides_side_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_image_text_slides
    ADD CONSTRAINT pages_blocks_image_text_slides_side_image_id_media_id_fk FOREIGN KEY (side_image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: pages_blocks_image_text_slides_slides pages_blocks_image_text_slides_slides_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_image_text_slides_slides
    ADD CONSTRAINT pages_blocks_image_text_slides_slides_image_id_media_id_fk FOREIGN KEY (image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: pages_blocks_image_text_slides_slides pages_blocks_image_text_slides_slides_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_image_text_slides_slides
    ADD CONSTRAINT pages_blocks_image_text_slides_slides_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages_blocks_image_text_slides(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_image_with_text pages_blocks_image_with_text_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_image_with_text
    ADD CONSTRAINT pages_blocks_image_with_text_image_id_media_id_fk FOREIGN KEY (image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: pages_blocks_image_with_text pages_blocks_image_with_text_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_image_with_text
    ADD CONSTRAINT pages_blocks_image_with_text_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_lead_form_cta pages_blocks_lead_form_cta_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_lead_form_cta
    ADD CONSTRAINT pages_blocks_lead_form_cta_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_logo_grid_logos pages_blocks_logo_grid_logos_logo_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_logo_grid_logos
    ADD CONSTRAINT pages_blocks_logo_grid_logos_logo_id_media_id_fk FOREIGN KEY (logo_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: pages_blocks_logo_grid_logos pages_blocks_logo_grid_logos_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_logo_grid_logos
    ADD CONSTRAINT pages_blocks_logo_grid_logos_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages_blocks_logo_grid(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_logo_grid pages_blocks_logo_grid_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_logo_grid
    ADD CONSTRAINT pages_blocks_logo_grid_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_media_panel pages_blocks_media_panel_background_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_media_panel
    ADD CONSTRAINT pages_blocks_media_panel_background_image_id_media_id_fk FOREIGN KEY (background_image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: pages_blocks_media_panel pages_blocks_media_panel_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_media_panel
    ADD CONSTRAINT pages_blocks_media_panel_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_prices_and_limits pages_blocks_prices_and_limits_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_prices_and_limits
    ADD CONSTRAINT pages_blocks_prices_and_limits_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_profile_grid pages_blocks_profile_grid_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_profile_grid
    ADD CONSTRAINT pages_blocks_profile_grid_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_profile_grid_people pages_blocks_profile_grid_people_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_profile_grid_people
    ADD CONSTRAINT pages_blocks_profile_grid_people_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages_blocks_profile_grid(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_profile_grid_people pages_blocks_profile_grid_people_photo_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_profile_grid_people
    ADD CONSTRAINT pages_blocks_profile_grid_people_photo_id_media_id_fk FOREIGN KEY (photo_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: pages_blocks_representatives pages_blocks_representatives_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_representatives
    ADD CONSTRAINT pages_blocks_representatives_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_rich_text pages_blocks_rich_text_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_rich_text
    ADD CONSTRAINT pages_blocks_rich_text_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_step_phones pages_blocks_step_phones_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_step_phones
    ADD CONSTRAINT pages_blocks_step_phones_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_step_phones_steps pages_blocks_step_phones_steps_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_step_phones_steps
    ADD CONSTRAINT pages_blocks_step_phones_steps_image_id_media_id_fk FOREIGN KEY (image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: pages_blocks_step_phones_steps pages_blocks_step_phones_steps_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_step_phones_steps
    ADD CONSTRAINT pages_blocks_step_phones_steps_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages_blocks_step_phones(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_steps pages_blocks_steps_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_steps
    ADD CONSTRAINT pages_blocks_steps_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_steps_steps pages_blocks_steps_steps_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_steps_steps
    ADD CONSTRAINT pages_blocks_steps_steps_image_id_media_id_fk FOREIGN KEY (image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: pages_blocks_steps_steps pages_blocks_steps_steps_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_steps_steps
    ADD CONSTRAINT pages_blocks_steps_steps_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages_blocks_steps(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_video_list pages_blocks_video_list_dark_background_image_id_media_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_video_list
    ADD CONSTRAINT pages_blocks_video_list_dark_background_image_id_media_fk FOREIGN KEY (dark_background_image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: pages_blocks_video_list pages_blocks_video_list_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_video_list
    ADD CONSTRAINT pages_blocks_video_list_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_video_list_videos pages_blocks_video_list_videos_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_video_list_videos
    ADD CONSTRAINT pages_blocks_video_list_videos_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages_blocks_video_list(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_video pages_blocks_video_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_video
    ADD CONSTRAINT pages_blocks_video_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages_blocks_videos_with_tabs_marker pages_blocks_videos_with_tabs_marker_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages_blocks_videos_with_tabs_marker
    ADD CONSTRAINT pages_blocks_videos_with_tabs_marker_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: pages pages_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_created_by_id_users_id_fk FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: pages pages_og_image_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_og_image_id_media_id_fk FOREIGN KEY (og_image_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: pages pages_parent_id_pages_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_parent_id_pages_id_fk FOREIGN KEY (parent_id) REFERENCES public.pages(id) ON DELETE SET NULL;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_announcements_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_announcements_fk FOREIGN KEY (announcements_id) REFERENCES public.announcements(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_audit_logs_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_audit_logs_fk FOREIGN KEY (audit_logs_id) REFERENCES public.audit_logs(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_blog_posts_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_blog_posts_fk FOREIGN KEY (blog_posts_id) REFERENCES public.blog_posts(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_campaigns_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_campaigns_fk FOREIGN KEY (campaigns_id) REFERENCES public.campaigns(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_categories_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_categories_fk FOREIGN KEY (categories_id) REFERENCES public.categories(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_cookie_rows_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_cookie_rows_fk FOREIGN KEY (cookie_rows_id) REFERENCES public.cookie_rows(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_documents_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_documents_fk FOREIGN KEY (documents_id) REFERENCES public.documents(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_faq_items_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_faq_items_fk FOREIGN KEY (faq_items_id) REFERENCES public.faq_items(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_fee_rows_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_fee_rows_fk FOREIGN KEY (fee_rows_id) REFERENCES public.fee_rows(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_feedback_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_feedback_fk FOREIGN KEY (feedback_id) REFERENCES public.feedback(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_legal_pages_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_legal_pages_fk FOREIGN KEY (legal_pages_id) REFERENCES public.legal_pages(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_limit_tables_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_limit_tables_fk FOREIGN KEY (limit_tables_id) REFERENCES public.limit_tables(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_media_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_media_fk FOREIGN KEY (media_id) REFERENCES public.media(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_nav_links_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_nav_links_fk FOREIGN KEY (nav_links_id) REFERENCES public.nav_links(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_page_meta_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_page_meta_fk FOREIGN KEY (page_meta_id) REFERENCES public.page_meta(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_pages_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_pages_fk FOREIGN KEY (pages_id) REFERENCES public.pages(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_parent_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_parent_fk FOREIGN KEY (parent_id) REFERENCES public.payload_locked_documents(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_representatives_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_representatives_fk FOREIGN KEY (representatives_id) REFERENCES public.representatives(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_translations_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_translations_fk FOREIGN KEY (translations_id) REFERENCES public.translations(id) ON DELETE CASCADE;


--
-- Name: payload_locked_documents_rels payload_locked_documents_rels_users_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_locked_documents_rels
    ADD CONSTRAINT payload_locked_documents_rels_users_fk FOREIGN KEY (users_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: payload_preferences_rels payload_preferences_rels_parent_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_preferences_rels
    ADD CONSTRAINT payload_preferences_rels_parent_fk FOREIGN KEY (parent_id) REFERENCES public.payload_preferences(id) ON DELETE CASCADE;


--
-- Name: payload_preferences_rels payload_preferences_rels_users_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payload_preferences_rels
    ADD CONSTRAINT payload_preferences_rels_users_fk FOREIGN KEY (users_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: representatives representatives_created_by_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.representatives
    ADD CONSTRAINT representatives_created_by_id_users_id_fk FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: representatives representatives_qr_code_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.representatives
    ADD CONSTRAINT representatives_qr_code_id_media_id_fk FOREIGN KEY (qr_code_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: users users_avatar_id_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_avatar_id_media_id_fk FOREIGN KEY (avatar_id) REFERENCES public.media(id) ON DELETE SET NULL;


--
-- Name: users users_delegate_to_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_delegate_to_id_users_id_fk FOREIGN KEY (delegate_to_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: users_sessions users_sessions_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_sessions
    ADD CONSTRAINT users_sessions_parent_id_fk FOREIGN KEY (_parent_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--


