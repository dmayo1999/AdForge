// Badge.swift
// AdForge

import Foundation

// MARK: - Badge

struct Badge: Codable, Identifiable, Sendable {
    let id: String
    let name: String          // e.g. "Meme Lord"
    let iconName: String      // SF Symbol name
    let description: String
    let earnedAt: Date?       // nil = not yet earned

    init(id: String, name: String, iconName: String, description: String, earnedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.description = description
        self.earnedAt = earnedAt
    }
}

// MARK: - All Available Badges

extension Badge {
    /// The complete catalogue of badges a user can earn.
    static let allAvailable: [Badge] = [
        Badge(
            id: "badge-meme-lord",
            name: "Meme Lord",
            iconName: "crown.fill",
            description: "Win the Best Meme sub at least once."
        ),
        Badge(
            id: "badge-video-virtuoso",
            name: "Video Virtuoso",
            iconName: "film.fill",
            description: "Generate 10 or more videos."
        ),
        Badge(
            id: "badge-streak-master",
            name: "Streak Master",
            iconName: "flame.fill",
            description: "Log in 7 days in a row."
        ),
        Badge(
            id: "badge-first-creation",
            name: "First Creation",
            iconName: "wand.and.stars",
            description: "Generate your very first image or video."
        ),
        Badge(
            id: "badge-popular-post",
            name: "Popular Post",
            iconName: "heart.fill",
            description: "Receive 100 votes on a single generation."
        ),
        Badge(
            id: "badge-competition-winner",
            name: "Competition Winner",
            iconName: "trophy.fill",
            description: "Finish first in any sub competition."
        ),
        Badge(
            id: "badge-prolific-creator",
            name: "Prolific Creator",
            iconName: "square.stack.3d.up.fill",
            description: "Generate 50 pieces of content."
        ),
        Badge(
            id: "badge-ad-supporter",
            name: "Ad Supporter",
            iconName: "play.circle.fill",
            description: "Watch 10 rewarded ads to earn credits."
        ),
        Badge(
            id: "badge-portrait-master",
            name: "Portrait Master",
            iconName: "person.crop.circle.fill",
            description: "Win the Hyperrealistic Portrait sub."
        ),
        Badge(
            id: "badge-dream-weaver",
            name: "Dream Weaver",
            iconName: "sparkles",
            description: "Win the Surreal Dreamscape sub."
        ),
        Badge(
            id: "badge-landscape-legend",
            name: "Landscape Legend",
            iconName: "mountain.2.fill",
            description: "Win the Cinematic Landscape sub."
        ),
        Badge(
            id: "badge-viral-star",
            name: "Viral Star",
            iconName: "star.fill",
            description: "Have a video reach 500 votes."
        )
    ]

    // MARK: - Mock

    static let mock = Badge(
        id: "badge-first-creation",
        name: "First Creation",
        iconName: "wand.and.stars",
        description: "Generate your very first image or video.",
        earnedAt: Date()
    )
}
