// CreditService.swift
// AdForge
//
// Server-side credit ledger simulation using UserDefaults for MVP.
// TODO: Replace storage with Firestore; run balance mutations server-side.

import Foundation

// MARK: - CreditError

enum CreditError: LocalizedError {
    case insufficientCredits(needed: Int, available: Int)
    case dailyAlreadyCollected
    case adLimitReached
    case ledgerCorrupted

    var errorDescription: String? {
        switch self {
        case .insufficientCredits(let needed, let available):
            return "Not enough credits. Need \(needed), have \(available)."
        case .dailyAlreadyCollected:
            return "Daily free credits already collected today."
        case .adLimitReached:
            return "You've reached the daily ad watch limit of \(CreditCost.maxAdWatchesPerDay) ads."
        case .ledgerCorrupted:
            return "Credit data is corrupted. Please contact support."
        }
    }
}

// MARK: - CreditService

@MainActor
@Observable
final class CreditService {

    // MARK: UserDefaults Keys
    private enum Keys {
        static let balance           = "adforge.credits.balance"
        static let adWatchesToday    = "adforge.credits.ad_watches_today"
        static let adWatchDate       = "adforge.credits.ad_watch_date"
        static let dailyCollected    = "adforge.credits.daily_collected"
        static let dailyCollectDate  = "adforge.credits.daily_collect_date"
        static let transactions      = "adforge.credits.transactions"
    }

    // MARK: Published State
    private(set) var balance: Int = 0
    private(set) var transactions: [CreditTransaction] = []

    // MARK: - Init

    init() {
        // Load balance immediately from UserDefaults
        balance = UserDefaults.standard.integer(forKey: Keys.balance)
        loadTransactions()
    }

    // MARK: - Fetch Balance

    /// Reads current balance from local ledger.
    /// TODO: Fetch from Firestore for multi-device sync.
    func fetchBalance() async -> Int {
        resetDailyCountersIfNeeded()
        balance = UserDefaults.standard.integer(forKey: Keys.balance)
        return balance
    }

    // MARK: - Spend Credits

    /// Deducts `amount` from the balance, throws if insufficient.
    func spendCredits(amount: Int, reason: CreditReason) async throws {
        let current = await fetchBalance()
        guard current >= amount else {
            throw CreditError.insufficientCredits(needed: amount, available: current)
        }
        let newBalance = current - amount
        UserDefaults.standard.set(newBalance, forKey: Keys.balance)
        balance = newBalance
        recordTransaction(amount: -amount, reason: reason)
    }

    // MARK: - Earn Credits

    /// Adds `amount` to the balance.
    func earnCredits(amount: Int, reason: CreditReason) async {
        let current = await fetchBalance()
        let newBalance = current + amount
        UserDefaults.standard.set(newBalance, forKey: Keys.balance)
        balance = newBalance
        recordTransaction(amount: amount, reason: reason)
    }

    // MARK: - Daily Free Credits

    /// Awards daily free credits if not already collected today. Returns true if awarded.
    func collectDailyFree() async throws -> Bool {
        resetDailyCountersIfNeeded()

        let collected = UserDefaults.standard.bool(forKey: Keys.dailyCollected)
        if collected { throw CreditError.dailyAlreadyCollected }

        await earnCredits(amount: CreditCost.dailyFree, reason: .dailyFree)
        UserDefaults.standard.set(true, forKey: Keys.dailyCollected)
        UserDefaults.standard.set(Date(), forKey: Keys.dailyCollectDate)
        return true
    }

    // MARK: - Ad Watch

    /// Returns true if the user can still watch ads today.
    func canWatchAd() -> Bool {
        resetDailyCountersIfNeeded()
        let watched = UserDefaults.standard.integer(forKey: Keys.adWatchesToday)
        return watched < CreditCost.maxAdWatchesPerDay
    }

    /// Records a completed ad watch and credits the reward.
    func recordAdWatch() async {
        guard canWatchAd() else { return }
        let watched = UserDefaults.standard.integer(forKey: Keys.adWatchesToday)
        UserDefaults.standard.set(watched + 1, forKey: Keys.adWatchesToday)
        UserDefaults.standard.set(Date(), forKey: Keys.adWatchDate)
        await earnCredits(amount: CreditCost.perAdWatch, reason: .adWatch)
    }

    // MARK: - Private

    private func resetDailyCountersIfNeeded() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastAdDate = UserDefaults.standard.object(forKey: Keys.adWatchDate) as? Date {
            let lastDay = calendar.startOfDay(for: lastAdDate)
            if lastDay < today {
                UserDefaults.standard.set(0, forKey: Keys.adWatchesToday)
            }
        }

        if let lastCollectDate = UserDefaults.standard.object(forKey: Keys.dailyCollectDate) as? Date {
            let lastDay = calendar.startOfDay(for: lastCollectDate)
            if lastDay < today {
                UserDefaults.standard.set(false, forKey: Keys.dailyCollected)
            }
        }
    }

    private func recordTransaction(amount: Int, reason: CreditReason) {
        let transaction = CreditTransaction(
            id: UUID().uuidString,
            userId: "local",  // TODO: Use real user ID from AuthService
            amount: amount,
            reason: reason,
            createdAt: Date()
        )
        transactions.insert(transaction, at: 0)
        // Persist (keep last 100)
        let toSave = Array(transactions.prefix(100))
        if let data = try? JSONEncoder().encode(toSave) {
            UserDefaults.standard.set(data, forKey: Keys.transactions)
        }
    }

    private func loadTransactions() {
        guard
            let data = UserDefaults.standard.data(forKey: Keys.transactions),
            let decoded = try? JSONDecoder().decode([CreditTransaction].self, from: data)
        else { return }
        transactions = decoded
    }
}
