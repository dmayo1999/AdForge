// AppState.swift
// AdForge
//
// Root observable state injected as an environment object into the view hierarchy.

import SwiftUI

// MARK: - AppTab

enum AppTab: Int, CaseIterable {
    case studio      = 0
    case feed        = 1
    case competitions = 2
    case profile     = 3

    var title: String {
        switch self {
        case .studio:       return "Studio"
        case .feed:         return "Feed"
        case .competitions: return "Compete"
        case .profile:      return "Profile"
        }
    }

    var iconName: String {
        switch self {
        case .studio:       return "wand.and.stars"
        case .feed:         return "rectangle.stack.fill"
        case .competitions: return "trophy.fill"
        case .profile:      return "person.fill"
        }
    }
}

// MARK: - AppState

@MainActor
@Observable
final class AppState {
    // MARK: UI State
    var currentUser: AFUser?
    var isAuthenticated: Bool = false
    var isLoading: Bool = false
    var selectedTab: AppTab = .studio
    var showingAuth: Bool = false
    var errorMessage: String?

    // MARK: Services
    let authService: AuthService
    let creditService: CreditService
    let generationService: GenerationService
    let feedService: FeedService
    let competitionService: CompetitionService
    let adService: AdService
    let reportService: ReportService

    // MARK: Init

    init() {
        let auth       = AuthService()
        let credits    = CreditService()
        let generation = GenerationService()
        let feed       = FeedService()
        let competition = CompetitionService()
        let ad         = AdService()
        let report     = ReportService()

        self.authService        = auth
        self.creditService      = credits
        self.generationService  = generation
        self.feedService        = feed
        self.competitionService = competition
        self.adService          = ad
        self.reportService      = report
    }

    // MARK: - Session Management

    /// Attempts to restore a previous session from UserDefaults.
    func checkSession() async {
        isLoading = true
        defer { isLoading = false }

        if let user = await authService.checkExistingSession() {
            currentUser = user
            isAuthenticated = true
            // Refresh credit balance from the ledger
            let balance = await creditService.fetchBalance()
            currentUser?.credits = balance
        }
    }

    // MARK: - Daily Credits

    /// Collects free daily credits if not already collected today.
    func collectDailyCredits() async {
        guard isAuthenticated, var user = currentUser else { return }
        guard !user.dailyFreeCreditsCollected else { return }

        do {
            let collected = try await creditService.collectDailyFree()
            if collected {
                user.dailyFreeCreditsCollected = true
                let newBalance = await creditService.fetchBalance()
                user.credits = newBalance
                currentUser = user
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Auth Helpers

    func signOut() {
        authService.signOut()
        currentUser = nil
        isAuthenticated = false
        selectedTab = .studio
    }

    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
    }
}
