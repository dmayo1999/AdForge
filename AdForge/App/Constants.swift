// Constants.swift
// AdForge
//
// Design tokens, credit costs, API endpoints, and default subs.

import SwiftUI

// MARK: - Design Tokens

enum Design {
    // MARK: Colors
    static let accent         = Color(red: 0.486, green: 0.227, blue: 0.929)  // #7C3AED
    static let accentLight    = Color(red: 0.655, green: 0.545, blue: 0.980)  // #A78BFA
    static let background     = Color(red: 0.059, green: 0.059, blue: 0.059)  // #0F0F0F
    static let surface        = Color(red: 0.102, green: 0.102, blue: 0.180)  // #1A1A2E
    static let surfaceLight   = Color(red: 0.145, green: 0.145, blue: 0.239)  // #25253D
    static let textPrimary    = Color.white
    static let textSecondary  = Color(red: 0.612, green: 0.639, blue: 0.686)  // #9CA3AF
    static let success        = Color(red: 0.063, green: 0.725, blue: 0.506)  // #10B981
    static let warning        = Color(red: 0.961, green: 0.620, blue: 0.043)  // #F59E0B
    static let error          = Color(red: 0.937, green: 0.267, blue: 0.267)  // #EF4444
    static let heart          = Color(red: 0.925, green: 0.286, blue: 0.600)  // #EC4899
    static let credit         = Color(red: 0.984, green: 0.749, blue: 0.141)  // #FBBF24

    // MARK: Typography
    static let titleFont:    Font = .system(size: 28, weight: .bold,      design: .rounded)
    static let headlineFont: Font = .system(size: 20, weight: .semibold,  design: .rounded)
    static let bodyFont:     Font = .system(size: 16, weight: .regular)
    static let captionFont:  Font = .system(size: 13, weight: .medium)
    static let badgeFont:    Font = .system(size: 11, weight: .bold)

    // MARK: Spacing
    static let paddingSM:        CGFloat = 8
    static let paddingMD:        CGFloat = 16
    static let paddingLG:        CGFloat = 24
    static let paddingXL:        CGFloat = 32
    static let cornerRadius:     CGFloat = 16
    static let cornerRadiusSM:   CGFloat = 10
    static let cornerRadiusXL:   CGFloat = 24

    // MARK: Gradient Helpers
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Credit Costs

enum CreditCost {
    static let fluxPro           = 300
    static let fluxDev           = 200
    static let wan25             = 1000
    static let kling25           = 800
    static let dailyFree         = 500
    static let perAdWatch        = 1000
    static let maxAdWatchesPerDay = 30
}

// MARK: - API

enum API {
    static let baseURL       = "https://adforge-api.vercel.app"
    static let generateImage = "/api/generate-image"
    static let generateVideo = "/api/generate-video"
    static let checkPrompt   = "/api/check-prompt"

    // Fully-qualified convenience URLs
    static var generateImageURL: URL { URL(string: baseURL + generateImage)! }
    static var generateVideoURL: URL { URL(string: baseURL + generateVideo)! }
    static var checkPromptURL:   URL { URL(string: baseURL + checkPrompt)! }
}

// MARK: - Default Subs

/// The six launch Subs shipped with the app.
enum DefaultSubs {
    static let all: [Sub] = [
        Sub(
            id: "sub-best-meme",
            name: "Best Meme",
            description: "Drop your funniest AI-generated meme. The community votes for the most hilarious.",
            iconName: "face.smiling.inverse",
            acceptedTypes: [.image],
            isActive: true,
            votingWindowHours: 24
        ),
        Sub(
            id: "sub-cinematic-landscape",
            name: "Cinematic Landscape",
            description: "Awe-inspiring vistas, golden-hour light, epic scale. One prompt, infinite worlds.",
            iconName: "mountain.2.fill",
            acceptedTypes: [.image],
            isActive: true,
            votingWindowHours: 48
        ),
        Sub(
            id: "sub-hyperrealistic-portrait",
            name: "Hyperrealistic Portrait",
            description: "Indistinguishable from photography. Faces, textures, and soul captured in pixels.",
            iconName: "person.crop.rectangle.fill",
            acceptedTypes: [.image],
            isActive: true,
            votingWindowHours: 48
        ),
        Sub(
            id: "sub-surreal-dreamscape",
            name: "Surreal Dreamscape",
            description: "Reality bends here. Impossible architecture, dreamlike palettes, pure imagination.",
            iconName: "sparkles",
            acceptedTypes: [.image],
            isActive: true,
            votingWindowHours: 48
        ),
        Sub(
            id: "sub-viral-short-video",
            name: "Viral Short Video",
            description: "Create the next viral AI video clip. Motion, story, and wow factor in under 10 seconds.",
            iconName: "play.rectangle.fill",
            acceptedTypes: [.video],
            isActive: true,
            votingWindowHours: 24
        ),
        Sub(
            id: "sub-funny-ai-fails",
            name: "Funny AI Fails",
            description: "Glitchy hands, melting faces, physics gone wrong — celebrate the beautiful failures.",
            iconName: "exclamationmark.triangle.fill",
            acceptedTypes: [.image, .video],
            isActive: true,
            votingWindowHours: 24
        )
    ]
}
