// FeedService.swift
// AdForge
//
// In-memory feed store for MVP.
// TODO: Replace with Firestore real-time listener and server-side pagination.

import Foundation

// MARK: - FeedError

enum FeedError: LocalizedError {
    case alreadyVoted
    case generationNotFound
    case votingClosed

    var errorDescription: String? {
        switch self {
        case .alreadyVoted:        return "You've already voted for this post."
        case .generationNotFound:  return "This post could not be found."
        case .votingClosed:        return "Voting has ended for this post."
        }
    }
}

// MARK: - FeedService

@MainActor
@Observable
final class FeedService {

    // MARK: Page Size
    private let pageSize = 20

    // MARK: State
    private(set) var feed: [Generation] = []
    private(set) var votedGenerationIds: Set<String> = []

    // In-memory "database" for MVP
    private var allGenerations: [Generation] = Generation.mockFeed

    // MARK: - Fetch Feed

    /// Returns a paginated list of generations from the feed.
    /// Page is 1-indexed.
    func fetchFeed(page: Int) async throws -> [Generation] {
        // Simulate network latency
        try await Task.sleep(nanoseconds: 500_000_000)

        let start = (page - 1) * pageSize
        guard start < allGenerations.count else { return [] }
        let end = min(start + pageSize, allGenerations.count)

        let slice = Array(allGenerations[start..<end])

        if page == 1 {
            feed = slice
        } else {
            // Append deduplicated items
            let existingIds = Set(feed.map(\.id))
            let newItems = slice.filter { !existingIds.contains($0.id) }
            feed.append(contentsOf: newItems)
        }

        return slice
    }

    // MARK: - Vote

    /// Adds a vote to a generation. Throws if already voted.
    func voteForGeneration(id: String) async throws {
        guard !votedGenerationIds.contains(id) else {
            throw FeedError.alreadyVoted
        }

        guard let index = allGenerations.firstIndex(where: { $0.id == id }) else {
            throw FeedError.generationNotFound
        }

        // Simulate network latency
        try await Task.sleep(nanoseconds: 300_000_000)

        // Optimistic update
        allGenerations[index].voteCount += 1
        votedGenerationIds.insert(id)

        // Sync to local feed view
        if let feedIndex = feed.firstIndex(where: { $0.id == id }) {
            feed[feedIndex].voteCount += 1
        }

        // TODO: POST vote to Firestore via backend
    }

    // MARK: - Has Voted

    func hasVoted(generationId: String) -> Bool {
        votedGenerationIds.contains(generationId)
    }

    // MARK: - Add Generation (called after creation)

    /// Inserts a newly created generation at the top of the feed.
    func addGeneration(_ generation: Generation) {
        allGenerations.insert(generation, at: 0)
        feed.insert(generation, at: 0)
    }

    // MARK: - Remove (for moderation)

    func removeGeneration(id: String) {
        allGenerations.removeAll { $0.id == id }
        feed.removeAll { $0.id == id }
    }
}
