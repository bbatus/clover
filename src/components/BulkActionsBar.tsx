"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { Button, useAuth, useConfig, useRouteCache, useSelection } from "@payloadcms/ui";
import type { Where } from "payload";
import { useAdminLocale } from "./useAdminLocale";
import { useIsActiveCheckerDelegate } from "./useIsActiveCheckerDelegate";
import { ROLES } from "@/access/roleConstants";
import { LoadingState, VfSpinner, useBusyAction } from "./AdminStates";
import { describeApiError } from "@/lib/apiErrorMessage";
import { BULK_MAX_IDS, bulkActionsFor, type BulkAction, type BulkResponse } from "@/lib/bulkActionRules";

/**
 * Toplu işlemler (18.09.2026) — the bar above a list table once rows are
 * selected, wired into `admin.components.beforeListTable` on every
 * drafts-enabled collection (lib/bulkActionRules.ts → `bulkActionsBar`).
 *
 * Replaces Payload's own bulk Publish / Unpublish / Delete (switched off with
 * `disableBulkEdit`/`disableBulkDelete`), which derive only from collection
 * access and so offered a Growth Maker a bulk "Yayınla" that could only 403,
 * and reported results as one generic toast. Here:
 * - the buttons come from `bulkActionsFor`, the same function the server uses,
 *   so a role never sees a control the server will refuse;
 * - everything goes to `POST /api/bulk-actions` (lib/bulkActions.ts), which
 *   saves each record as this user through the collections' own hooks;
 * - the answer is shown per record: done / skipped / refused, with the
 *   server's own reason, until the editor closes it.
 * Payload's bulk "Düzenle" is gone on these collections — see `bulkActionsFor`
 * for why.
 */

type Props = { collection: string };

/** Payload's `SelectAllStatus.AllAvailable` — the enum itself isn't exported from @payloadcms/ui. */
const ALL_AVAILABLE = "allAvailable";

const STRINGS = {
  tr: {
    selected: (n: number) => `${n} kayıt seçildi`,
    actions: {
      publish: "Seçilenleri yayınla",
      unpublish: "Seçilenleri yayından kaldır",
      requestUnpublish: "Yayından kaldırma talebi oluştur",
      deleteDraft: "Seçili taslakları çöp kutusuna taşı",
    } satisfies Record<BulkAction, string>,
    confirmTitle: {
      publish: (n: number) => `${n} kayıt yayınlansın mı?`,
      unpublish: (n: number) => `${n} kayıt yayından kaldırılsın mı?`,
      requestUnpublish: (n: number) => `${n} kampanya için yayından kaldırma talebi oluşturulsun mu?`,
      deleteDraft: (n: number) => `${n} taslak çöp kutusuna taşınsın mı?`,
    } satisfies Record<BulkAction, (n: number) => string>,
    confirmBody: {
      publish:
        "Her kayıt sizin yetkinizle tek tek yayınlanır; tek kayıt yayınlarken geçerli olan tüm kurallar burada da geçerli. Kurala takılan kayıtlar yayınlanmaz, sonuç listesinde nedeniyle gösterilir.",
      unpublish: "Seçili kayıtlar siteden kalkar ve taslağa döner. Zaten yayında olmayanlar atlanır.",
      requestUnpublish:
        "Seçili yayındaki kampanyalar için talep açılır; kampanyalar bir Checker onaylayıp yayından kaldırana kadar yayında kalır.",
      deleteDraft: "Seçili taslaklar çöp kutusuna taşınır; oradan geri alınabilir. Yayındaki kayıtlar atlanır.",
    } satisfies Record<BulkAction, string>,
    campaignPublishNote: "Belirli bir tarihe planlanmış ve reddedilmiş kampanyalar atlanır.",
    growthMakerDeleteNote: "Yalnızca kendi oluşturduğunuz taslaklar taşınır.",
    // 19.09.2026 — second, explicit statement before a bulk publish (also required by the server).
    reviewAck: (n: number) => `Seçili ${n} kaydın her birini incelediğimi ve yayına alınmasını onayladığımı beyan ederim.`,
    confirm: "Evet, devam et",
    cancel: "Vazgeç",
    running: "İşleniyor…",
    progress: (n: number) => `${n} kayıt tek tek işleniyor. Bitene kadar bu pencereyi kapatmayın.`,
    resultTitle: {
      publish: "Toplu yayınlama sonucu",
      unpublish: "Toplu yayından kaldırma sonucu",
      requestUnpublish: "Toplu yayından kaldırma talebi sonucu",
      deleteDraft: "Çöp kutusuna taşıma sonucu",
    } satisfies Record<BulkAction, string>,
    counts: (ok: number, skipped: number, failed: number) => `${ok} başarılı · ${skipped} atlandı · ${failed} başarısız`,
    status: { ok: "Başarılı", skipped: "Atlandı", failed: "Başarısız" },
    colRecord: "Kayıt",
    colResult: "Sonuç",
    colReason: "Açıklama",
    close: "Kapat",
    tooMany: (max: number) => `Tek seferde en fazla ${max} kayıt işlenebilir. Filtreyle seçimi daraltın.`,
    loadFailed: "Seçili kayıtlar alınamadı.",
  },
  en: {
    selected: (n: number) => `${n} selected`,
    actions: {
      publish: "Publish selected",
      unpublish: "Unpublish selected",
      requestUnpublish: "Request unpublish",
      deleteDraft: "Move selected drafts to the trash",
    } satisfies Record<BulkAction, string>,
    confirmTitle: {
      publish: (n: number) => `Publish ${n} record(s)?`,
      unpublish: (n: number) => `Unpublish ${n} record(s)?`,
      requestUnpublish: (n: number) => `Request unpublishing for ${n} campaign(s)?`,
      deleteDraft: (n: number) => `Move ${n} draft(s) to the trash?`,
    } satisfies Record<BulkAction, (n: number) => string>,
    confirmBody: {
      publish:
        "Each record is published one by one with your own rights; every rule that applies to publishing a single record applies here. Records a rule refuses are not published and are listed with the reason.",
      unpublish: "The selected records come off the site and go back to draft. Records that aren't live are skipped.",
      requestUnpublish: "A request is filed for each selected live campaign; they stay live until a Checker approves and unpublishes them.",
      deleteDraft: "The selected drafts go to the trash, where they can be restored. Live records are skipped.",
    } satisfies Record<BulkAction, string>,
    campaignPublishNote: "Campaigns scheduled for a specific time, and rejected ones, are skipped.",
    growthMakerDeleteNote: "Only drafts you created are moved.",
    reviewAck: (n: number) => `I confirm I have reviewed each of the ${n} selected records and approve publishing them.`,
    confirm: "Yes, continue",
    cancel: "Cancel",
    running: "Working…",
    progress: (n: number) => `Processing ${n} records one by one. Keep this window open until it finishes.`,
    resultTitle: {
      publish: "Bulk publish result",
      unpublish: "Bulk unpublish result",
      requestUnpublish: "Bulk unpublish request result",
      deleteDraft: "Move to trash result",
    } satisfies Record<BulkAction, string>,
    counts: (ok: number, skipped: number, failed: number) => `${ok} done · ${skipped} skipped · ${failed} failed`,
    status: { ok: "Done", skipped: "Skipped", failed: "Failed" },
    colRecord: "Record",
    colResult: "Result",
    colReason: "Details",
    close: "Close",
    tooMany: (max: number) => `At most ${max} records can be processed at once. Narrow the selection with a filter.`,
    loadFailed: "Couldn't load the selected records.",
  },
};

export default function BulkActionsBar({ collection }: Props) {
  const locale = useAdminLocale();
  const t = STRINGS[locale];
  const { count, selectedIDs, selectAll, getQueryParams, toggleAll, totalDocs } = useSelection();
  const { user, permissions } = useAuth();
  const { config, getEntityConfig } = useConfig();
  const { clearRouteCache } = useRouteCache();
  const router = useRouter();
  const searchParams = useSearchParams();
  // The Çöp (trash) list has its own restore / permanent-delete controls;
  // publishing or trashing a trashed record makes no sense there.
  const inTrashView = /\/trash\/?$/.test(usePathname() ?? "");

  const role = (user as { role?: string } | undefined)?.role;
  const userId = (user as { id?: string | number } | undefined)?.id;
  const isActiveDelegate = useIsActiveCheckerDelegate(role, userId);
  const collectionPermissions = permissions?.collections?.[collection];
  const actions = useMemo(
    () =>
      bulkActionsFor({
        role,
        collection,
        canUpdate: Boolean(collectionPermissions?.update),
        canDelete: Boolean(collectionPermissions?.delete),
        isActiveDelegate,
      }),
    [role, collection, collectionPermissions?.update, collectionPermissions?.delete, isActiveDelegate]
  );
  const clientCollection = getEntityConfig({ collectionSlug: collection });

  const [confirming, setConfirming] = useState<BulkAction | null>(null);
  const [reviewAck, setReviewAck] = useState(false);
  // Ref-guarded (AdminStates.useBusyAction): a fast double click on
  // "Evet, devam et" can no longer send the same bulk request twice.
  const { run: runOnce, busy: running } = useBusyAction();
  const [result, setResult] = useState<BulkResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  const selectedCount = selectAll === ALL_AVAILABLE ? totalDocs : count;

  useEffect(() => {
    if (!confirming) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape" && !running) setConfirming(null);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [confirming, running]);

  /**
   * "Select all N across pages" only flips a flag in Payload's selection — the
   * ids are never loaded. Resolve them here against the same filter (and list
   * search) the list is showing, capped like the server.
   */
  const resolveIds = useCallback(async (): Promise<string[]> => {
    if (selectAll !== ALL_AVAILABLE) return selectedIDs.map(String);
    const search = searchParams?.get("search");
    const admin = (clientCollection as { admin?: { useAsTitle?: string; listSearchableFields?: string[] } } | undefined)?.admin;
    const fields = admin?.listSearchableFields?.length ? admin.listSearchableFields : [admin?.useAsTitle ?? "id"];
    const extra: Where | undefined = search ? { or: fields.map((f) => ({ [f]: { like: search } })) } : undefined;
    const query = getQueryParams(extra);
    const sep = query ? "&" : "?";
    const res = await fetch(`/api/${collection}${query}${sep}limit=${BULK_MAX_IDS + 1}&depth=0&draft=true&select[id]=true`, {
      credentials: "same-origin",
    });
    if (!res.ok) throw new Error(t.loadFailed);
    const data = (await res.json()) as { docs?: { id: string | number }[] };
    return (data.docs ?? []).map((d) => String(d.id));
  }, [selectAll, selectedIDs, searchParams, clientCollection, getQueryParams, collection, t.loadFailed]);

  const run = useCallback(
    (action: BulkAction) =>
      runOnce(async () => {
        setError(null);
        try {
          const ids = await resolveIds();
          if (ids.length > BULK_MAX_IDS) {
            setError(t.tooMany(BULK_MAX_IDS));
            return;
          }
          const res = await fetch("/api/bulk-actions", {
            method: "POST",
            credentials: "same-origin",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ collection, action, ids, ...(action === "publish" ? { reviewConfirmed: true } : {}) }),
          });
          const body = (await res.json().catch(() => null)) as unknown;
          if (!res.ok) {
            setError(describeApiError({ status: res.status, body, locale, context: "generic" }));
            return;
          }
          setResult(body as BulkResponse);
          // Clear the selection (the rows it pointed at may be gone or changed)
          // and re-render the table from the server.
          toggleAll();
          clearRouteCache();
          router.refresh();
        } catch (err) {
          setError(err instanceof Error && err.message ? err.message : describeApiError({ err, locale, context: "generic" }));
        } finally {
          setConfirming(null);
        }
      }),
    [runOnce, resolveIds, t, collection, locale, toggleAll, clearRouteCache, router]
  );

  const showBar = !inTrashView && selectedCount > 0 && actions.length > 0;
  if (!showBar && !result && !error) return null;

  const adminRoute = config.routes.admin;
  const notes: string[] = [];
  if (confirming === "publish" && collection === "campaigns") notes.push(t.campaignPublishNote);
  if (confirming === "deleteDraft" && role === ROLES.GROWTH_MAKER) notes.push(t.growthMakerDeleteNote);

  return (
    <div className="bulk">
      {showBar && (
        <div className="bulk-bar" role="toolbar" aria-label={t.selected(selectedCount)}>
          <span className="bulk-count">{t.selected(selectedCount)}</span>
          <div className="bulk-buttons">
            {actions.map((action) => (
              <Button
                key={action}
                buttonStyle="secondary"
                className={action === "deleteDraft" ? "bulk-danger" : undefined}
                size="small"
                disabled={running}
                onClick={() => {
                  setReviewAck(false);
                  setConfirming(action);
                }}
              >
                {t.actions[action]}
              </Button>
            ))}
          </div>
        </div>
      )}

      {error && (
        <div className="bulk-error" role="alert">
          <span>{error}</span>
          <button type="button" className="bulk-link" onClick={() => setError(null)}>
            {t.close}
          </button>
        </div>
      )}

      {result && (
        <section className="bulk-result" aria-live="polite">
          <div className="bulk-result-head">
            <div>
              <strong>{t.resultTitle[result.action]}</strong>
              <span className="bulk-result-counts">{t.counts(result.counts.ok, result.counts.skipped, result.counts.failed)}</span>
            </div>
            <button type="button" className="bulk-link" onClick={() => setResult(null)}>
              {t.close}
            </button>
          </div>
          <table className="bulk-table">
            <thead>
              <tr>
                <th>{t.colRecord}</th>
                <th>{t.colResult}</th>
                <th>{t.colReason}</th>
              </tr>
            </thead>
            <tbody>
              {result.results.map((row) => (
                <tr key={row.id}>
                  <td>
                    {result.action === "deleteDraft" && row.status === "ok" ? (
                      <span>{row.title}</span>
                    ) : (
                      <a href={`${adminRoute}/collections/${collection}/${row.id}`}>{row.title}</a>
                    )}
                  </td>
                  <td>
                    <span className={`bulk-chip bulk-chip--${row.status}`}>{t.status[row.status]}</span>
                  </td>
                  <td className="bulk-reason">{row.status === "ok" ? "" : row.message}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      )}

      {confirming && (
        <div className="rapb-modal-overlay" role="dialog" aria-modal="true" aria-labelledby="bulk-confirm-title">
          <div className="rapb-modal">
            <h2 id="bulk-confirm-title" className="rapb-modal-title">
              {t.confirmTitle[confirming](selectedCount)}
            </h2>
            <p className="bulk-confirm-body">{t.confirmBody[confirming]}</p>
            {notes.map((note) => (
              <p key={note} className="bulk-confirm-note">
                {note}
              </p>
            ))}
            {running && <LoadingState label={t.running} detail={t.progress(selectedCount)} showElapsed compact />}
            {confirming === "publish" && (
              <label className="rapb-ack" htmlFor="bulk-review-ack">
                <input id="bulk-review-ack" type="checkbox" checked={reviewAck} disabled={running} onChange={(e) => setReviewAck(e.target.checked)} />
                <span>{t.reviewAck(selectedCount)}</span>
              </label>
            )}
            <div className="rapb-modal-actions">
              <Button buttonStyle="secondary" size="small" disabled={running} onClick={() => setConfirming(null)}>
                {t.cancel}
              </Button>
              <Button
                buttonStyle={confirming === "deleteDraft" ? "error" : "primary"}
                size="small"
                disabled={running || (confirming === "publish" && !reviewAck)}
                onClick={() => void run(confirming)}
              >
                <span className="bulk-confirm-label">
                  {running && <VfSpinner size="s" />}
                  {running ? t.running : t.confirm}
                </span>
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
