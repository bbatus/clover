"use client";

import { useCallback, useEffect, useState } from "react";
import { useAuth, useDocumentInfo } from "@payloadcms/ui";
import { useAdminLocale } from "./useAdminLocale";
import { ROLES } from "@/access/roleConstants";
import { formatIstanbul } from "@/lib/istanbulTime";

/**
 * "Önizleme linki paylaş" (18.09.2026) — sidebar panel on Kampanyalar / Blog
 * Yazıları / Sayfalar. Creates a time-limited link someone without a CMS
 * account can open, lists this document's active links and revokes them.
 * All rules live on the server (collections/ShareLinks.ts); this only mirrors
 * who may revoke so it never shows a button the server would refuse.
 */

type LinkRow = {
  id: string | number;
  note?: string | null;
  expiresAt: string;
  viewCount?: number | null;
  lastViewedAt?: string | null;
  createdBy?: { id: string | number; email?: string } | string | number | null;
};

const DURATIONS = [1, 3, 7] as const;
const CAN_REVOKE_ANY = new Set<string>([ROLES.NEW_VERTICAL_MAKER, ROLES.NEW_VERTICAL_CHECKER, ROLES.GROWTH_CHECKER]);

const STRINGS = {
  tr: {
    title: "Önizleme linki paylaş",
    intro: "CMS hesabı olmayan birine (hukuk, pazarlama) bu içeriğin yayınlanmamış halini süreli bir linkle gösterin. Link yalnızca bu içeriği açar.",
    saveFirst: "Link oluşturmak için önce içeriği bir kez kaydedin.",
    duration: "Geçerlilik",
    days: (n: number) => `${n} gün`,
    note: "Kime / neden (opsiyonel)",
    notePlaceholder: "ör. Hukuk — Ayşe Y., koşul metni onayı",
    create: "Link oluştur",
    creating: "Oluşturuluyor…",
    created: "Link oluşturuldu. Bu link yalnızca şimdi gösterilir — kopyalayıp gönderin.",
    copy: "Kopyala",
    copied: "Kopyalandı",
    until: (d: string) => `${d} (İstanbul) tarihine kadar geçerli`,
    active: "Aktif linkler",
    none: "Bu içerik için aktif link yok.",
    views: (n: number) => `${n} kez açıldı`,
    by: "Oluşturan",
    revoke: "İptal et",
    revoking: "İptal ediliyor…",
    failed: "İşlem yapılamadı.",
  },
  en: {
    title: "Share a preview link",
    intro: "Show someone without a CMS account (legal, marketing) the unpublished version of this content with a time-limited link. The link opens only this content.",
    saveFirst: "Save the content once before creating a link.",
    duration: "Valid for",
    days: (n: number) => `${n} day${n > 1 ? "s" : ""}`,
    note: "For whom / why (optional)",
    notePlaceholder: "e.g. Legal — Ayşe Y., terms sign-off",
    create: "Create link",
    creating: "Creating…",
    created: "Link created. It is shown only now — copy it and send it.",
    copy: "Copy",
    copied: "Copied",
    until: (d: string) => `valid until ${d} (Istanbul)`,
    active: "Active links",
    none: "No active links for this content.",
    views: (n: number) => `opened ${n} time${n === 1 ? "" : "s"}`,
    by: "Created by",
    revoke: "Revoke",
    revoking: "Revoking…",
    failed: "That didn't work.",
  },
};

async function errorMessage(res: Response, fallback: string): Promise<string> {
  try {
    const body = (await res.json()) as { errors?: { message?: string }[] };
    return body.errors?.[0]?.message || fallback;
  } catch {
    return fallback;
  }
}

export default function SharePreviewPanel() {
  const locale = useAdminLocale();
  const t = STRINGS[locale] ?? STRINGS.tr;
  const { id, collectionSlug } = useDocumentInfo();
  const { user } = useAuth();
  const userId = (user as { id?: string | number } | null | undefined)?.id;
  const role = (user as { role?: string } | null | undefined)?.role ?? "";

  const [days, setDays] = useState<number>(3);
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [created, setCreated] = useState<{ url: string; expiresAt: string } | null>(null);
  const [copied, setCopied] = useState(false);
  const [links, setLinks] = useState<LinkRow[]>([]);
  const [revoking, setRevoking] = useState<string | number | null>(null);

  const load = useCallback(async () => {
    if (id === undefined || id === null || !collectionSlug) return;
    const params = new URLSearchParams({ depth: "1", limit: "20", sort: "-createdAt" });
    params.append("where[targetCollection][equals]", collectionSlug);
    params.append("where[targetId][equals]", String(id));
    params.append("where[revokedAt][exists]", "false");
    params.append("where[expiresAt][greater_than]", new Date().toISOString());
    const res = await fetch(`/api/share-links?${params.toString()}`, { credentials: "include" });
    if (res.ok) setLinks(((await res.json()) as { docs: LinkRow[] }).docs);
  }, [collectionSlug, id]);

  useEffect(() => {
    let cancelled = false;
    Promise.resolve().then(() => {
      if (!cancelled) void load();
    });
    return () => {
      cancelled = true;
    };
  }, [load]);

  if (id === undefined || id === null) {
    return (
      <div className="spp">
        <span className="spp-title">{t.title}</span>
        <p className="spp-muted">{t.saveFirst}</p>
      </div>
    );
  }

  const create = async () => {
    setBusy(true);
    setError(null);
    setCopied(false);
    try {
      const res = await fetch("/api/share-links/create", {
        method: "POST",
        credentials: "include",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ collection: collectionSlug, id, days, note }),
      });
      if (!res.ok) {
        setError(await errorMessage(res, t.failed));
        return;
      }
      setCreated((await res.json()) as { url: string; expiresAt: string });
      setNote("");
      await load();
    } finally {
      setBusy(false);
    }
  };

  const revoke = async (linkId: string | number) => {
    setRevoking(linkId);
    setError(null);
    try {
      const res = await fetch(`/api/share-links/${linkId}/revoke`, { method: "POST", credentials: "include" });
      if (!res.ok) setError(await errorMessage(res, t.failed));
      await load();
    } finally {
      setRevoking(null);
    }
  };

  const copy = async () => {
    if (!created) return;
    try {
      await navigator.clipboard.writeText(created.url);
      setCopied(true);
    } catch {
      setCopied(false);
    }
  };

  const ownerOf = (l: LinkRow) => (typeof l.createdBy === "object" && l.createdBy ? l.createdBy.id : l.createdBy);
  const emailOf = (l: LinkRow) => (typeof l.createdBy === "object" && l.createdBy ? l.createdBy.email : undefined);
  const mayRevoke = (l: LinkRow) => CAN_REVOKE_ANY.has(role) || String(ownerOf(l)) === String(userId);

  return (
    <div className="spp">
      <span className="spp-title">{t.title}</span>
      <p className="spp-muted">{t.intro}</p>

      <div className="spp-form">
        <label className="spp-field" htmlFor="spp-days">
          <span>{t.duration}</span>
          <select id="spp-days" value={days} onChange={(e) => setDays(Number(e.target.value))}>
            {DURATIONS.map((d) => (
              <option key={d} value={d}>
                {t.days(d)}
              </option>
            ))}
          </select>
        </label>
        <label className="spp-field" htmlFor="spp-note">
          <span>{t.note}</span>
          <input id="spp-note" type="text" maxLength={200} value={note} placeholder={t.notePlaceholder} onChange={(e) => setNote(e.target.value)} />
        </label>
        <button type="button" className={`btn btn--style-secondary btn--size-small${busy ? " btn--disabled" : ""}`} disabled={busy} onClick={() => void create()}>
          <span className="btn__content">
            <span className="btn__label">{busy ? t.creating : t.create}</span>
          </span>
        </button>
      </div>

      {error && <p className="spp-error">{error}</p>}

      {created && (
        <div className="spp-created">
          <p>{t.created}</p>
          <div className="spp-url">
            <input id="spp-url" type="text" readOnly value={created.url} onFocus={(e) => e.currentTarget.select()} />
            <button type="button" className="btn btn--style-primary btn--size-small" onClick={() => void copy()}>
              <span className="btn__content">
                <span className="btn__label">{copied ? t.copied : t.copy}</span>
              </span>
            </button>
          </div>
          <p className="spp-muted">{t.until(formatIstanbul(created.expiresAt))}</p>
        </div>
      )}

      <div className="spp-list">
        <span className="spp-subtitle">{t.active}</span>
        {links.length === 0 ? (
          <p className="spp-muted">{t.none}</p>
        ) : (
          <ul>
            {links.map((l) => (
              <li key={l.id} className="spp-link">
                <div className="spp-link-text">
                  <strong>{l.note || "—"}</strong>
                  <span>{t.until(formatIstanbul(l.expiresAt))}</span>
                  <span>
                    {t.views(l.viewCount ?? 0)}
                    {emailOf(l) ? ` · ${t.by}: ${emailOf(l)}` : ""}
                  </span>
                </div>
                {mayRevoke(l) && (
                  <button
                    type="button"
                    className={`btn btn--style-secondary btn--size-small${revoking === l.id ? " btn--disabled" : ""}`}
                    disabled={revoking === l.id}
                    onClick={() => void revoke(l.id)}
                  >
                    <span className="btn__content">
                      <span className="btn__label">{revoking === l.id ? t.revoking : t.revoke}</span>
                    </span>
                  </button>
                )}
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
