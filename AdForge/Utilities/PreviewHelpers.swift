// PreviewHelpers.swift
// AdForge
//
// Static mock instances used exclusively in SwiftUI #Preview blocks.

import Foundation

// MARK: - AppState Preview

extension AppState {
    /// Pre-configured AppState for use in SwiftUI previews.
    @MainActor
    static var preview: AppState {
        let state = AppState()
        state.currentUser = .mock
        state.isAuthenticated = true
        return state
    }
}

// MARK: - Generation.mock alias

extension Generation {
    /// Convenience alias pointing to the primary mock image generation.
    static var mock: Generation { mockImage }
}

// MARK: - CompetitionEntry.mocks alias

extension CompetitionEntry {
    /// Array alias for preview collections.
    static var mocks: [CompetitionEntry] { mockLeaderboard }
}
