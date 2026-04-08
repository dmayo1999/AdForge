// Competition.swift
// AdForge

import Foundation

// MARK: - Sub

struct Sub: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let description: String
    let iconName: String              // SF Symbol name
    let acceptedTypes: [GenerationType]
    var isActive: Bool
    let votingWindowHours: Int        // 24 or 48

    // MARK: Computed

    /// A human-readable voting window string.
    var votingWindowLabel: String {
        votingWindowHours == 24 ? "24-hour voting" : "48-hour voting"
    }

    /// Whether this sub accepts image entries.
    var acceptsImages: Bool { acceptedTypes.contains(.image) }

    /// Whether this sub accepts video entries.
    var acceptsVideos: Bool { acceptedTypes.contains(.video) }

    // MARK: Mocks

    static let mock = Sub(
        id: "sub-best-meme",
        name: "Best Meme",
        description: "Drop your funniest AI-generated meme. The community votes for the most hilarious.",
        iconName: "face.smiling.inverse",
        acceptedTypes: [.image],
        isActive: true,
        votingWindowHours: 24
    )
}

// MARK: - CompetitionEntry

struct CompetitionEntry: Codable, Identifiable, Sendable {
    let id: String
    let generationId: String
    let subId: String
    let userId: String
    let userDisplayName: String
    var voteCount: Int
    let submittedAt: Date
    let votingEndsAt: Date
    let mediaURL: String
    let prompt: String
    let model: AIModel

    // MARK: Computed

    /// Whether the voting window is still open.
    var isVotingOpen: Bool { votingEndsAt > Date() }

    /// Time remaining in the voting window (nil if closed).
    var timeRemaining: TimeInterval? {
        guard isVotingOpen else { return nil }
        return votingEndsAt.timeIntervalSince(Date())
    }

    // MARK: Mocks

    static let mock = CompetitionEntry(
        id: "entry-mock-001",
        generationId: "gen-mock-001",
        subId: "sub-best-meme",
        userId: "mock-user-001",
        userDisplayName: "ArtBot9000",
        voteCount: 142,
        submittedAt: Date().addingTimeInterval(-3600),
        votingEndsAt: Date().addingTimeInterval(72_000),
        mediaURL: "https://images.unsplash.com/photo-1513407030348-c983a97b98d8?w=1080",
        prompt: "A neon-lit Tokyo street at midnight, rain-soaked reflections, cyberpunk atmosphere",
        model: .fluxPro
    )

    static let mockLeaderboard: [CompetitionEntry] = [
        CompetitionEntry(
            id: "entry-mock-001",
            generationId: "gen-mock-001",
            subId: "sub-best-meme",
            userId: "mock-user-001",
            userDisplayName: "ArtBot9000",
            voteCount: 391,
            submittedAt: Date().addingTimeInterval(-14400),
            votingEndsAt: Date().addingTimeInterval(72_000),
            mediaURL: "https://images.unsplash.com/photo-1533743983669-94fa5c4338ec?w=1080",
            prompt: "A cat wearing a tiny suit presenting a PowerPoint called 'Why Mondays Are Bad'",
            model: .fluxDev
        ),
        CompetitionEntry(
            id: "entry-mock-002",
            generationId: "gen-mock-003",
            subId: "sub-best-meme",
            userId: "mock-user-002",
            userDisplayName: "PixelWizard",
            voteCount: 210,
            submittedAt: Date().addingTimeInterval(-10800),
            votingEndsAt: Date().addingTimeInterval(72_000),
            mediaURL: "https://images.unsplash.com/photo-1546961342-ea5f71ba193e?w=1080",
            prompt: "Oil painting portrait of an elderly samurai",
            model: .fluxPro
        ),
        CompetitionEntry(
            id: "entry-mock-003",
            generationId: "gen-mock-004",
            subId: "sub-best-meme",
            userId: "mock-user-003",
            userDisplayName: "DreamForge",
            voteCount: 87,
            submittedAt: Date().addingTimeInterval(-7200),
            votingEndsAt: Date().addingTimeInterval(72_000),
            mediaURL: "https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?w=1080",
            prompt: "Deep ocean bioluminescent jellyfish ascending",
            model: .fluxDev
        )
    ]
}
