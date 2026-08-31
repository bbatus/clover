/**
 * Internal role slugs — deliberately NOT Vodafone AccessPoint's literal LDAP
 * group names. Until 2026-08-19 the four values here WERE the exact
 * AccessPoint strings (`RL_VODAFONEPAY_CMS_EXEC_DEVELOPER_MAKER_RW`, etc.),
 * which meant our own access-control code was directly coupled to one
 * specific AD group-naming scheme for exactly today's two business units
 * (New Vertical, Growth). Onboarding a third department meant inventing a
 * brand new ROLES entry + touching every collection that checks it, purely
 * because their AD group happened to have a different name.
 *
 * The fix is one layer of indirection: these four slugs are now our own
 * vocabulary, and `roleMapping.ts`'s `LDAP_GROUP_TO_ROLE` is where a real
 * AccessPoint/AD group name gets translated into one of them. A new
 * department that needs a permission shape we already have (e.g. "creates
 * content in one scope, can't publish it themselves" — what GROWTH_MAKER is
 * today) is *one line* in that mapping file: their AD group name → the
 * existing ROLES.GROWTH_MAKER value. No change here, no new collection
 * code, no new deploy of business logic — only a data-shaped config edit.
 *
 * This does NOT make the four *permission shapes* themselves infinitely
 * flexible — a department that needs a genuinely new shape (e.g. write
 * access to only 3 specific collections nobody else touches) still needs a
 * new ROLES entry and new access-control wiring, same as before. That
 * deeper limit is real and intentional — see docs/RFP-OPEN-ITEMS.md §3.1.12
 * ("Flexible/Extensible panel… bu, Payload'ı bırakıp başka bir mimariye
 * geçmeden kapanmaz"). What this change actually buys: reusing an existing
 * shape for a new group of people is now config, not code.
 *
 * This file deliberately imports nothing from "payload" — it's the one part
 * of the role system client components ("use client") are allowed to import
 * directly. `roles.ts` re-exports these same bindings for server code, but a
 * client component must import from HERE, not from `roles.ts`: that file's
 * top-level `import { APIError, Forbidden } from "payload"` pulls Payload's
 * whole server runtime (pino, undici, Node builtins) into the client bundle
 * the moment anything imports from it — fine for Turbopack's dev/HMR graph,
 * but breaks a plain `next build --webpack` production build with
 * "Reading from 'node:assert' is not handled by plugins" style errors
 * (found 31.08.2026 building on a runner without native SWC bindings,
 * forcing the `--webpack` fallback — see AccountForm.tsx/UsersExportButton.tsx/
 * AuditRoleField.tsx for the client components this actually affects).
 */
export const ROLES = {
  /** "New Vertical" FE dev leads. Full CRUD + publish on every collection. */
  NEW_VERTICAL_MAKER: "new_vertical_maker",
  /** Reviews/publishes NEW_VERTICAL_MAKER's changes. Cannot create new documents. */
  NEW_VERTICAL_CHECKER: "new_vertical_checker",
  /**
   * Approves/publishes GROWTH_MAKER's drafts. Follow-up 28.08 (business
   * re-confirmed the role table): unlike the earlier reading of this role,
   * it does NOT create — "_RO" turned out to describe its actual capability
   * after all (approve + publish only), not just AccessPoint's naming
   * scheme. Scope was Campaigns-only; expanded 28.08 to every collection
   * GROWTH_MAKER can touch (see standardCreate/standardReadWrite below) —
   * Growth now mirrors New Vertical's content scope, not just Campaigns.
   */
  GROWTH_CHECKER: "growth_checker",
  /**
   * Creates/edits drafts. Can never publish its own work, and can never
   * touch an already-published document at all (see denyMakerPublish /
   * denyMakerEditPublished below) — a Checker always has to be the one who
   * takes something live. Scope was Campaigns-only; expanded 28.08 to every
   * collection New Vertical can touch, same as GROWTH_CHECKER above.
   */
  GROWTH_MAKER: "growth_maker",
} as const;

export type RoleValue = (typeof ROLES)[keyof typeof ROLES];

/**
 * Walkthrough 29.08: these were plain strings, so the Role select stayed
 * Turkish even with the panel switched to English — the one field on the
 * account screen that refused to translate. Payload takes a {tr,en} object
 * here exactly like every other label in this codebase.
 */
export const ROLE_OPTIONS = [
  {
    label: { tr: "New Vertical — Exec Developer (Maker, tüm alanlar)", en: "New Vertical — Exec Developer (Maker, all areas)" },
    value: ROLES.NEW_VERTICAL_MAKER,
  },
  {
    label: { tr: "New Vertical — Exec Content (Checker, tüm alanlar)", en: "New Vertical — Exec Content (Checker, all areas)" },
    value: ROLES.NEW_VERTICAL_CHECKER,
  },
  {
    label: {
      tr: "Growth — Checker (New Vertical ile aynı kapsam, sadece onaylar)",
      en: "Growth — Checker (same scope as New Vertical, approves only)",
    },
    value: ROLES.GROWTH_CHECKER,
  },
  {
    label: {
      tr: "Growth — Maker (New Vertical ile aynı kapsam, yayınlayamaz)",
      en: "Growth — Maker (same scope as New Vertical, cannot publish)",
    },
    value: ROLES.GROWTH_MAKER,
  },
];
