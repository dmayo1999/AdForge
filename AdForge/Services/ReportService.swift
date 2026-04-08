// ReportService.swift
// AdForge
//
// User content reporting.
// MVP: Stores reports locally in UserDefaults.
// TODO: Replace with Firestore write + server-side moderation queue.

import Foundation

// MARK: - ReportError

enum ReportError: LocalizedError {
    case alreadyReported
    case reportFailed

    var errorDescription: String? {
        switch self {
        case .alreadyReported: return "You have already reported this content."
        case .reportFailed:    return "Failed to submit report. Please try again."
        }
    }
}

// MARK: - ReportService

@MainActor
@Observable
final class ReportService {

    // MARK: UserDefaults Keys
    private enum Keys {
        static let reports          = "adforge.reports.submitted"
        static let reportedIds      = "adforge.reports.reported_ids"
    }

    // MARK: State
    private(set) var submittedReports: [ContentReport] = []
    private(set) var reportedGenerationIds: Set<String> = []

    // MARK: Init

    init() {
        loadPersistedData()
    }

    // MARK: - Report Content

    /// Submits a content report for a generation.
    /// Throws if the user has already reported this content.
    func reportContent(generationId: String, category: ReportCategory) async throws {
        guard !reportedGenerationIds.contains(generationId) else {
            throw ReportError.alreadyReported
        }

        // Simulate network call
        try await Task.sleep(nanoseconds: 600_000_000)

        let report = ContentReport(
            id: UUID().uuidString,
            reporterId: "local",  // TODO: Use real user ID from AuthService
            generationId: generationId,
            category: category,
            createdAt: Date()
        )

        submittedReports.insert(report, at: 0)
        reportedGenerationIds.insert(generationId)
        persist()

        // TODO: Write to Firestore "reports" collection and trigger Cloud Function
    }

    // MARK: - Query

    func hasReported(generationId: String) -> Bool {
        reportedGenerationIds.contains(generationId)
    }

    // MARK: - Persistence

    private func persist() {
        // Save reports
        if let data = try? JSONEncoder().encode(submittedReports) {
            UserDefaults.standard.set(data, forKey: Keys.reports)
        }
        // Save reported IDs
        let idsArray = Array(reportedGenerationIds)
        UserDefaults.standard.set(idsArray, forKey: Keys.reportedIds)
    }

    private func loadPersistedData() {
        // Load reports
        if let data = UserDefaults.standard.data(forKey: Keys.reports),
           let decoded = try? JSONDecoder().decode([ContentReport].self, from: data) {
            submittedReports = decoded
        }
        // Load reported IDs
        if let ids = UserDefaults.standard.stringArray(forKey: Keys.reportedIds) {
            reportedGenerationIds = Set(ids)
        }
    }
}
