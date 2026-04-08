// AdService.swift
// AdForge
//
// Rewarded ad integration.
// MVP: Simulates ads with a 2-second delay, always rewards.
// TODO: Replace with real AppLovin MAX SDK integration.

import Foundation

// MARK: - AdError

enum AdError: LocalizedError {
    case adNotReady
    case adFailed(message: String)
    case dailyLimitReached

    var errorDescription: String? {
        switch self {
        case .adNotReady:
            return "No ad is ready. Please try again in a moment."
        case .adFailed(let msg):
            return "Ad playback failed: \(msg)"
        case .dailyLimitReached:
            return "You've reached today's ad limit. Come back tomorrow for more!"
        }
    }
}

// MARK: - AdService

@MainActor
@Observable
final class AdService {

    // MARK: State
    private(set) var isAdReady: Bool = false
    private(set) var isLoading: Bool = false

    // MARK: - Load Rewarded Ad

    /// Pre-loads a rewarded ad so it is ready to show instantly.
    /// TODO: Replace with ALRewardedAd.load() from AppLovin MAX SDK.
    func loadRewardedAd() async {
        guard !isAdReady && !isLoading else { return }
        isLoading = true

        // Simulate AppLovin MAX ad load (~1s)
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        isAdReady = true
        isLoading = false
    }

    // MARK: - Show Rewarded Ad

    /// Presents a rewarded ad and returns true if the user completed it.
    /// Throws if no ad is ready or playback fails.
    /// TODO: Replace with real AppLovin MAX presentation flow.
    func showRewardedAd() async throws -> Bool {
        guard isAdReady else {
            throw AdError.adNotReady
        }

        isAdReady = false

        // Simulate a 2-second ad
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // Preload the next ad in the background
        Task { await loadRewardedAd() }

        // MVP: always returns true (user completed the ad)
        // TODO: Hook into AppLovin MAX delegate callback for real completion status.
        return true
    }

    // MARK: - Convenience

    /// Loads an ad if one is not already loaded or loading.
    func ensureAdLoaded() async {
        if !isAdReady && !isLoading {
            await loadRewardedAd()
        }
    }
}
