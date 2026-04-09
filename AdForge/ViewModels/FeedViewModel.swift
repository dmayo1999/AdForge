// FeedViewModel.swift
// AdForge

import SwiftUI

@MainActor @Observable
final class FeedViewModel {

    // MARK: - Properties

    var generations: [Generation] = []
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var currentPage: Int = 0
    private var hasMore: Bool = true

    // MARK: - Private

    private let appState: AppState

    // MARK: - Init

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Methods

    func loadFeed() async {
        guard !isLoading else { return }
        isLoading = true
        currentPage = 0
        hasMore = true

        do {
            let results = try await appState.feedService.fetchFeed(page: 0)
            generations = results
            hasMore = !results.isEmpty
        } catch {
            appState.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadMore() async {
        guard !isLoadingMore, hasMore, !isLoading else { return }
        isLoadingMore = true
        let nextPage = currentPage + 1

        do {
            let results = try await appState.feedService.fetchFeed(page: nextPage)
            if results.isEmpty {
                hasMore = false
            } else {
                generations.append(contentsOf: results)
                currentPage = nextPage
            }
        } catch {
            appState.errorMessage = error.localizedDescription
        }

        isLoadingMore = false
    }

    func vote(for generation: Generation) async {
        guard let user = appState.currentUser else { return }
        guard user.heartsRemaining > 0 else {
            appState.errorMessage = "No hearts remaining today."
            return
        }
        guard !appState.feedService.hasVoted(generationId: generation.id) else { return }

        do {
            try await appState.feedService.voteForGeneration(id: generation.id)
            // Optimistically update local count
            if let idx = generations.firstIndex(where: { $0.id == generation.id }) {
                generations[idx].voteCount += 1
            }
            // Decrement hearts
            appState.currentUser?.heartsRemaining -= 1
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    func hasVoted(for generation: Generation) -> Bool {
        appState.feedService.hasVoted(generationId: generation.id)
    }

    func report(generation: Generation, category: ReportCategory) async {
        do {
            try await appState.reportService.reportContent(
                generationId: generation.id,
                category: category
            )
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }
}
