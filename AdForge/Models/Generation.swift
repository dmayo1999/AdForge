// Generation.swift
// AdForge

import Foundation

// MARK: - GenerationType

enum GenerationType: String, Codable, CaseIterable, Sendable {
    case image
    case video
}

// MARK: - AIModel

enum AIModel: String, Codable, CaseIterable, Identifiable, Sendable {
    case fluxPro = "flux-2-pro"
    case fluxDev = "flux-2-dev"
    case wan25   = "wan-2.5"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fluxPro: return "FLUX 2 Pro"
        case .fluxDev: return "FLUX 2 Dev"
        case .wan25:   return "Wan 2.5"
        }
    }

    var type: GenerationType {
        switch self {
        case .fluxPro, .fluxDev: return .image
        case .wan25:             return .video
        }
    }

    var creditCost: Int {
        switch self {
        case .fluxPro: return CreditCost.fluxPro
        case .fluxDev: return CreditCost.fluxDev
        case .wan25:   return CreditCost.wan25
        }
    }

    var description: String {
        switch self {
        case .fluxPro:
            return "Highest quality, photorealistic output. Best for competition entries."
        case .fluxDev:
            return "Fast & creative. Great for experimenting with prompts."
        case .wan25:
            return "State-of-the-art video generation with fluid motion and coherence."
        }
    }

    var estimatedTime: String {
        switch self {
        case .fluxPro: return "~15s"
        case .fluxDev: return "~8s"
        case .wan25:   return "~45s"
        }
    }
}

// MARK: - Generation

struct Generation: Codable, Identifiable, Sendable {
    let id: String
    let userId: String
    var userDisplayName: String
    let prompt: String
    let model: AIModel
    let type: GenerationType
    let mediaURL: String          // Cloudinary URL
    let thumbnailURL: String?
    var voteCount: Int
    var isSubmittedToSub: Bool
    var subId: String?
    let createdAt: Date
    let creditCost: Int

    // MARK: - Mocks

    static let mockImage = Generation(
        id: "gen-mock-001",
        userId: "mock-user-001",
        userDisplayName: "ArtBot9000",
        prompt: "A neon-lit Tokyo street at midnight, rain-soaked reflections, cyberpunk atmosphere, ultra-detailed",
        model: .fluxPro,
        type: .image,
        mediaURL: "https://images.unsplash.com/photo-1513407030348-c983a97b98d8?w=1080",
        thumbnailURL: "https://images.unsplash.com/photo-1513407030348-c983a97b98d8?w=400",
        voteCount: 142,
        isSubmittedToSub: true,
        subId: "sub-cinematic-landscape",
        createdAt: Date().addingTimeInterval(-3600),
        creditCost: CreditCost.fluxPro
    )

    static let mockVideo = Generation(
        id: "gen-mock-002",
        userId: "mock-user-001",
        userDisplayName: "ArtBot9000",
        prompt: "A glowing jellyfish slowly ascending through deep ocean water, bioluminescent trails, cinematic",
        model: .wan25,
        type: .video,
        mediaURL: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4",
        thumbnailURL: "https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?w=400",
        voteCount: 73,
        isSubmittedToSub: false,
        subId: nil,
        createdAt: Date().addingTimeInterval(-7200),
        creditCost: CreditCost.wan25
    )

    static let mockFeed: [Generation] = [
        mockImage,
        mockVideo,
        Generation(
            id: "gen-mock-003",
            userId: "mock-user-002",
            userDisplayName: "NeonDreamer42",
            prompt: "Oil painting portrait of an elderly samurai, weathered face, distant mountains, golden hour",
            model: .fluxDev,
            type: .image,
            mediaURL: "https://images.unsplash.com/photo-1546961342-ea5f71ba193e?w=1080",
            thumbnailURL: "https://images.unsplash.com/photo-1546961342-ea5f71ba193e?w=400",
            voteCount: 55,
            isSubmittedToSub: true,
            subId: "sub-hyperrealistic-portrait",
            createdAt: Date().addingTimeInterval(-10800),
            creditCost: CreditCost.fluxDev
        ),
        Generation(
            id: "gen-mock-004",
            userId: "mock-user-003",
            userDisplayName: "PixelMuse777",
            prompt: "A cat wearing a tiny suit presenting a PowerPoint called 'Why Mondays Are Bad'",
            model: .fluxDev,
            type: .image,
            mediaURL: "https://images.unsplash.com/photo-1533743983669-94fa5c4338ec?w=1080",
            thumbnailURL: "https://images.unsplash.com/photo-1533743983669-94fa5c4338ec?w=400",
            voteCount: 391,
            isSubmittedToSub: true,
            subId: "sub-best-meme",
            createdAt: Date().addingTimeInterval(-14400),
            creditCost: CreditCost.fluxDev
        )
    ]
}
