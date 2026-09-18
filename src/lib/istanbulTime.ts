/**
 * Istanbul wall-clock formatting, shared by server hooks and client
 * components (kept free of any "payload" import so client bundles stay small).
 * Always formats in Europe/Istanbul, never the machine's own zone — an
 * OpenShift pod runs in UTC, three hours behind Istanbul.
 */
export const SCHEDULE_TIME_ZONE = "Europe/Istanbul";

/** "01.10.2026 00:00" in Istanbul time. */
export function formatIstanbul(iso: string | Date): string {
  const parts = new Intl.DateTimeFormat("tr-TR", {
    timeZone: SCHEDULE_TIME_ZONE,
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).formatToParts(new Date(iso));
  const get = (type: string) => parts.find((p) => p.type === type)?.value ?? "";
  return `${get("day")}.${get("month")}.${get("year")} ${get("hour")}:${get("minute")}`;
}
