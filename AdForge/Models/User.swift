// User.swift
// AdForge

import Foundation

// MARK: - AFUser

struct AFUser: Codable, Identifiable, Sendable {
    let id: String                      // Firebase Auth UID (or local UUID for MVP)
    var displayName: String
    var avatarURL: String?
    var credits: Int
    var totalGenerations: Int
    var totalVotesReceived: Int
    var totalWins: Int
    var level: Int
    var xp: Int
    var currentStreak: Int
    var lastActiveDate: Date?
    var badges: [Badge]
    var joinedDate: Date
    var dailyFreeCreditsCollected: Bool
    var adWatchesToday: Int
    var heartsRemaining: Int            // Daily vote allowance
    var heartsLastRefill: Date?

    // MARK: Computed

    /// XP required to reach the next level (simple 500 * level formula).
    var xpToNextLevel: Int {
        500 * level
    }

    /// Normalized progress to next level, 0…1.
    var levelProgress: Double {
        guard xpToNextLevel > 0 else { return 0 }
        return min(Double(xp % xpToNextLevel) / Double(xpToNextLevel), 1.0)
    }

    /// Whether the user can still earn more credits by watching ads today.
    var canEarnMoreFromAds: Bool {
        adWatchesToday < CreditCost.maxAdWatchesPerDay
    }

    // MARK: - Mock

    static let mock = AFUser(
        id: "mock-user-001",
        displayName: "ArtBot9000",
        avatarURL: nil,
        credits: 1_500,
        totalGenerations: 42,
        totalVotesReceived: 318,
        totalWins: 3,
        level: 5,
        xp: 1_200,
        currentStreak: 4,
        lastActiveDate: Date(),
        badges: [Badge.mock],
        joinedDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
        dailyFreeCreditsCollected: false,
        adWatchesToday: 2,
        heartsRemaining: 20,
        heartsLastRefill: Date()
    )
}
