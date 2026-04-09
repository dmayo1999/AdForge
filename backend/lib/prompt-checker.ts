/**
 * prompt-checker.ts
 * Shared prompt safety checking logic.
 * Checks a prompt against the blocklist (terms, regex patterns, celebrity names).
 */

import blocklist from "./blocklist.json" with { type: "json" };

export interface CheckResult {
  safe: boolean;
  reason?: string;
}

// Pre-compile all regex patterns at module load time for performance
const compiledPatterns: RegExp[] = (blocklist.patterns as string[]).map(
  (p) => new RegExp(p, "gi")
);

/**
 * Check a prompt for prohibited content.
 * Returns { safe: true } or { safe: false, reason: string }.
 * All matching is case-insensitive.
 */
export function checkPrompt(prompt: string): CheckResult {
  if (typeof prompt !== "string" || prompt.trim().length === 0) {
    return { safe: false, reason: "empty_prompt" };
  }

  const lower = prompt.toLowerCase();

  // 1. Exact-term matching (case-insensitive substring check)
  for (const term of blocklist.terms as string[]) {
    if (lower.includes(term.toLowerCase())) {
      return { safe: false, reason: "prohibited_content" };
    }
  }

  // 2. Regex pattern matching (catches leet-speak / spacing tricks)
  for (const pattern of compiledPatterns) {
    // Reset lastIndex to ensure correct behaviour with global flag
    pattern.lastIndex = 0;
    if (pattern.test(prompt)) {
      return { safe: false, reason: "prohibited_content" };
    }
  }

  // 3. Celebrity / public figure deepfake prevention
  for (const name of blocklist.celebrity_names as string[]) {
    if (lower.includes(name.toLowerCase())) {
      return { safe: false, reason: "public_figure_not_allowed" };
    }
  }

  return { safe: true };
}
