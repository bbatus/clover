"use client";

import { startTransition, useCallback, useEffect, useState } from "react";
import { useAuth, useDocumentDrawer } from "@payloadcms/ui";
import { useAdminLocale } from "./useAdminLocale";
import { TableSkeleton } from "./TableSkeleton";

/**
 * Footer Yönetimi's link columns (17.09.2026). Nothing here is stored on the
 * FooterSettings global: every list is read live from the records the site
 * itself reads, and every edit opens THAT record's own drawer, so it goes
 * through that record's own maker→checker flow.
 *
 * - Sol sütun → Menü Linkleri, section "footer-kurumsal"
 * - Orta sütun → Blog Yazıları with "Footer'da Göster"
 * - Sağ sütun → Kampanyalar with "Footer'da Göster"
 * - Alt satır → Menü Linkleri, section "footer-yasal"
 *
 * That is the user's sync requirement: ticking "Footer'da Göster" on a blog
 * post and looking at this screen show the same list, because there is only
 * one list. Lists include drafts (`draft=true`) with their status, so an
 * editor sees a pending change here too, not only what is already live.
 */

type Row = { id: string | number; _status?: string; label?: string; title?: string; href?: string; order?: number; footerOrder?: number | null };

type SectionKey = "kurumsal" | "blogs" | "campaigns" | "yasal";

const STRINGS = {
  tr: {
    title: "Footer içeriği",
    intro:
      "Aşağıdaki listeler doğrudan ilgili kayıtlardan gelir: bir blog yazısında veya kampanyada 'Footer'da Göster' işaretlendiğinde burada da görünür, buradan açıp değiştirdiğinizde de o kaydın kendisi değişir. Her değişiklik o kaydın kendi onay (maker→checker) akışından geçer.",
    sections: {
      kurumsal: { title: "Sol sütun — kurumsal sayfalar", hint: "Menü Linkleri → 'Footer — Kurumsal'" },
      blogs: { title: "Orta sütun — blog yazıları", hint: "Blog Yazıları → 'Footer'da Göster'" },
      campaigns: { title: "Sağ sütun — kampanyalar", hint: "Kampanyalar → 'Footer'da Göster'" },
      yasal: { title: "Alt satır — yasal sayfalar", hint: "Menü Linkleri → 'Footer — Yasal'" },
    },
    colTitle: "Başlık",
    colOrder: "Sıra",
    colStatus: "Durum",
    published: "Yayında",
    draft: "Taslak",
    empty: "Bu sütunda henüz kayıt yok.",
    addLink: "Yeni link ekle",
    addFromList: "Footer'a ekle…",
    addHint: "Seçtiğiniz kayıt açılır; 'Footer'da Göster' kutusunu işaretleyip kaydedin.",
    error: "Liste yüklenemedi.",
  },
  en: {
    title: "Footer content",
    intro:
      "These lists come straight from the records themselves: ticking 'Show in Footer' on a blog post or campaign makes it appear here, and opening it from here edits that record. Every change goes through that record's own maker→checker flow.",
    sections: {
      kurumsal: { title: "Left column — corporate pages", hint: "Nav Links → 'Footer — Corporate'" },
      blogs: { title: "Middle column — blog posts", hint: "Blog Posts → 'Show in Footer'" },
      campaigns: { title: "Right column — campaigns", hint: "Campaigns → 'Show in Footer'" },
      yasal: { title: "Bottom row — legal pages", hint: "Nav Links → 'Footer — Legal'" },
    },
    colTitle: "Title",
    colOrder: "Order",
    colStatus: "Status",
    published: "Published",
    draft: "Draft",
    empty: "Nothing in this column yet.",
    addLink: "Add a link",
    addFromList: "Add to footer…",
    addHint: "The chosen record opens; tick 'Show in Footer' and save.",
    error: "Could not load the list.",
  },
};

const SOURCES: Record<SectionKey, { collection: "nav-links" | "blog-posts" | "campaigns"; query: string }> = {
  kurumsal: { collection: "nav-links", query: "where[section][equals]=footer-kurumsal&sort=order" },
  blogs: { collection: "blog-posts", query: "where[showInFooter][equals]=true&sort=footerOrder" },
  campaigns: { collection: "campaigns", query: "where[showInFooter][equals]=true&sort=footerOrder" },
  yasal: { collection: "nav-links", query: "where[section][equals]=footer-yasal&sort=order" },
};

function StatusBadge({ status, t }: { status?: string; t: (typeof STRINGS)["tr"] }) {
  return status === "published" ? (
    <span className="cm-badge cm-badge--published">{t.published}</span>
  ) : (
    <span className="cm-badge">{t.draft}</span>
  );
}

function RecordRow({ row, collection, onSaved, t }: { row: Row; collection: string; onSaved: () => void; t: (typeof STRINGS)["tr"] }) {
  const [Drawer, Toggler] = useDocumentDrawer({ collectionSlug: collection, id: row.id as number });
  return (
    <tr>
      <td>
        <Toggler>{row.label ?? row.title}</Toggler>
        <Drawer onSave={onSaved} />
      </td>
      <td>{row.order ?? row.footerOrder ?? "—"}</td>
      <td>
        <StatusBadge status={row._status} t={t} />
      </td>
    </tr>
  );
}

/** Nav links: a plain create drawer (the editor picks the footer section in it). */
function CreateLink({ onSaved, label }: { onSaved: () => void; label: string }) {
  const { permissions } = useAuth();
  const [Drawer, Toggler] = useDocumentDrawer({ collectionSlug: "nav-links" });
  if (!permissions?.collections?.["nav-links"]?.create) return null;
  return (
    <>
      <Toggler className="btn btn--style-secondary btn--size-small">
        <span className="btn__content">
          <span className="btn__label">{label}</span>
        </span>
      </Toggler>
      <Drawer onSave={onSaved} redirectAfterCreate={false} />
    </>
  );
}

/** Blog posts / campaigns not yet in the footer: pick one, its own drawer opens to tick the box. */
function AddExisting({
  collection,
  excludeIds,
  onSaved,
  t,
}: {
  collection: "blog-posts" | "campaigns";
  excludeIds: Set<string | number>;
  onSaved: () => void;
  t: (typeof STRINGS)["tr"];
}) {
  const { permissions } = useAuth();
  const [options, setOptions] = useState<Row[]>([]);
  const [selected, setSelected] = useState<string | number | null>(null);
  const [Drawer, , { openDrawer }] = useDocumentDrawer({ collectionSlug: collection, id: (selected ?? undefined) as number | undefined });

  useEffect(() => {
    let cancelled = false;
    void fetch(`/api/${collection}?depth=0&limit=200&draft=true&sort=title`, { credentials: "same-origin" })
      .then((r) => (r.ok ? r.json() : { docs: [] }))
      .then((d) => {
        if (!cancelled) setOptions(d.docs ?? []);
      });
    return () => {
      cancelled = true;
    };
  }, [collection]);

  useEffect(() => {
    if (selected !== null) openDrawer();
  }, [selected, openDrawer]);

  if (!permissions?.collections?.[collection]?.update) return null;
  const available = options.filter((o) => !excludeIds.has(o.id));
  if (available.length === 0) return null;

  return (
    <div className="fsp-add">
      <select
        className="fsp-select"
        value=""
        onChange={(e) => {
          const id = available.find((o) => String(o.id) === e.target.value)?.id;
          if (id !== undefined) setSelected(id);
        }}
      >
        <option value="">{t.addFromList}</option>
        {available.map((o) => (
          <option key={o.id} value={String(o.id)}>
            {o.title}
          </option>
        ))}
      </select>
      <span className="cm-hint">{t.addHint}</span>
      {selected !== null && (
        <Drawer
          onSave={() => {
            setSelected(null);
            onSaved();
          }}
        />
      )}
    </div>
  );
}

export default function FooterSyncPanel() {
  const locale = useAdminLocale();
  const t = STRINGS[locale];
  const [lists, setLists] = useState<Record<SectionKey, Row[] | null>>({ kurumsal: null, blogs: null, campaigns: null, yasal: null });
  const [error, setError] = useState(false);
  const [reloadKey, setReloadKey] = useState(0);
  const refetch = useCallback(() => setReloadKey((k) => k + 1), []);

  useEffect(() => {
    let cancelled = false;
    startTransition(() => setError(false));
    const load = async () => {
      try {
        const entries = await Promise.all(
          (Object.keys(SOURCES) as SectionKey[]).map(async (key) => {
            const { collection, query } = SOURCES[key];
            const res = await fetch(`/api/${collection}?depth=0&limit=50&draft=true&${query}`, { credentials: "same-origin" });
            if (!res.ok) throw new Error("fetch failed");
            const data = await res.json();
            return [key, (data.docs ?? []) as Row[]] as const;
          })
        );
        if (!cancelled) setLists(Object.fromEntries(entries) as Record<SectionKey, Row[]>);
      } catch {
        if (!cancelled) setError(true);
      }
    };
    void load();
    return () => {
      cancelled = true;
    };
  }, [reloadKey]);

  return (
    <div className="fsp">
      <h3 className="fsp-title">{t.title}</h3>
      <p className="cm-hint">{t.intro}</p>
      {error && <p className="cm-error">{t.error}</p>}
      {(Object.keys(SOURCES) as SectionKey[]).map((key) => {
        const { collection } = SOURCES[key];
        const rows = lists[key];
        return (
          <section key={key} className="fsp-section">
            <div className="fsp-section-head">
              <div>
                <h4 className="fsp-section-title">{t.sections[key].title}</h4>
                <span className="cm-hint">{t.sections[key].hint}</span>
              </div>
              {collection === "nav-links" && <CreateLink onSaved={refetch} label={t.addLink} />}
            </div>
            <div className="card cm-card">
              {rows === null ? (
                <TableSkeleton columns={3} />
              ) : rows.length === 0 ? (
                <p className="cm-hint">{t.empty}</p>
              ) : (
                <div className="table-wrap">
                  <table className="cm-table">
                    <thead>
                      <tr>
                        <th>{t.colTitle}</th>
                        <th>{t.colOrder}</th>
                        <th>{t.colStatus}</th>
                      </tr>
                    </thead>
                    <tbody>
                      {rows.map((row) => (
                        <RecordRow key={row.id} row={row} collection={collection} onSaved={refetch} t={t} />
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
            {collection !== "nav-links" && rows && (
              <AddExisting collection={collection} excludeIds={new Set(rows.map((r) => r.id))} onSaved={refetch} t={t} />
            )}
          </section>
        );
      })}
    </div>
  );
}
