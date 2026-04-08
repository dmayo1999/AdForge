// PromptFilter.swift
// AdForge
//
// Client-side prompt safety check (backup layer; server-side blocklist is the primary gate).
// Uses a curated set of blocked terms. Returns false for any flagged prompt.

import Foundation

// MARK: - PromptFilter

enum PromptFilter {

    // MARK: - Public API

    /// Returns true if the prompt is safe to submit, false if it contains blocked content.
    static func isPromptSafe(_ prompt: String) -> Bool {
        let normalized = prompt.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Empty prompts are rejected (no useful content)
        guard normalized.isNotEmpty else { return false }

        // Check each blocked term
        for term in blockedTerms {
            if normalized.contains(term) {
                return false
            }
        }

        return true
    }

    // MARK: - Blocked Term Categories
    //
    // This is a minimal client-side filter. The server maintains a comprehensive blocklist.
    // Add terms here only for obvious, high-confidence blocks to reduce latency on clear violations.

    private static let blockedTerms: [String] = [
        // Non-consensual imagery
        "nude", "naked", "nsfw", "porn", "pornographic", "xxx",
        "sexual content", "explicit", "genitalia", "erotic",

        // Real person harm
        "deepfake", "face swap", "impersonate",

        // Violence / gore
        "gore", "decapitat", "dismember", "mutilat",
        "graphic violence", "snuff",

        // Hate speech
        "hate speech", "ethnic cleansing", "racial slur",

        // Illegal content
        "child exploitation", "csam", "lolicon",
        "underage sexual",

        // Dangerous instructions
        "how to make a bomb", "bomb making", "bioweapon",
        "chemical weapon", "drug synthesis",
    ]
}

// MARK: - String Helper (local to avoid circular dependency)

private extension String {
    var isNotEmpty: Bool { !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
