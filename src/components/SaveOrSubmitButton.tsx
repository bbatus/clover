"use client";

import { useCallback } from "react";
import { useAuth, useConfig, useDocumentInfo, useForm, useLocale } from "@payloadcms/ui";
import { formatAdminURL } from "payload/shared";
import { useAdminLocale } from "./useAdminLocale";
import { useDbStrings } from "./useDbStrings";
import { ROLES } from "@/access/roleConstants";

/** Same set of collections that set `versions.drafts.validate: true` server-side — see Campaigns.ts. */
const COLLECTIONS_WITH_DRAFT_VALIDATION = new Set(["campaigns"]);

/**
 * RFP feedback: "taslağı kaydet dedi mesela onaya gönder demesi lazımdı" —
 * a Growth Maker's own draft save reads as "just saving," with no signal
 * that clicking it is what actually sends the campaign to a Checker for
 * review. Replaces Payload's default SaveDraftButton (same submit logic,
 * copied from its source) with an identical action but a role-conditional
 * label: "Taslağı Onaya Gönder" for the one role that can never publish here
 * (Growth Maker), the normal "Taslağı Kaydet" for everyone else.
 *
 * Follow-up 30.08: that label was originally just "Onaya Gönder" — a real
 * Growth Maker looked straight at this button and reported "there's no
 * save-draft button anywhere," because the text named only the consequence
 * (goes to review) with nothing saying the action itself saves their work.
 * Naming both fixed it.
 */
export default function SaveOrSubmitButton() {
  const { user } = useAuth();
  const role = (user as { role?: string } | undefined)?.role;
  const locale = useAdminLocale();
  const t = useDbStrings(locale);

  const { id, collectionSlug, globalSlug, setUnpublishedVersionCount, uploadStatus } = useDocumentInfo();
  const { submit } = useForm();
  const { code: localeCode } = useLocale();
  const { config } = useConfig();

  const disabled = uploadStatus === "uploading";

  const saveDraft = useCallback(async () => {
    if (disabled) return;
    const search = `?locale=${localeCode}&depth=0&fallback-locale=null&draft=true`;
    const idSegment = id ? `/${id}` : "";
    const path = globalSlug ? `/globals/${globalSlug}${search}` : `/${collectionSlug}${idSegment}${search}`;
    const action = formatAdminURL({ apiRoute: config.routes.api, path: path as `/${string}` });
    // 02.09.2026 kullanıcı geri bildirimi: bir Growth Maker taslağını
    // kaydedemiyordu (örn. henüz medya eklemediği bir Sayfa) — Payload'ın
    // kendi varsayılan SaveDraftButton'ı draft kaydında her zaman
    // `skipValidation: true` gönderir (bkz. @payloadcms/ui
    // elements/SaveDraftButton), bu sarmalayıcı onu unutmuştu ve
    // client-side zorunlu-alan doğrulaması save'i tamamen engelliyordu —
    // sunucu tarafında (versions.drafts.validate) izin verilse bile.
    // Campaigns bilinçli olarak `versions.drafts.validate: true` ile
    // taslakta da zorunlu alan istiyor (bkz. Campaigns.ts) — client
    // tarafını da onunla tutarlı tutuyoruz, diğer her koleksiyonda
    // (validate:true DEMEYEN) taslak serbestçe kaydedilebilsin diye.
    const skipValidation = !COLLECTIONS_WITH_DRAFT_VALIDATION.has(collectionSlug ?? "");
    await submit({ action, method: id ? "PATCH" : "POST", overrides: { _status: "draft" }, skipValidation });
    setUnpublishedVersionCount((count) => count + 1);
  }, [disabled, globalSlug, collectionSlug, id, localeCode, config.routes.api, submit, setUnpublishedVersionCount]);

  const label = role === ROLES.GROWTH_MAKER ? t("saveOrSubmit.submitForReview") : t("saveOrSubmit.saveDraft");
  const disabledClass = disabled ? " btn--disabled" : "";

  return (
    <button
      type="button"
      className={`btn btn--style-secondary btn--size-medium${disabledClass}`}
      disabled={disabled}
      onClick={() => void saveDraft()}
    >
      <span className="btn__content">
        <span className="btn__label">{label}</span>
      </span>
    </button>
  );
}
