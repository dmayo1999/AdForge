// StudioViewModel.swift
// AdForge

import SwiftUI

@MainActor @Observable
final class StudioViewModel {

    // MARK: - Properties

    var selectedType: GenerationType = .image {
        didSet {
            // Reset model to first valid model for the new type
            selectedModel = availableModels.first ?? .fluxDev
        }
    }
    var selectedModel: AIModel = .fluxDev
    var promptText: String = ""
    var isGenerating: Bool = false
    var generationProgress: String? = nil
    var lastGeneration: Generation? = nil
    var showingResult: Bool = false

    // MARK: - Computed Properties

    var availableModels: [AIModel] {
        AIModel.allCases.filter { $0.type == selectedType }
    }

    var creditCost: Int {
        selectedModel.creditCost
    }

    var canGenerate: Bool {
        guard let user = appState.currentUser else { return false }
        return !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && user.credits >= creditCost
    }

    var canGenerateWithAd: Bool {
        !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && appState.adService.isAdReady
            && (appState.currentUser?.adWatchesToday ?? 0) < CreditCost.maxAdWatchesPerDay
    }

    var adsRemainingToday: Int {
        let watched = appState.currentUser?.adWatchesToday ?? 0
        return max(0, CreditCost.maxAdWatchesPerDay - watched)
    }

    // MARK: - Private

    private let appState: AppState

    // MARK: - Init

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Methods

    func generate() async {
        let trimmedPrompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return }
        guard let _ = appState.currentUser else { return }
        guard !isGenerating else { return }

        isGenerating = true
        generationProgress = "Checking prompt..."

        do {
            // Safety check
            let isSafe = try await appState.generationService.checkPrompt(prompt: trimmedPrompt)
            guard isSafe else {
                generationProgress = nil
                isGenerating = false
                appState.errorMessage = "Your prompt was flagged. Please try different wording."
                return
            }

            // Spend credits
            generationProgress = "Spending credits..."
            try await appState.creditService.spendCredits(amount: creditCost, reason: .generation)

            // Generate
            generationProgress = selectedType == .image
                ? "Generating image \(selectedModel.estimatedTime)..."
                : "Generating video \(selectedModel.estimatedTime)..."

            let displayName = appState.currentUser?.displayName ?? "Creator"
            let userId = appState.currentUser?.id ?? "local"
            let generation: Generation
            if selectedType == .image {
                generation = try await appState.generationService.generateImage(
                    prompt: trimmedPrompt,
                    model: selectedModel,
                    userId: userId,
                    userDisplayName: displayName
                )
            } else {
                generation = try await appState.generationService.generateVideo(
                    prompt: trimmedPrompt,
                    model: selectedModel,
                    userId: userId,
                    userDisplayName: displayName
                )
            }

            lastGeneration = generation
            generationProgress = nil
            isGenerating = false
            showingResult = true

        } catch {
            generationProgress = nil
            isGenerating = false
            appState.errorMessage = error.localizedDescription
        }
    }

    func watchAdAndGenerate() async {
        guard !isGenerating else { return }
        isGenerating = true
        generationProgress = "Loading ad..."

        do {
            await appState.adService.loadRewardedAd()
            generationProgress = "Showing ad..."
            let completed = try await appState.adService.showRewardedAd()

            if completed {
                generationProgress = "Crediting account..."
                // recordAdWatch() handles both the counter increment AND earnCredits internally
                await appState.creditService.recordAdWatch()
                isGenerating = false
                generationProgress = nil
                await generate()
            } else {
                isGenerating = false
                generationProgress = nil
            }
        } catch {
            isGenerating = false
            generationProgress = nil
            appState.errorMessage = error.localizedDescription
        }
    }
}
