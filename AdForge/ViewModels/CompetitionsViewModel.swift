// CompetitionsViewModel.swift
// AdForge

import SwiftUI

@MainActor @Observable
final class CompetitionsViewModel {

    // MARK: - Properties

    var subs: [Sub] = []
    var selectedSub: Sub? = nil
    var entries: [CompetitionEntry] = []
    var leaderboard: [CompetitionEntry] = []
    var isLoading: Bool = false
    private var votedEntryIds: Set<String> = []

    // MARK: - Private

    private let appState: AppState

    // MARK: - Init

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Methods

    func loadSubs() async {
        guard !isLoading else { return }
        isLoading = true
        do {
            subs = try await appState.competitionService.fetchSubs()
        } catch {
            // Fall back to default subs if fetch fails
            subs = DefaultSubs.all
            appState.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadEntries(for sub: Sub) async {
        selectedSub = sub
        isLoading = true
        do {
            entries = try await appState.competitionService.fetchEntries(subId: sub.id)
        } catch {
            appState.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadLeaderboard(for sub: Sub) async {
        do {
            leaderboard = try await appState.competitionService.fetchLeaderboard(subId: sub.id)
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    func submitEntry(generationId: String, to sub: Sub) async {
        do {
            try await appState.competitionService.submitEntry(
                generationId: generationId,
                subId: sub.id
            )
            // Reload entries after submission
            await loadEntries(for: sub)
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    func vote(for entry: CompetitionEntry) async {
        guard let user = appState.currentUser else { return }
        guard user.heartsRemaining > 0 else {
            appState.errorMessage = "No hearts remaining today."
            return
        }
        do {
            try await appState.competitionService.voteForEntry(entryId: entry.id, subId: entry.subId)
            // Optimistic update
            if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[idx].voteCount += 1
            }
            if let idx = leaderboard.firstIndex(where: { $0.id == entry.id }) {
                leaderboard[idx].voteCount += 1
            }
            // Decrement hearts
            appState.currentUser?.heartsRemaining -= 1
            // Track voted entry
            votedEntryIds.insert(entry.id)
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    func hasVotedForEntry(_ entryId: String) -> Bool {
        votedEntryIds.contains(entryId)
    }

    var dailyChallengesSub: Sub? {
        subs.first { $0.votingWindowHours == 24 }
    }
}
