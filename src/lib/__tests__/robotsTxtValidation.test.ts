import { describe, expect, it } from "vitest";
import { DEFAULT_ROBOTS_TXT } from "@/lib/seoFilesDefaults";
import { findSiteWideBlock, validateRobotsTxt } from "@/lib/robotsTxtValidation";

describe("robots.txt validation", () => {
  it("accepts the default file (AI-training bots fully blocked by name)", () => {
    expect(findSiteWideBlock(DEFAULT_ROBOTS_TXT)).toBeNull();
    expect(validateRobotsTxt(DEFAULT_ROBOTS_TXT)).toBe(true);
  });

  it("refuses Disallow: / for every crawler and names the line", () => {
    const txt = "User-agent: *\nDisallow: /api/\nDisallow: /\n";
    expect(findSiteWideBlock(txt)).toBe(3);
    expect(validateRobotsTxt(txt)).toContain("3. satır");
    expect(validateRobotsTxt(txt, "en")).toContain("Line 3");
  });

  it("catches * when it shares a group with a named bot", () => {
    expect(findSiteWideBlock("User-agent: GPTBot\nUser-agent: *\nDisallow: /")).toBe(3);
  });

  it("does not carry * into the next group", () => {
    expect(findSiteWideBlock("User-agent: *\nDisallow: /api/\n\nUser-agent: CCBot\nDisallow: /")).toBeNull();
  });

  it("ignores comments and deeper paths", () => {
    expect(findSiteWideBlock("# Disallow: /\nUser-agent: *\nDisallow: /private/ # Disallow: /")).toBeNull();
  });

  it("treats empty as valid (the site falls back to its default)", () => {
    expect(validateRobotsTxt("")).toBe(true);
    expect(validateRobotsTxt(undefined)).toBe(true);
  });
});
