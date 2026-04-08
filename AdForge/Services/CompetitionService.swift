// CompetitionService.swift
// AdForge
//
// Manages sub competitions and entries.
// TODO: Replace in-memory store with Firestore.

import Foundation

// MARK: - CompetitionError

enum CompetitionError: LocalizedError {
    case subNotFound
    case alreadySubmitted
    case votingClosed
    case entryNotFound
    case generationNotFound

    var errorDescription: String? {
        switch self {
        case .subNotFound:        return "This competition could not be found."
        case .alreadySubmitted:   return "You've already submitted an entry to this competition."
        case .votingClosed:       return "Voting has closed for this competition."
        case .entryNotFound:      return "Entry not found."
        case .generationNotFound: return "The selected generation could not be found."
        }
    }
}

// MARK: - CompetitionService

@MainActor
@Observable
final class CompetitionService {

    // MARK: State
    private(set) var subs: [Sub] = []
    private(set) var entries: [String: [CompetitionEntry]] = [:]  // keyed by subId
    private(set) var userSubmissions: Set<String> = []             // subIds the user has entered

    // MARK: - Fetch Subs

    /// Returns all active sub competitions.
    /// TODO: Fetch from Firestore collection "subs".
    func fetchSubs() async throws -> [Sub] {
        try await Task.sleep(nanoseconds: 400_000_000)
        subs = DefaultSubs.all
        return subs
    }

    // MARK: - Fetch Entries

    /// Returns all entries for a given sub, unsorted.
    func fetchEntries(subId: String) async throws -> [CompetitionEntry] {
        guard subs.contains(where: { $0.id == subId }) || DefaultSubs.all.contains(where: { $0.id == subId }) else {
            throw CompetitionError.subNotFound
        }

        try await Task.sleep(nanoseconds: 400_000_000)

        // Return cached or generate mock entries
        if let cached = entries[subId] { return cached }

        let mockEntries = generateMockEntries(subId: subId)
        entries[subId] = mockEntries
        return mockEntries
    }

    // MARK: - Submit Entry

    /// Submits a generation as an entry to the specified sub.
    func submitEntry(generationId: String, subId: String) async throws {
        guard !userSubmissions.contains(subId) else {
            throw CompetitionError.alreadySubmitted
        }

        guard let sub = (subs.isEmpty ? DefaultSubs.all : subs).first(where: { $0.id == subId }) else {
            throw CompetitionError.subNotFound
        }

        guard sub.isActive else {
            throw CompetitionError.votingClosed
        }

        try await Task.sleep(nanoseconds: 500_000_000)

        let votingEnds = Date().addingTimeInterval(Double(sub.votingWindowHours) * 3600)
        let entry = CompetitionEntry(
            id: UUID().uuidString,
            generationId: generationId,
            subId: subId,
            userId: "local",  // TODO: Use real user ID
            userDisplayName: "You",
            voteCount: 0,
            submittedAt: Date(),
            votingEndsAt: votingEnds,
            mediaURL: "",     // TODO: Resolve from GenerationService
            prompt: "",       // TODO: Resolve from GenerationService
            model: .fluxDev   // TODO: Resolve from GenerationService
        )

        var subEntries = entries[subId] ?? []
        subEntries.insert(entry, at: 0)
        entries[subId] = subEntries
        userSubmissions.insert(subId)

        // TODO: Write to Firestore "competitionEntries" collection
    }

    // MARK: - Fetch Leaderboard

    /// Returns entries for a sub sorted by vote count, descending.
    func fetchLeaderboard(subId: String) async throws -> [CompetitionEntry] {
        let allEntries = try await fetchEntries(subId: subId)
        return allEntries.sorted { $0.voteCount > $1.voteCount }
    }

    // MARK: - Vote on Entry

    /// Casts a vote on a competition entry.
    func voteForEntry(entryId: String, subId: String) async throws {
        guard var subEntries = entries[subId],
              let index = subEntries.firstIndex(where: { $0.id == entryId }) else {
            throw CompetitionError.entryNotFound
        }

        guard subEntries[index].isVotingOpen else {
            throw CompetitionError.votingClosed
        }

        try await Task.sleep(nanoseconds: 300_000_000)
        subEntries[index].voteCount += 1
        entries[subId] = subEntries

        // TODO: POST vote to Firestore
    }

    // MARK: - Helpers

    func hasSubmitted(to subId: String) -> Bool {
        userSubmissions.contains(subId)
    }

    // MARK: - Mock Data Generator

    private func generateMockEntries(subId: String) -> [CompetitionEntry] {
        let userNames = ["PixelWizard", "DreamForge", "ArtBot9000", "NeonMuse", "VoidCreator", "CosmicVision"]
        let prompts = [
            "A surreal landscape where mountains float in clouds of liquid gold",
            "Hyperrealistic portrait of a cyberpunk street musician at dusk",
            "Ancient temple ruins reclaimed by bioluminescent jungle vines",
            "Time-lapse of a city built by ants, photographed at macro scale",
            "A melting clocktower in a desert of broken mirrors",
            "Portrait of an elder tree spirit with bark-skin and glowing eyes"
        ]
        let imageURLs = [
            "https://images.unsplash.com/photo-1513407030348-c983a97b98d8?w=1080",
            "https://images.unsplash.com/photo-1546961342-ea5f71ba193e?w=1080",
            "https://images.unsplash.com/photo-1682685797365-41f45b562c0a?w=1080",
            "https://images.unsplash.com/photo-1533743983669-94fa5c4338ec?w=1080",
            "https://images.unsplash.com/photo-1614741118887-7a4ee193a5fa?w=1080",
            "https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?w=1080"
        ]
        let models: [AIModel] = [.fluxPro, .fluxDev, .fluxPro, .fluxDev, .fluxPro, .fluxDev]
        let voteCounts = [391, 210, 178, 132, 87, 44]

        return (0..<6).map { i in
            CompetitionEntry(
                id: "entry-\(subId)-\(i)",
                generationId: "gen-\(subId)-\(i)",
                subId: subId,
                userId: "user-\(i)",
                userDisplayName: userNames[i],
                voteCount: voteCounts[i],
                submittedAt: Date().addingTimeInterval(Double(-i) * 3600),
                votingEndsAt: Date().addingTimeInterval(72_000),
                mediaURL: imageURLs[i],
                prompt: prompts[i],
                model: models[i]
            )
        }
    }
}
