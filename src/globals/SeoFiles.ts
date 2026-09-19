import type { GlobalConfig } from "payload";
import { revalidateGlobalTag } from "@/hooks/revalidate";
import { auditGlobalAfterChange } from "@/hooks/audit";
import { authenticated } from "@/access/authenticated";
import { denyMakerEditPublishedGlobal, denyMakerPublishGlobal, standardReadWrite } from "@/access/roles";
import { validateRobotsTxt } from "@/lib/robotsTxtValidation";

/**
 * 17.09.2026 kullanıcı: "robots.txt ve llms.txt'yi product ekibi de
 * değiştirebilsin, tek bir yerde dursun."
 *
 * The site serves both files straight from this record
 * (vodafonepaycomtr-site `src/app/robots.txt/route.ts`, `llms.txt/route.ts`).
 * Maker→checker like every other content screen: a crawler-facing file going
 * live unreviewed is exactly the kind of change the approval flow exists for.
 *
 * Safety nets, because a broken robots.txt fails silently:
 * - `Disallow: /` under `User-agent: *` is refused on publish (robotsTxtValidation;
 *   Payload skips field validation for draft saves, and the site only ever
 *   reads the published version)
 * - the `Sitemap:` line is added by the site from its own SITE_URL, so the
 *   test and production environments each point at their own sitemap
 * - an empty field falls back to the site's default file, never to an empty one
 *
 * No `defaultValue`: Payload would bake these multi-kilobyte texts into the
 * column DEFAULT, turning every wording change into a schema migration. The
 * starting content is inserted as data instead (migration §11 — see
 * `src/lib/seoFilesDefaults.ts`).
 */
export const SeoFiles: GlobalConfig = {
  slug: "seo-files",
  label: { tr: "SEO Dosyaları", en: "SEO Files" },
  admin: {
    hideAPIURL: true,
    group: { tr: "Site Yapısı", en: "Site Structure" },
    description: {
      tr: "Arama motorlarının ve yapay zekâ sistemlerinin okuduğu robots.txt ve llms.txt dosyaları. Değişiklikler onaydan (yayınla) sonra sitede /robots.txt ve /llms.txt adreslerinde görünür.",
      en: "The robots.txt and llms.txt files read by search engines and AI systems. Changes show on the site at /robots.txt and /llms.txt once approved (published).",
    },
    components: {
      elements: {
        beforeDocumentControls: [{ path: "/components/HelpButton#default", clientProps: { collection: "seo-files" } }],
        PublishButton: "/components/MakerAwarePublishButton#default",
        SaveDraftButton: "/components/SaveOrSubmitButton#default",
      },
    },
  },
  versions: {
    drafts: true,
  },
  access: {
    read: () => true,
    readVersions: authenticated,
    update: standardReadWrite,
  },
  fields: [
    {
      name: "robotsTxt",
      // 19.09.2026: textarea, not "code" — Payload's code field loads the
      // Monaco editor from cdn.jsdelivr.net at runtime, which an OpenShift pod
      // without internet egress can't reach (the field would never render) and
      // which the CMS Content-Security-Policy now blocks. Same varchar column.
      type: "textarea",
      label: { tr: "robots.txt", en: "robots.txt" },
      admin: {
        rows: 16,
        className: "field-monospace",
        description: {
          tr: "Arama motoru botlarının hangi adresleri tarayabileceğini belirler. 'Sitemap:' satırını yazmayın — site kendi adresiyle otomatik ekler. Güvenlik için 'User-agent: *' altında 'Disallow: /' (sitenin tamamını kapatmak) yayınlanamaz. Boş bırakılırsa sitenin varsayılan dosyası kullanılır.",
          en: "Controls which addresses search engine bots may crawl. Don't write a 'Sitemap:' line — the site adds it with its own address. For safety, 'Disallow: /' under 'User-agent: *' (closing the whole site) can't be published. Left empty, the site's default file is used.",
        },
      },
      validate: (value: unknown, { req }: { req: { i18n?: { language?: string } } }) =>
        validateRobotsTxt(value, req?.i18n?.language === "en" ? "en" : "tr"),
    },
    {
      name: "llmsTxt",
      type: "textarea",
      label: { tr: "llms.txt", en: "llms.txt" },
      admin: {
        rows: 24,
        className: "field-monospace",
        description: {
          tr: "ChatGPT, Perplexity gibi yapay zekâ sistemlerine sitenin ne olduğunu ve önemli sayfalarını anlatan Markdown dosyası. Yeni bir ürün sayfası eklendiğinde buraya da bir satır eklemek iyi olur. Boş bırakılırsa sitenin varsayılan dosyası kullanılır.",
          en: "Markdown file telling AI systems such as ChatGPT and Perplexity what the site is and which pages matter. Worth adding a line here when a new product page goes live. Left empty, the site's default file is used.",
        },
      },
    },
  ],
  hooks: {
    beforeChange: [denyMakerEditPublishedGlobal, denyMakerPublishGlobal],
    afterChange: [revalidateGlobalTag("seo-files"), auditGlobalAfterChange("seo-files")],
  },
};
