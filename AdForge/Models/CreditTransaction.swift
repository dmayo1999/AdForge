// CreditTransaction.swift
// AdForge

import Foundation

// MARK: - CreditReason

enum CreditReason: String, Codable, CaseIterable, Sendable {
    case dailyFree       = "dailyFree"
    case adWatch         = "adWatch"
    case generation      = "generation"
    case competitionWin  = "competitionWin"
    case streakBonus     = "streakBonus"

    /// Human-readable label for display in transaction history.
    var displayLabel: String {
        switch self {
        case .dailyFree:      return "Daily Free Credits"
        case .adWatch:        return "Ad Watch Reward"
        case .generation:     return "Content Generation"
        case .competitionWin: return "Competition Win Bonus"
        case .streakBonus:    return "Streak Bonus"
        }
    }

    /// SF Symbol name matching this reason.
    var iconName: String {
        switch self {
        case .dailyFree:      return "gift.fill"
        case .adWatch:        return "play.circle.fill"
        case .generation:     return "wand.and.stars"
        case .competitionWin: return "trophy.fill"
        case .streakBonus:    return "flame.fill"
        }
    }
}

// MARK: - CreditTransaction

struct CreditTransaction: Codable, Identifiable, Sendable {
    let id: String
    let userId: String
    let amount: Int        // positive = earn, negative = spend
    let reason: CreditReason
    let createdAt: Date

    // MARK: Computed

    var isEarning: Bool { amount > 0 }
    var isSpending: Bool { amount < 0 }

    var formattedAmount: String {
        amount > 0 ? "+\(amount)" : "\(amount)"
    }

    // MARK: Mocks

    static let mockEarn = CreditTransaction(
        id: "tx-mock-001",
        userId: "mock-user-001",
        amount: CreditCost.dailyFree,
        reason: .dailyFree,
        createdAt: Date()
    )

    static let mockSpend = CreditTransaction(
        id: "tx-mock-002",
        userId: "mock-user-001",
        amount: -CreditCost.fluxPro,
        reason: .generation,
        createdAt: Date().addingTimeInterval(-1800)
    )

    static let mockHistory: [CreditTransaction] = [
        CreditTransaction(
            id: "tx-mock-001",
            userId: "mock-user-001",
            amount: CreditCost.dailyFree,
            reason: .dailyFree,
            createdAt: Date()
        ),
        CreditTransaction(
            id: "tx-mock-002",
            userId: "mock-user-001",
            amount: -CreditCost.fluxPro,
            reason: .generation,
            createdAt: Date().addingTimeInterval(-1800)
        ),
        CreditTransaction(
            id: "tx-mock-003",
            userId: "mock-user-001",
            amount: CreditCost.perAdWatch,
            reason: .adWatch,
            createdAt: Date().addingTimeInterval(-3600)
        ),
        CreditTransaction(
            id: "tx-mock-004",
            userId: "mock-user-001",
            amount: 2000,
            reason: .competitionWin,
            createdAt: Date().addingTimeInterval(-86400)
        )
    ]
}

// MARK: - Vote (from spec)

struct Vote: Codable, Sendable {
    let id: String
    let userId: String
    let generationId: String
    let createdAt: Date
}

// MARK: - ReportCategory (from spec)

enum ReportCategory: String, Codable, CaseIterable, Sendable {
    case offensive
    case spam
    case deepfake
    case other

    var displayLabel: String {
        switch self {
        case .offensive: return "Offensive Content"
        case .spam:      return "Spam"
        case .deepfake:  return "Deepfake / Non-consensual"
        case .other:     return "Other"
        }
    }
}

// MARK: - ContentReport (from spec)

struct ContentReport: Codable, Sendable {
    let id: String
    let reporterId: String
    let generationId: String
    let category: ReportCategory
    let createdAt: Date
}
