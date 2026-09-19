"use client";

import { useCallback, useEffect, useRef, useState, type ReactNode } from "react";
import { useAdminLocale } from "./useAdminLocale";

/**
 * 19.09.2026 — one waiting / empty / error language for every custom admin
 * screen (Kırık Linkler, Ücretler ve Limitler, İçerik Yönetimi, toplu işlem,
 * SEO asistanı, önizleme linkleri). Before this each screen wrote its own:
 * a grey "Yükleniyor…" line here, a skeleton that never went away on error
 * there, a failed request shown as "no records" somewhere else.
 *
 * The spinner is CMS-only by decision (the public site uses layout-shaped
 * skeletons, never a spinner). Styles: `.vf-spinner` / `.vf-state` in
 * styles/custom.css; with prefers-reduced-motion the ring stops turning and
 * the text carries the state.
 */

const STRINGS = {
  tr: {
    loading: "Yükleniyor…",
    retry: "Tekrar dene",
    retrying: "Deneniyor…",
    errorTitle: "Yüklenemedi",
    loadFailed: "Sunucudan cevap alınamadı. Bağlantınızı kontrol edip tekrar deneyin.",
    elapsed: (s: number) => `${s} sn`,
  },
  en: {
    loading: "Loading…",
    retry: "Try again",
    retrying: "Trying…",
    errorTitle: "Couldn't load",
    loadFailed: "The server didn't answer. Check your connection and try again.",
    elapsed: (s: number) => `${s}s`,
  },
};

export function useStateStrings() {
  return STRINGS[useAdminLocale()] ?? STRINGS.tr;
}

type SpinnerSize = "s" | "m" | "l";

/** Vodafone red ring. Decorative (aria-hidden) unless given a label. */
export function VfSpinner({ size = "m", label }: { size?: SpinnerSize; label?: string }) {
  if (!label) return <span className={`vf-spinner vf-spinner--${size}`} aria-hidden="true" />;
  return <span className={`vf-spinner vf-spinner--${size}`} role="img" aria-label={label} />;
}

/** Seconds since `active` became true; 0 while inactive. */
export function useElapsedSeconds(active: boolean): number {
  const [seconds, setSeconds] = useState(0);
  useEffect(() => {
    if (!active) return;
    const started = Date.now();
    const timer = setInterval(() => setSeconds(Math.floor((Date.now() - started) / 1000)), 1000);
    return () => {
      clearInterval(timer);
      setSeconds(0);
    };
  }, [active]);
  return seconds;
}

/**
 * A request in flight. `detail` explains what is happening (e.g. "40 kayıt
 * işleniyor"); `showElapsed` adds a running seconds counter for operations
 * that can take long, so a slow scan never looks frozen.
 */
export function LoadingState({
  label,
  detail,
  showElapsed = false,
  compact = false,
}: {
  label?: string;
  detail?: ReactNode;
  showElapsed?: boolean;
  compact?: boolean;
}) {
  const t = useStateStrings();
  const seconds = useElapsedSeconds(showElapsed);
  return (
    <div className={`vf-state vf-state--loading${compact ? " vf-state--compact" : ""}`} role="status" aria-live="polite">
      <VfSpinner size={compact ? "s" : "m"} />
      <div className="vf-state__text">
        <p className="vf-state__title">
          {label ?? t.loading}
          {showElapsed && seconds >= 2 && <span className="vf-state__elapsed"> · {t.elapsed(seconds)}</span>}
        </p>
        {detail && <p className="vf-state__detail">{detail}</p>}
      </div>
    </div>
  );
}

/** Nothing to show, and that is the real answer (not a failed request). */
export function EmptyState({ title, hint, action }: { title: string; hint?: ReactNode; action?: ReactNode }) {
  return (
    <div className="vf-state vf-state--empty">
      <svg className="vf-state__icon" width="28" height="28" viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <path d="M4 13h4l1.5 2.5h5L16 13h4" stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round" />
        <path d="M6.2 5h11.6L20 13v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-5l2.2-8Z" stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round" />
      </svg>
      <div className="vf-state__text">
        <p className="vf-state__title">{title}</p>
        {hint && <p className="vf-state__detail">{hint}</p>}
        {action && <div className="vf-state__action">{action}</div>}
      </div>
    </div>
  );
}

/** A request failed. Says what, and offers a retry when one makes sense. */
export function ErrorState({ message, title, onRetry }: { message?: ReactNode; title?: string; onRetry?: () => unknown }) {
  const t = useStateStrings();
  const { busy, run } = useBusyAction();
  return (
    <div className="vf-state vf-state--error" role="alert">
      <svg className="vf-state__icon" width="28" height="28" viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="1.6" />
        <path d="M12 7.5v5.5" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
        <circle cx="12" cy="16.3" r="1.1" fill="currentColor" />
      </svg>
      <div className="vf-state__text">
        <p className="vf-state__title">{title ?? t.errorTitle}</p>
        {message && <p className="vf-state__detail">{message}</p>}
        {onRetry && (
          <div className="vf-state__action">
            <BusyButton busy={busy} onClick={() => run(async () => onRetry())} label={t.retry} busyLabel={t.retrying} />
          </div>
        )}
      </div>
    </div>
  );
}

/**
 * Double-click guard. `run(fn)` ignores calls while an earlier one is still
 * running — checked against a ref, so two clicks inside the same frame
 * (before React re-renders the disabled button) still start only one
 * request. Pass a `key` to lock per row (e.g. per link being revoked).
 */
export function useBusyAction() {
  const locks = useRef(new Set<string>());
  const [busyKeys, setBusyKeys] = useState<ReadonlySet<string>>(new Set());

  const run = useCallback(async <T,>(fn: () => Promise<T>, key = "default"): Promise<T | undefined> => {
    if (locks.current.has(key)) return undefined;
    locks.current.add(key);
    setBusyKeys(new Set(locks.current));
    try {
      return await fn();
    } finally {
      locks.current.delete(key);
      setBusyKeys(new Set(locks.current));
    }
  }, []);

  return {
    run,
    busy: busyKeys.size > 0,
    isBusy: (key = "default") => busyKeys.has(key),
  };
}

/**
 * Payload-styled button with a working state: disabled while busy, shows
 * the spinner and `busyLabel`, announces aria-busy. Uses Payload's own
 * `btn` classes so it matches every built-in button next to it.
 */
export function BusyButton({
  busy,
  onClick,
  label,
  busyLabel,
  variant = "secondary",
  disabled = false,
  className = "",
  id,
}: {
  busy: boolean;
  onClick: () => unknown;
  label: ReactNode;
  busyLabel?: ReactNode;
  variant?: "primary" | "secondary";
  disabled?: boolean;
  className?: string;
  id?: string;
}) {
  const off = busy || disabled;
  return (
    <button
      id={id}
      type="button"
      className={`btn btn--style-${variant} btn--size-small vf-busy-btn${off ? " btn--disabled" : ""}${busy ? " vf-busy-btn--busy" : ""}${className ? ` ${className}` : ""}`}
      disabled={off}
      aria-busy={busy || undefined}
      onClick={() => {
        if (!off) void onClick();
      }}
    >
      <span className="btn__content">
        {busy && <VfSpinner size="s" />}
        <span className="btn__label">{busy ? (busyLabel ?? label) : label}</span>
      </span>
    </button>
  );
}
