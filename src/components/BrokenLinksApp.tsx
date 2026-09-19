"use client";

import { useCallback, useEffect, useState } from "react";
import { useAdminLocale } from "./useAdminLocale";
import { TableSkeleton } from "./TableSkeleton";
import { BusyButton, EmptyState, ErrorState, LoadingState, useBusyAction } from "./AdminStates";
import { formatIstanbul } from "@/lib/istanbulTime";

/**
 * Kırık Linkler (18.09.2026) — two lists on one screen:
 * 1. İçerikteki kırık linkler: runs /api/broken-links/scan on demand.
 * 2. 404 alan adresler: what visitors actually hit (collections/NotFoundHits.ts).
 * Every source row links straight to the record that holds the link.
 */

type Source = { collection: string; id?: string; global?: string; title: string; field: string; adminUrl: string };
type Broken = { target: string; type: "internal" | "external" | "doc" | "invalid"; status?: number; reason: string; sources: Source[] };
type Scan = { checkedAt: string; siteOrigin: string; external: boolean; counts: { links: number; internal: number; external: number; broken: number }; broken: Broken[] };
type Hit = { id: string | number; path: string; count?: number; lastSeenAt?: string; lastReferrer?: string; ignored?: boolean };

const STRINGS = {
  tr: {
    title: "Kırık Linkler",
    intro:
      "Sitedeki kırık linkleri iki yerden toplar: yayındaki içeriklerde geçen linkler (taramayla) ve ziyaretçilerin gerçekten '404 — sayfa bulunamadı' aldığı adresler. Düzeltmek için satırdaki kayda gidin.",
    scanTitle: "İçerikteki kırık linkler",
    scanHint: "Menü linkleri, kampanyalar, blog yazıları, sayfalar, SSS, duyurular, hukuki sayfalar, footer ve iletişim bilgilerindeki yayındaki linkler taranır; site içi adresler sitenin kendisine sorulur.",
    external: "Dış linkleri de kontrol et (CMS sunucusunun internete erişimi olmalı)",
    run: "Taramayı başlat",
    running: "Taranıyor…",
    scanningDetail: "Yayındaki her içerik ve içindeki her link kontrol ediliyor. Dış linkler açıksa bir dakikayı bulabilir; sayfadan ayrılmayın.",
    notRun: "Henüz tarama yapılmadı.",
    notRunHint: "“Taramayı başlat” ile yayındaki içeriklerdeki linkleri kontrol edin.",
    scanFailed: "Tarama tamamlanamadı",
    summary: (s: Scan) =>
      `${formatIstanbul(s.checkedAt)} (İstanbul): ${s.counts.links} link, ${s.counts.internal} farklı site içi adres${s.external ? `, ${s.counts.external} dış adres` : ""} kontrol edildi — ${s.counts.broken} kırık.`,
    allGood: "Kırık link bulunmadı.",
    colLink: "Link",
    colProblem: "Sorun",
    colWhere: "Nerede",
    reasons: {
      "not-found": (s?: number) => `Sayfa bulunamadı${s ? ` (${s})` : ""}`,
      "server-error": (s?: number) => `Sunucu hatası${s ? ` (${s})` : ""}`,
      unreachable: () => "Ulaşılamadı",
      "private-address": () => "İç ağ adresi — ziyaretçiler açamaz, kontrol edilmedi",
      unpublished: () => "Bağlı içerik yayında değil",
      deleted: () => "Bağlı içerik silinmiş",
      relative: () => "Adres '/' ya da 'https://' ile başlamıyor",
    } as Record<string, (s?: number) => string>,
    types: { internal: "site içi", external: "dış", doc: "CMS içeriği", invalid: "geçersiz" } as Record<string, string>,
    hitsTitle: "404 alan adresler",
    hitsHint:
      "Sitede 'sayfa bulunamadı' ile karşılaşılan adresler, en çok alınandan başlayarak. 'Geldiği sayfa' sitenin kendi sayfasıysa o sayfada kırık bir link vardır.",
    showIgnored: "Yok sayılanları da göster",
    colPath: "Adres",
    colCount: "Sayı",
    colLast: "Son görülme (İstanbul)",
    colFrom: "Geldiği sayfa",
    fromSite: "site içinden",
    ignore: "Yok say",
    unignore: "Geri al",
    noHits: "Kayıtlı 404 yok.",
    noHitsHint: "Ziyaretçiler sitede bulunamayan bir adrese gittiğinde burada listelenir.",
    failed: "Yüklenemedi.",
    hitsFailed: "404 kayıtları yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.",
    ignoring: "Kaydediliyor…",
  },
  en: {
    title: "Broken Links",
    intro:
      "Collects broken links from two places: links in published content (by scanning) and addresses where visitors actually got '404 — page not found'. Open the record in a row to fix it.",
    scanTitle: "Broken links in content",
    scanHint:
      "Published links in nav links, campaigns, blog posts, pages, FAQ, announcements, legal pages, the footer and contact info are scanned; site addresses are checked against the site itself.",
    external: "Also check external links (the CMS server needs internet access)",
    run: "Run scan",
    running: "Scanning…",
    scanningDetail: "Every published record and every link in it is being checked. With external links on this can take a minute; stay on this page.",
    notRun: "No scan yet.",
    notRunHint: "Use “Run scan” to check the links in published content.",
    scanFailed: "The scan didn't finish",
    summary: (s: Scan) =>
      `${formatIstanbul(s.checkedAt)} (Istanbul): ${s.counts.links} links, ${s.counts.internal} distinct site addresses${s.external ? `, ${s.counts.external} external addresses` : ""} checked — ${s.counts.broken} broken.`,
    allGood: "No broken links found.",
    colLink: "Link",
    colProblem: "Problem",
    colWhere: "Where",
    reasons: {
      "not-found": (s?: number) => `Page not found${s ? ` (${s})` : ""}`,
      "server-error": (s?: number) => `Server error${s ? ` (${s})` : ""}`,
      unreachable: () => "Unreachable",
      "private-address": () => "Internal network address — visitors can't open it, not checked",
      unpublished: () => "Linked content isn't published",
      deleted: () => "Linked content was deleted",
      relative: () => "Doesn't start with '/' or 'https://'",
    } as Record<string, (s?: number) => string>,
    types: { internal: "site", external: "external", doc: "CMS content", invalid: "invalid" } as Record<string, string>,
    hitsTitle: "Addresses that returned 404",
    hitsHint: "Addresses where the site said 'page not found', most frequent first. If the referring page is one of the site's own, that page has a broken link.",
    showIgnored: "Show ignored too",
    colPath: "Address",
    colCount: "Count",
    colLast: "Last seen (Istanbul)",
    colFrom: "Referring page",
    fromSite: "from the site",
    ignore: "Ignore",
    unignore: "Restore",
    noHits: "No 404s recorded.",
    noHitsHint: "Addresses visitors open that don't exist on the site show up here.",
    failed: "Couldn't load.",
    hitsFailed: "Couldn't load the 404 records. Check your connection and try again.",
    ignoring: "Saving…",
  },
};

const SITE_REFERRER = /^https?:\/\/(www\.)?vodafonepay\.com\.tr(\/|$)|^https?:\/\/localhost(:\d+)?(\/|$)|^https?:\/\/vodafonepaycomtr[^/]*(\/|$)/i;

export default function BrokenLinksApp() {
  const locale = useAdminLocale();
  const t = STRINGS[locale] ?? STRINGS.tr;

  const [external, setExternal] = useState(false);
  const [scan, setScan] = useState<Scan | null>(null);
  const [scanError, setScanError] = useState<string | null>(null);
  const scanAction = useBusyAction();
  const scanning = scanAction.busy;

  const [hits, setHits] = useState<Hit[] | null>(null);
  const [hitsError, setHitsError] = useState(false);
  const [showIgnored, setShowIgnored] = useState(false);
  const rowAction = useBusyAction();

  const runScan = () =>
    scanAction.run(async () => {
      setScanError(null);
      try {
        const res = await fetch(`/api/broken-links/scan${external ? "?external=1" : ""}`, { credentials: "include" });
        if (!res.ok) {
          const body = (await res.json().catch(() => null)) as { errors?: { message?: string }[] } | null;
          setScanError(body?.errors?.[0]?.message ?? t.failed);
          return;
        }
        setScan((await res.json()) as Scan);
      } catch {
        // Network drop / proxy timeout: used to be an unhandled rejection
        // that left the old result on screen with no word of the failure.
        setScanError(t.failed);
      }
    });

  // A failed request is shown as a failure, not as "no 404s recorded".
  const loadHits = useCallback(async () => {
    const params = new URLSearchParams({ depth: "0", limit: "200", sort: "-count" });
    if (!showIgnored) params.append("where[ignored][not_equals]", "true");
    try {
      const res = await fetch(`/api/not-found-hits?${params.toString()}`, { credentials: "include" });
      if (!res.ok) throw new Error(String(res.status));
      setHits(((await res.json()) as { docs: Hit[] }).docs);
      setHitsError(false);
    } catch {
      setHitsError(true);
    }
  }, [showIgnored]);

  useEffect(() => {
    let cancelled = false;
    Promise.resolve().then(() => {
      if (!cancelled) void loadHits();
    });
    return () => {
      cancelled = true;
    };
  }, [loadHits]);

  const toggleIgnore = (hit: Hit) =>
    rowAction.run(async () => {
      await fetch(`/api/not-found-hits/${hit.id}/ignore`, {
        method: "POST",
        credentials: "include",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ ignored: !hit.ignored }),
      }).catch(() => null);
      await loadHits();
    }, String(hit.id));

  return (
    <div className="cm blk">
      <h1>{t.title}</h1>
      <p className="cm-hint">{t.intro}</p>

      <section className="blk-section">
        <h2 className="cm-section-title">{t.scanTitle}</h2>
        <p className="cm-hint">{t.scanHint}</p>
        <div className="blk-controls">
          <BusyButton variant="primary" busy={scanning} onClick={runScan} label={t.run} busyLabel={t.running} />
          <label className="blk-check" htmlFor="blk-external">
            <input id="blk-external" type="checkbox" checked={external} disabled={scanning} onChange={(e) => setExternal(e.target.checked)} />
            <span>{t.external}</span>
          </label>
        </div>
        {!scanning && scanError && <ErrorState title={t.scanFailed} message={scanError} onRetry={runScan} />}
        {scanning && <LoadingState label={t.running} detail={t.scanningDetail} showElapsed />}
        {!scanning && !scan && !scanError && <EmptyState title={t.notRun} hint={t.notRunHint} />}
        {!scanning && scan && (
          <>
            <p className={`blk-summary${scan.counts.broken === 0 ? " blk-summary--ok" : ""}`}>{t.summary(scan)}</p>
            {scan.broken.length === 0 ? (
              <EmptyState title={t.allGood} />
            ) : (
              <div className="table-wrap">
                <table className="cm-table blk-table">
                  <thead>
                    <tr>
                      <th>{t.colLink}</th>
                      <th>{t.colProblem}</th>
                      <th>{t.colWhere}</th>
                    </tr>
                  </thead>
                  <tbody>
                    {scan.broken.map((b) => (
                      <tr key={`${b.type}:${b.target}`}>
                        <td>
                          <code className="blk-url">{b.target}</code>
                          <span className="blk-type">{t.types[b.type]}</span>
                        </td>
                        <td>
                          <span className={`blk-reason blk-reason--${b.reason}`}>{t.reasons[b.reason]?.(b.status) ?? b.reason}</span>
                        </td>
                        <td>
                          <ul className="blk-sources">
                            {b.sources.map((s, i) => (
                              <li key={`${s.adminUrl}-${s.field}-${i}`}>
                                <a href={s.adminUrl}>{s.title}</a>
                                {s.field && <span className="blk-field"> — {s.field}</span>}
                              </li>
                            ))}
                          </ul>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </>
        )}
      </section>

      <section className="blk-section">
        <h2 className="cm-section-title">{t.hitsTitle}</h2>
        <p className="cm-hint">{t.hitsHint}</p>
        <label className="blk-check" htmlFor="blk-ignored">
          <input id="blk-ignored" type="checkbox" checked={showIgnored} onChange={(e) => setShowIgnored(e.target.checked)} />
          <span>{t.showIgnored}</span>
        </label>
        {hitsError ? (
          <ErrorState message={t.hitsFailed} onRetry={loadHits} />
        ) : hits === null ? (
          <TableSkeleton columns={5} />
        ) : hits.length === 0 ? (
          <EmptyState title={t.noHits} hint={t.noHitsHint} />
        ) : (
          <div className="table-wrap">
            <table className="cm-table blk-table">
              <thead>
                <tr>
                  <th>{t.colPath}</th>
                  <th>{t.colCount}</th>
                  <th>{t.colLast}</th>
                  <th>{t.colFrom}</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {hits.map((h) => (
                  <tr key={h.id} className={h.ignored ? "blk-ignored" : undefined}>
                    <td>
                      <code className="blk-url">{h.path}</code>
                    </td>
                    <td className="blk-num">{h.count ?? 0}</td>
                    <td>{h.lastSeenAt ? formatIstanbul(h.lastSeenAt) : "—"}</td>
                    <td>
                      {h.lastReferrer ? (
                        <>
                          <code className="blk-url">{h.lastReferrer}</code>
                          {SITE_REFERRER.test(h.lastReferrer) && <span className="blk-type blk-type--site">{t.fromSite}</span>}
                        </>
                      ) : (
                        "—"
                      )}
                    </td>
                    <td>
                      <BusyButton
                        busy={rowAction.isBusy(String(h.id))}
                        onClick={() => toggleIgnore(h)}
                        label={h.ignored ? t.unignore : t.ignore}
                        busyLabel={t.ignoring}
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </div>
  );
}
