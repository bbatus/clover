import type { Payload, PayloadRequest } from "payload";
import type { I18nClient } from "@payloadcms/translations";
import { DefaultTemplate } from "@payloadcms/next/templates";
import { loadDbStrings } from "@/lib/loadDbStrings";
import BrokenLinksApp from "./BrokenLinksApp";

/**
 * Kırık Linkler (18.09.2026) — same top-level-view pattern as
 * FeesAndLimitsView (DefaultTemplate applied explicitly). The report itself is
 * BrokenLinksApp: a content scan (lib/brokenLinks.ts) and the site's 404 hits
 * (collections/NotFoundHits.ts). Read-only for every role; nothing here edits
 * content — each row links to the record to fix.
 */
export default async function BrokenLinksView(props: {
  payload: Payload;
  i18n: I18nClient;
  locale?: { code: string } | string;
  initPageResult?: {
    req?: PayloadRequest;
    permissions?: unknown;
    visibleEntities?: { collections?: string[]; globals?: string[] };
  };
}) {
  const { payload, i18n, initPageResult } = props;
  const user = (initPageResult?.req as PayloadRequest | undefined)?.user;
  const t = await loadDbStrings(payload, i18n.language === "en" ? "en" : "tr");
  const permissions = initPageResult?.permissions as Parameters<typeof DefaultTemplate>[0]["permissions"];
  const visibleEntities = (initPageResult?.visibleEntities ?? { collections: [], globals: [] }) as Parameters<
    typeof DefaultTemplate
  >[0]["visibleEntities"];
  const req = initPageResult?.req as PayloadRequest;

  return (
    <DefaultTemplate
      req={req}
      payload={payload}
      i18n={i18n}
      locale={props.locale as never}
      user={user as never}
      permissions={permissions}
      visibleEntities={visibleEntities}
      viewType="broken-links"
    >
      {user ? <BrokenLinksApp /> : <p className="cm-error">{t("contentManagement.loginRequired")}</p>}
    </DefaultTemplate>
  );
}
