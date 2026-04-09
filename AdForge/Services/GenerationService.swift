// GenerationService.swift
// AdForge
//
// Handles AI generation requests. Uses NetworkClient to POST to the Vercel backend proxy.
// MVP: Mock mode returns placeholder content after a realistic delay.

import Foundation

// MARK: - GenerationError

enum GenerationError: LocalizedError {
    case unsafePrompt
    case generationFailed(message: String)
    case modelUnavailable
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .unsafePrompt:
            return "Your prompt was flagged. Please revise and try again."
        case .generationFailed(let msg):
            return "Generation failed: \(msg)"
        case .modelUnavailable:
            return "This model is currently unavailable. Please try another."
        case .networkUnavailable:
            return "No network connection. Please check your connection."
        }
    }
}

// MARK: - API Request / Response Types

private struct GenerateImageRequest: Encodable, Sendable {
    let prompt: String
    let model: String
    let userId: String
}

private struct GenerateVideoRequest: Encodable, Sendable {
    let prompt: String
    let model: String
    let userId: String
}

private struct GenerateImageResponse: Decodable, Sendable {
    let imageURL: String
    let thumbnailURL: String?
}

private struct GenerateVideoResponse: Decodable, Sendable {
    let videoURL: String
    let thumbnailURL: String?
}

// MARK: - GenerationService

@MainActor
@Observable
final class GenerationService {

    // MARK: Mock Mode
    /// When true, returns placeholder media instead of calling the real backend.
    /// TODO: Set to false once the Vercel backend is deployed.
    var isMockMode: Bool = true

    // MARK: State
    private(set) var recentGenerations: [Generation] = []

    // MARK: - Generate Image

    /// Generates an image using the specified model and prompt.
    /// Returns a `Generation` with the resulting media URL.
    func generateImage(prompt: String, model: AIModel, userId: String = "local", userDisplayName: String = "Creator") async throws -> Generation {
        guard model.type == .image else {
            throw GenerationError.modelUnavailable
        }

        // Local safety check first
        guard PromptFilter.isPromptSafe(prompt) else {
            throw GenerationError.unsafePrompt
        }

        if isMockMode {
            return try await mockGenerateImage(prompt: prompt, model: model, userId: userId, userDisplayName: userDisplayName)
        }

        // Real backend call
        let request = GenerateImageRequest(prompt: prompt, model: model.rawValue, userId: userId)
        let response: GenerateImageResponse = try await NetworkClient.shared.post(
            path: API.generateImage,
            body: request
        )

        let generation = Generation(
            id: UUID().uuidString,
            userId: userId,
            userDisplayName: userDisplayName,
            prompt: prompt,
            model: model,
            type: .image,
            mediaURL: response.imageURL,
            thumbnailURL: response.thumbnailURL,
            voteCount: 0,
            isSubmittedToSub: false,
            subId: nil,
            createdAt: Date(),
            creditCost: model.creditCost
        )
        recentGenerations.insert(generation, at: 0)
        return generation
    }

    // MARK: - Generate Video

    /// Generates a video using the Wan 2.5 model.
    func generateVideo(prompt: String, model: AIModel, userId: String = "local", userDisplayName: String = "Creator") async throws -> Generation {
        guard model.type == .video else {
            throw GenerationError.modelUnavailable
        }

        guard PromptFilter.isPromptSafe(prompt) else {
            throw GenerationError.unsafePrompt
        }

        if isMockMode {
            return try await mockGenerateVideo(prompt: prompt, model: model, userId: userId, userDisplayName: userDisplayName)
        }

        let request = GenerateVideoRequest(prompt: prompt, model: model.rawValue, userId: userId)
        let response: GenerateVideoResponse = try await NetworkClient.shared.post(
            path: API.generateVideo,
            body: request
        )

        let generation = Generation(
            id: UUID().uuidString,
            userId: userId,
            userDisplayName: userDisplayName,
            prompt: prompt,
            model: model,
            type: .video,
            mediaURL: response.videoURL,
            thumbnailURL: response.thumbnailURL,
            voteCount: 0,
            isSubmittedToSub: false,
            subId: nil,
            createdAt: Date(),
            creditCost: model.creditCost
        )
        recentGenerations.insert(generation, at: 0)
        return generation
    }

    // MARK: - Check Prompt

    /// Checks a prompt against the server-side blocklist.
    /// Returns true if the prompt is safe.
    func checkPrompt(prompt: String) async throws -> Bool {
        // Always run local check first (fast path)
        guard PromptFilter.isPromptSafe(prompt) else { return false }

        if isMockMode {
            // In mock mode, trust the local filter
            return true
        }

        struct CheckRequest:  Encodable, Sendable { let prompt: String }
        struct CheckResponse: Decodable, Sendable { let safe: Bool }

        let request = CheckRequest(prompt: prompt)
        let response: CheckResponse = try await NetworkClient.shared.post(
            path: API.checkPrompt,
            body: request
        )
        return response.safe
    }

    // MARK: - Mock Implementations

    /// Simulates image generation with a realistic delay and a placeholder image.
    private func mockGenerateImage(prompt: String, model: AIModel, userId: String, userDisplayName: String) async throws -> Generation {
        // Simulate generation time: FLUX Dev ~8s, FLUX Pro ~15s
        let delay: UInt64 = model == .fluxPro ? 4_000_000_000 : 2_500_000_000
        try await Task.sleep(nanoseconds: delay)

        // Rotate through a set of Unsplash placeholders
        let placeholders = [
            "https://images.unsplash.com/photo-1682685797365-41f45b562c0a?w=1080",
            "https://images.unsplash.com/photo-1682685797703-2bb22dbb9b55?w=1080",
            "https://images.unsplash.com/photo-1547592180-85f173990554?w=1080",
            "https://images.unsplash.com/photo-1614741118887-7a4ee193a5fa?w=1080",
            "https://images.unsplash.com/photo-1573339010577-e1e71c5dc13c?w=1080"
        ]
        let mediaURL = placeholders.randomElement()!
        let thumbURL = mediaURL.replacingOccurrences(of: "w=1080", with: "w=400")

        let generation = Generation(
            id: UUID().uuidString,
            userId: userId,
            userDisplayName: userDisplayName,
            prompt: prompt,
            model: model,
            type: .image,
            mediaURL: mediaURL,
            thumbnailURL: thumbURL,
            voteCount: 0,
            isSubmittedToSub: false,
            subId: nil,
            createdAt: Date(),
            creditCost: model.creditCost
        )
        recentGenerations.insert(generation, at: 0)
        return generation
    }

    /// Simulates video generation with a longer delay and a placeholder video.
    private func mockGenerateVideo(prompt: String, model: AIModel, userId: String, userDisplayName: String) async throws -> Generation {
        // Wan 2.5 takes ~45s in real life; simulate 5s for MVP
        try await Task.sleep(nanoseconds: 5_000_000_000)

        let generation = Generation(
            id: UUID().uuidString,
            userId: userId,
            userDisplayName: userDisplayName,
            prompt: prompt,
            model: model,
            type: .video,
            mediaURL: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4",
            thumbnailURL: "https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?w=400",
            voteCount: 0,
            isSubmittedToSub: false,
            subId: nil,
            createdAt: Date(),
            creditCost: model.creditCost
        )
        recentGenerations.insert(generation, at: 0)
        return generation
    }
}
