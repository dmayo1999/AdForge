// ProfileViewModel.swift
// AdForge

import SwiftUI

@MainActor @Observable
final class ProfileViewModel {

    // MARK: - Properties

    var user: AFUser? = nil
    var userGenerations: [Generation] = []
    var isLoading: Bool = false

    // MARK: - Private

    private let appState: AppState

    // MARK: - Init

    init(appState: AppState) {
        self.appState = appState
        self.user = appState.currentUser
    }

    // MARK: - Methods

    func loadProfile() async {
        isLoading = true
        // Refresh user from appState (would hit network in real implementation)
        user = appState.currentUser
        isLoading = false
    }

    func loadUserGenerations() async {
        guard !isLoading else { return }
        isLoading = true
        do {
            // FeedService scoped to the current user
            let allGenerations = try await appState.feedService.fetchFeed(page: 1)
            userGenerations = allGenerations.filter { $0.userId == appState.currentUser?.id }
        } catch {
            appState.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        appState.authService.signOut()
    }
}
