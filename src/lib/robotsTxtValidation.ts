/**
 * Guards the editable robots.txt (SEO Dosyaları global). A single wrong line —
 * `Disallow: /` in the group every crawler reads — would drop the whole site
 * out of search, and nothing on the site would look broken. So that one
 * mistake is refused at save time instead of being left to review.
 *
 * Only groups that apply to every crawler (`User-agent: *`) are checked; a
 * full block for a named bot (GPTBot etc.) is intentional and allowed.
 */
export function findSiteWideBlock(robotsTxt: string): number | null {
  const lines = robotsTxt.split(/\r?\n/);
  let groupAgents: string[] = [];
  let inRules = false;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].replace(/#.*/, "").trim();
    if (!line) continue;
    const match = /^([A-Za-z-]+)\s*:\s*(.*)$/.exec(line);
    if (!match) continue;
    const key = match[1].toLowerCase();
    const value = match[2].trim();
    if (key === "user-agent") {
      // A user-agent line after rules starts a new group.
      if (inRules) {
        groupAgents = [];
        inRules = false;
      }
      groupAgents.push(value);
      continue;
    }
    if (key === "disallow" || key === "allow") inRules = true;
    if (key === "disallow" && value === "/" && groupAgents.includes("*")) return i + 1;
  }
  return null;
}

export function validateRobotsTxt(value: unknown, locale: "tr" | "en" = "tr"): true | string {
  if (typeof value !== "string" || value.trim() === "") return true;
  const line = findSiteWideBlock(value);
  if (line === null) return true;
  return locale === "en"
    ? `Line ${line}: "Disallow: /" under "User-agent: *" would remove the whole site from search engines. Remove it or target a specific path.`
    : `${line}. satır: "User-agent: *" altındaki "Disallow: /" sitenin tamamını arama motorlarından kaldırır. Bu satırı silin ya da belirli bir yol yazın.`;
}
