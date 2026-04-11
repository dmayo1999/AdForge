import { describe, it, expect } from "vitest";
import { checkPrompt } from "./prompt-checker.js";
import blocklist from "./blocklist.json" with { type: "json" };

describe("checkPrompt", () => {
  it("rejects empty and whitespace-only prompts", () => {
    expect(checkPrompt("")).toEqual({
      safe: false,
      reason: "empty_prompt",
    });
    expect(checkPrompt("   \t\n")).toEqual({
      safe: false,
      reason: "empty_prompt",
    });
  });

  it("accepts a benign creative prompt", () => {
    const r = checkPrompt("A watercolor painting of mountains at sunset.");
    expect(r.safe).toBe(true);
    expect(r.reason).toBeUndefined();
  });

  it("blocks a term from the blocklist (substring)", () => {
    const term = (blocklist.terms as string[])[0];
    expect(term.length).toBeGreaterThan(0);
    const r = checkPrompt(`something about ${term} here`);
    expect(r.safe).toBe(false);
    expect(r.reason).toBe("prohibited_content");
  });

  it("blocks celebrity / public figure names when present in blocklist", () => {
    const names = blocklist.celebrity_names as string[];
    if (names.length === 0) return;
    const name = names[0];
    const r = checkPrompt(`a portrait of ${name} at the beach`);
    expect(r.safe).toBe(false);
    expect(r.reason).toBe("public_figure_not_allowed");
  });
});
