// AuthService.swift
// AdForge
//
// MVP implementation using UserDefaults for session persistence.
// TODO: Replace with real Firebase Auth + Apple Sign-In.

import Foundation
import AuthenticationServices

// MARK: - AuthError

enum AuthError: LocalizedError {
    case signInCancelled
    case credentialError
    case sessionExpired
    case noExistingSession

    var errorDescription: String? {
        switch self {
        case .signInCancelled:   return "Sign-in was cancelled."
        case .credentialError:   return "Could not obtain credentials from Apple."
        case .sessionExpired:    return "Your session has expired. Please sign in again."
        case .noExistingSession: return "No existing session found."
        }
    }
}

// MARK: - AuthService

@MainActor
@Observable
final class AuthService {

    // MARK: UserDefaults Keys
    private enum Keys {
        static let savedUser       = "adforge.saved_user"
        static let sessionToken    = "adforge.session_token"
    }

    // MARK: Observed State
    private(set) var currentUser: AFUser?

    // MARK: - Sign In with Apple

    /// MVP: Creates a local user record on first sign-in, then persists to UserDefaults.
    /// TODO: Replace with real Sign In with Apple flow + Firebase Auth backend.
    func signInWithApple() async throws -> AFUser {
        // TODO: Implement real ASAuthorizationAppleIDProvider flow.
        // For MVP, we simulate a short delay and create a stub user.
        try await Task.sleep(nanoseconds: 800_000_000)  // 0.8s simulated latency

        let userId = UUID().uuidString
        let newUser = AFUser(
            id: userId,
            displayName: generateDisplayName(),
            avatarURL: nil,
            credits: CreditCost.dailyFree,   // 500 welcome credits
            totalGenerations: 0,
            totalVotesReceived: 0,
            totalWins: 0,
            level: 1,
            xp: 0,
            currentStreak: 1,
            lastActiveDate: Date(),
            badges: [],
            joinedDate: Date(),
            dailyFreeCreditsCollected: true, // already given as welcome bonus
            adWatchesToday: 0,
            heartsRemaining: 20,
            heartsLastRefill: Date()
        )

        persist(user: newUser)
        currentUser = newUser
        return newUser
    }

    // MARK: - Sign Out

    func signOut() {
        UserDefaults.standard.removeObject(forKey: Keys.savedUser)
        UserDefaults.standard.removeObject(forKey: Keys.sessionToken)
        currentUser = nil
    }

    // MARK: - Session Restore

    /// Returns a restored AFUser if a valid local session exists, nil otherwise.
    /// TODO: Validate Firebase Auth token expiry on the backend.
    func checkExistingSession() async -> AFUser? {
        guard
            let data = UserDefaults.standard.data(forKey: Keys.savedUser),
            let user = try? JSONDecoder().decode(AFUser.self, from: data)
        else {
            return nil
        }
        currentUser = user
        await resetDailyStateIfNeeded()
        return currentUser
    }

    // MARK: - Private

    private func persist(user: AFUser) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        UserDefaults.standard.set(data, forKey: Keys.savedUser)
        // TODO: Store Firebase ID token as session token.
        UserDefaults.standard.set("mock-session-token-\(user.id)", forKey: Keys.sessionToken)
    }

    /// Resets daily counters if the last active date was a different calendar day.
    private func resetDailyStateIfNeeded() async {
        guard var user = currentUser else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastActive = user.lastActiveDate {
            let lastDay = calendar.startOfDay(for: lastActive)
            if lastDay < today {
                // New day — reset daily counters
                // Note: dailyFreeCreditsCollected is managed exclusively by CreditService
                user.adWatchesToday = 0

                // Check streak
                let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
                if daysBetween == 1 {
                    user.currentStreak += 1
                } else if daysBetween > 1 {
                    user.currentStreak = 1
                }

                // Refill hearts
                user.heartsRemaining = 20
                user.heartsLastRefill = Date()
            }
        }

        user.lastActiveDate = Date()
        currentUser = user
        persist(user: user)
    }

    private func generateDisplayName() -> String {
        let adjectives = ["Cosmic", "Electric", "Neon", "Quantum", "Shadow", "Solar", "Turbo", "Pixel", "Hyper", "Void"]
        let nouns = ["Creator", "Forge", "Studio", "Muse", "Bot", "Artist", "Dreamer", "Vision", "Mind", "Spark"]
        let adj  = adjectives.randomElement() ?? "Pixel"
        let noun = nouns.randomElement() ?? "Creator"
        let num  = Int.random(in: 10...999)
        return "\(adj)\(noun)\(num)"
    }
}
