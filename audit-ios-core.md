# AdForge iOS Core Audit

**Auditor:** Subagent  
**Date:** 2026-04-08  
**Scope:** All files in `AdForge/App/`, `AdForge/Models/`, `AdForge/Services/`, `AdForge/Utilities/`  
**Reference documents:** `AdForge_PRD_v2.md` (v2.0), `AdForge/ARCHITECTURE.md`

---

## File-by-File Audit

---

### 1. `AdForge/App/Constants.swift`

**Status: COMPLETE**

**Issues found:**
1. Colors are defined using raw `Color(red:green:blue:)` float literals rather than `Color(hex:)`. The architecture spec shows `Color(hex: "#7C3AED")`. The numeric values are correct, but the `Color(hex:)` init (defined in `Extensions.swift`) is not used here — meaning `Constants.swift` does not depend on `Extensions.swift`, which is fine, but if `Extensions.swift` is ever removed, nothing breaks here. Consistency would be better.
2. `DefaultSubs` references the `Sub` type from `Competition.swift`. At compile time this is fine (same module), but the file has no `import Foundation` — it only imports `SwiftUI`. `Sub` is a `Foundation`-dependent struct. This compiles correctly because `Sub` is in the same module and `SwiftUI` transitively imports `Foundation`, but it is worth noting the implicit dependency.
3. **`Viral Short Video` Sub's `votingWindowHours` is `24`, but the PRD (Section 12.3) specifies `48 hours` for that Sub.** This is a PRD alignment bug. The table in the PRD:  
   - Viral Short Video → **48 hours**  
   But `Constants.swift` line 125 sets `votingWindowHours: 24`.
4. No `import Foundation` — relies on transitive import from SwiftUI. Harmless at present but fragile.

**Missing from spec:** Nothing structurally missing. The `CreditCost`, `API`, `Design`, and `DefaultSubs` enums all match the architecture spec exactly.

---

### 2. `AdForge/App/AppState.swift`

**Status: PARTIAL**

**Issues found:**
1. **`collectDailyCredits()` has a logic race / double-mutation bug.** The method reads `currentUser`, mutates a local `var user`, then writes `currentUser = user`. Between the `let balance = await creditService.fetchBalance()` suspension point and the `currentUser = user` assignment, another concurrent mutation to `currentUser` (e.g., from `checkSession()`) would be silently clobbered. Although the class is `@MainActor` — meaning all code runs serially on the main actor — the pattern of copying `currentUser` into a local `var user`, suspending, then reassigning `currentUser = user` is still hazardous: any change made to `currentUser` during the `await` (e.g. from another `Task` that also runs on `@MainActor`) will be lost. The balance update should be applied as a targeted mutation: `currentUser?.credits = newBalance`.
2. **`checkSession()` has the same copy-then-overwrite pattern** at line 89: `currentUser?.credits = balance` is actually the correct form, but immediately above it line 85 assigns `currentUser = user` from `authService.checkExistingSession()`. That's fine on first read, but then line 89 does `currentUser?.credits = balance` — this is correct. No bug here after careful reading, but the pattern is inconsistent with `collectDailyCredits()`.
3. **`collectDailyCredits()` only checks `user.dailyFreeCreditsCollected`** (from the locally-cached user struct). If the app is killed and relaunched, and `AuthService.resetDailyStateIfNeeded()` already reset the flag to `false`, this guard could be stale because `creditService.collectDailyFree()` independently checks its own `UserDefaults` key. If both agree, this is fine; but the two systems (`AuthService` and `CreditService`) maintain separate flags for the same concept, creating a potential split-brain where one says already-collected and the other says not-yet-collected. See also CreditService issue #4.
4. **No `signIn` method.** The architecture spec says `AppState` coordinates auth, but there is no `func signIn() async` that delegates to `authService.signInWithApple()` and then updates `currentUser`/`isAuthenticated`. Views will need to call `authService.signInWithApple()` directly and then manually update AppState — this is inconsistent with the intended architecture where `AppState` is the single coordination point.
5. **`handleError(_:)` just sets `errorMessage` with `localizedDescription`** — there is no differentiation between error types. Some errors (e.g., network timeout, ad failure) should trigger different UI flows (retry vs. dismissal), but this method treats them all identically.
6. **`showingAuth` is never set to `true` anywhere in `AppState`.** If it's meant to trigger an auth sheet, something needs to set it. The only time it could be useful is if a deep link or unauthenticated action fires — but there's no mechanism for that here.

**Missing from spec:**
- No `signInWithApple()` coordination method on `AppState` itself (spec implies `AppState` orchestrates auth).
- No `updateCredits(amount:)` or similar method to keep `currentUser.credits` in sync with `CreditService.balance`. The two can drift.

---

### 3. `AdForge/Models/User.swift`

**Status: COMPLETE**

**Issues found:**
1. **`xpToNextLevel` formula is too simple.** The PRD (Section 12.4) says "Level thresholds increase exponentially." The implementation uses `500 * level` (linear). For Level 1 → 2: 500 XP. For Level 99 → 100: 49,500 XP. This is steeper at high levels but not exponential — it's purely linear scaling. This is a PRD alignment issue (P1 feature, so lower priority, but it will produce a flatter-than-intended progression curve).
2. **`levelProgress` uses `xp % xpToNextLevel`** — this calculates progress within the *current level's XP chunk*, not total XP. For example, if a user has 1,200 XP and is level 5 (threshold 2,500 XP), the modulo gives `1,200 % 2,500 = 1,200`, which is correct. But if the user has accumulated 6,000 XP total and level is still 5 (which shouldn't happen if levels are auto-incremented correctly), it would give `6,000 % 2,500 = 1,000`, hiding the overflow. The real bug is that there's **no level-up logic anywhere in the codebase** — `level` and `xp` are just raw fields on the struct with no service or logic to auto-increment them when XP thresholds are crossed.
3. **`heartsRemaining` mock value is `20`** — matches PRD exactly. No issue.
4. **No `maxHeartsPerDay` constant** referenced on the model. The value `20` is hardcoded in `AuthService.swift` line 133 (`user.heartsRemaining = 20`) and in `User.swift` mock (line 63). If the daily heart count ever changes, it needs to be updated in two places. Should reference `a constant` (e.g., `AppConstants.maxHeartsPerDay`).

**Missing from spec:** All spec fields are present. No missing properties.

---

### 4. `AdForge/Models/Generation.swift`

**Status: COMPLETE**

**Issues found:**
1. **`AIModel.estimatedTime` for `fluxPro` returns `"~15s"`** but the mock generation in `GenerationService` uses a 4-second delay (not 15). The displayed time and the actual mock time are inconsistent, which will confuse users during testing.
2. **`AIModel.estimatedTime` for `wan25` returns `"~45s"`** but the mock video generation uses a 5-second delay. Same inconsistency.
3. **`GenerationType` conforms to `CaseIterable`** but there is no usage of `allCases` anywhere in the audited files. No issue — just extra protocol conformance, which is fine.
4. **`Generation` has no `userDisplayName` field.** The feed shows creator names, but `Generation` only stores `userId`. Views will need a separate lookup or denormalized field. `CompetitionEntry` has `userDisplayName` — `Generation` doesn't, creating an asymmetry. The architecture spec does not include `userDisplayName` on `Generation`, so this matches the spec, but it is a production gap: the Feed UI cannot display creator names without an extra user lookup.

**Missing from spec:** All spec fields are present.

---

### 5. `AdForge/Models/Competition.swift`

**Status: COMPLETE**

**Issues found:**
1. **`CompetitionEntry.timeRemaining` uses `Date()` at call time** — this is correct for instantaneous calls, but if used in a SwiftUI view binding without a timer, it will become stale (shows wrong countdown). Views must use a `TimelineView` or `Timer` publisher to keep this live.
2. **`Sub.mock` hardcodes `votingWindowHours: 24`** — acceptable for preview purposes.
3. **`mockLeaderboard` all entries have the same `subId` ("sub-best-meme")** regardless of which Sub is being viewed. When `CompetitionService.generateMockEntries()` is called, it creates entries with the passed `subId`, so this mock is only realistic for the best-meme sub. Not a runtime bug.

**Missing from spec:** All spec fields are present (`Sub`, `CompetitionEntry`). Matches architecture exactly.

---

### 6. `AdForge/Models/CreditTransaction.swift`

**Status: COMPLETE**

**Issues found:**
1. **`Vote` and `ReportCategory`/`ContentReport` are defined in `CreditTransaction.swift`** — this is incorrect file placement. `Vote`, `ReportCategory`, and `ContentReport` have nothing to do with credit transactions. The architecture spec lists them as separate conceptual types. While Swift does not care about file placement at compile time, this organization will confuse future contributors.
2. **`CreditReason` is `CaseIterable`** in this file, but the spec only has it as `Codable, Sendable`. This is additive and harmless.
3. **`mockHistory` contains duplicate `id` values** — `tx-mock-001` appears in both `mockEarn` and `mockHistory[0]`. If the mock history is ever placed in a SwiftUI `List` with `\.id` as the identifier, this will cause rendering glitches.

**Missing from spec:** Nothing. All required types (`CreditTransaction`, `CreditReason`, `Vote`, `ReportCategory`, `ContentReport`) are present.

---

### 7. `AdForge/Models/Badge.swift`

**Status: COMPLETE**

**Issues found:**
1. **`Badge.allAvailable` defines "Video Virtuoso" as requiring 10 videos**, but the PRD (Section 12.4) says "25 video gens." This is a PRD misalignment.
2. **`Badge.allAvailable` defines "Meme Lord" as "Win the Best Meme sub at least once"**, but the PRD says it requires "50 meme submissions." This is a significant PRD misalignment — winning once vs. 50 submissions are very different achievement bars.
3. **No badge-award logic exists anywhere** in the audited files. Badges are defined but there is no service method or game-logic hook to award them. This is consistent with P1 scope, but it means the badge catalogue is entirely decorative at MVP launch.
4. **`Badge` has no `isEarned` computed property** — `earnedAt` being non-nil signals earned status, but a convenience property would make view code cleaner.

**Missing from spec:** All required fields present. Architecture spec does not define badge award logic in the core layer.

---

### 8. `AdForge/Services/NetworkClient.swift`

**Status: COMPLETE**

**Issues found:**
1. **No authentication header is attached to outbound requests.** `applyDefaultHeaders()` only sets `Accept` and `User-Agent`. Production calls to the Vercel backend will need a Firebase ID token (or some auth secret) in `Authorization: Bearer <token>` to prevent unauthenticated access. There is a `TODO` comment in `AuthService` about storing a session token, but `NetworkClient` has no mechanism to receive or attach it.
2. **`NetworkError` is not `Sendable`-conforming via `@unchecked` or proper stored-property guarantees.** All associated values are `String` or `Int` (both `Sendable`), so implicit `Sendable` conformance should work under Swift 6. No actual issue, but worth confirming during strict concurrency build.
3. **The `perform` method decodes into `Response` even for empty success responses (e.g., 204 No Content).** The `data.isEmpty` check at line 168 throws `NetworkError.noData`, which means any endpoint that returns `204` with no body (which is idiomatic for POST-with-no-response-body) will always throw. A no-body response type (e.g., `struct Empty: Decodable {}`) would be needed, or a separate `performVoid` method.
4. **`URLSession` is not `Sendable` in strict Swift 6** unless it is configured as `actor`-isolated. `NetworkClient` is an `actor`, and `URLSession` is called inside it — this is correct. No issue here; `URLSession` is `Sendable` since iOS 15 / Swift concurrency adoption.
5. **No retry logic** for transient network failures. A 500 error or timeout simply propagates. The PRD's reliability requirements (ad failure = retry option) imply some retry or backoff logic should eventually exist.
6. **`timeoutIntervalForRequest` is 60 seconds**, which is appropriate for video generation (up to 60s per PRD). However, the `URLSession` timeout and the Vercel Edge Function timeout may conflict — Vercel's default function timeout is 30 seconds (10s for hobby plan). If the backend times out at 30s, the iOS client won't know until it receives a 504, which falls into the generic `serverError` case.

**Missing from spec:** Nothing. `NetworkClient` is not explicitly specced beyond being an HTTP client — it fulfills its role.

---

### 9. `AdForge/Services/AuthService.swift`

**Status: STUB** (Apple Sign-In is entirely simulated)

**Issues found:**
1. **`signInWithApple()` is a complete stub.** It does not implement `ASAuthorizationAppleIDProvider` or `ASAuthorizationController` at all. It simulates an 0.8s delay, generates a random UUID, and creates a local `AFUser`. No actual Apple Sign-In occurs. This means R-01 (Apple Sign-In) is **not implemented**.
2. **Session token is a hardcoded string** `"mock-session-token-\(user.id)"` — no real Firebase Auth token is stored or validated.
3. **`checkExistingSession()` restores from `UserDefaults` without any token expiry check.** The comment says "TODO: Validate Firebase Auth token expiry." In production, expired tokens will authenticate users silently until they are invalidated, which is a security issue.
4. **`persist(user:)` stores the full `AFUser` struct in `UserDefaults`.** This includes `credits`, `totalGenerations`, etc. In production, all of this lives in Firestore — storing it locally means the client-side copy can diverge from the server. The architecture spec explicitly warns against client-side credit storage.
5. **`resetDailyStateIfNeeded()` is `async` but has no actual async work** — it calls no `await` operations. It's `async` only because it's called from `checkExistingSession()` via `await`. This is technically fine but misleading.
6. **`resetDailyStateIfNeeded()` resets hearts to the hardcoded value `20`** at line 133. This magic number should reference a constant (e.g., `AppConstants.maxHeartsPerDay`). If the PRD changes the daily heart count, this would need to be updated manually.
7. **`generateDisplayName()` can produce names already in use** — there's no uniqueness check against any backend. Duplicate display names are certain once user count grows.
8. **`AuthService` is `@MainActor @Observable`** — correct per spec.
9. **Missing `Sendable` annotation on `AuthError`** — this enum is throwable across async contexts and should be `Sendable`. Under Swift 6 strict concurrency this may produce a warning or error. (All cases have no associated values, so implicit `Sendable` conformance may apply, but explicit conformance is safer.)

**Missing from spec:**
- Real `ASAuthorizationAppleIDProvider` flow
- Firebase Auth integration
- Token validation
- The spec's `signInWithApple() async throws -> AFUser` signature is technically present but entirely mocked

---

### 10. `AdForge/Services/CreditService.swift`

**Status: PARTIAL** (functional but client-side only)

**Issues found:**
1. **All credit state is stored in `UserDefaults` on the client.** The PRD (Section 12.1) and architecture spec both explicitly state: "Credit balance is stored server-side in Firestore. Client displays a cached value, synced on every transaction. **No client-side manipulation possible.**" The current implementation is entirely client-side and trivially tampered with (any user can edit their `UserDefaults` balance).
2. **`spendCredits()` and `earnCredits()` are not atomic.** `spendCredits()` calls `fetchBalance()` (which reads `UserDefaults`) and then writes back. If two concurrent `Task` instances both call `spendCredits()` at the same moment — theoretically possible even on `@MainActor` because `await fetchBalance()` is a suspension point — they could both read the same balance, both pass the guard, and both subtract, resulting in a negative balance. Under `@MainActor` this cannot happen in practice (only one task runs at a time on the main actor), but the pattern is still dangerous if the actor isolation is ever relaxed.
3. **`recordTransaction()` hardcodes `userId: "local"`** — not linked to the authenticated user. Transaction history will be incorrect in production.
4. **`dailyFreeCreditsCollected` is tracked both in `AFUser.dailyFreeCreditsCollected` (via `AuthService`) and in `UserDefaults` (`Keys.dailyCollected`) in `CreditService`.** These two flags can desync:
   - `AuthService.resetDailyStateIfNeeded()` resets `user.dailyFreeCreditsCollected = false`.
   - `CreditService.resetDailyCountersIfNeeded()` resets `Keys.dailyCollected = false`.
   - `CreditService.collectDailyFree()` reads `Keys.dailyCollected`, not `AFUser.dailyFreeCreditsCollected`.
   - `AppState.collectDailyCredits()` guards on `user.dailyFreeCreditsCollected`, not `Keys.dailyCollected`.
   A user could collect daily credits twice if one flag is reset but the other isn't, or be blocked from collecting if one flag is set but the app state says otherwise.
5. **`canWatchAd()` is a synchronous function** (returns `Bool` directly), which is correct per spec. Good.
6. **`adWatchesToday` is tracked in `UserDefaults` separately from `AFUser.adWatchesToday`** — same split-brain issue as #4. `AFUser.adWatchesToday` is updated by `AuthService.resetDailyStateIfNeeded()` but `CreditService` only reads its own `UserDefaults` key. They can diverge.
7. **`resetDailyCountersIfNeeded()` uses `Keys.adWatchDate` as the sentinel for resetting the ad watch counter**, but if the user has never watched an ad, this date is never set, so the counter is never reset. On Day 2, `adWatchesToday` in `UserDefaults` will still be 0 (from default), so `canWatchAd()` will still return `true`. This is actually the correct behavior (counter starts at 0 each day), but only by accident — the reset path is skipped entirely for first-time ad watchers.

**Missing from spec:**
- Server-side Firestore integration
- Multi-device sync
- The spec's `earnCredits(amount:reason:) async` signature is present but returns `Void` — the spec shows the same void return, so this matches.

---

### 11. `AdForge/Services/GenerationService.swift`

**Status: PARTIAL** (mock mode on by default; real API call path exists but is untested)

**Issues found:**
1. **`isMockMode = true` is hardcoded.** There is no environment variable, build flag, or configuration to switch this off. Switching to production requires modifying source code.
2. **`generateImage()` and `generateVideo()` take `userId: String = "local"` as a default parameter.** In production, the real user ID must be passed. Views/ViewModels that call these functions without explicitly passing `userId` will send `"local"` to the backend, which will corrupt the server-side ledger.
3. **`checkPrompt()` skips the server-side check entirely in mock mode** (line 162: `return true`). This means the server-side blocklist (the primary safety layer per PRD Section 10, Layer 2) is never exercised in development. Safety regressions could go undetected until production.
4. **`GenerateImageResponse` uses `imageURL`** as the decoded field name, but `NetworkClient` applies `.convertFromSnakeCase` key decoding. The Vercel backend returns `{ "imageURL": ... }` (camelCase per the architecture spec). Snake-case key conversion would expect `image_u_r_l`, which would fail to decode correctly. This is a **compilation-time invisible but runtime-critical decoding bug** — the backend response field must either be `image_url` (snake case) or the decoder's key strategy must be overridden. The same issue applies to `thumbnailURL`, `videoURL`.
5. **Mock video generation simulates a 5-second delay (`5_000_000_000` nanoseconds)** but the comment says "Wan 2.5 takes ~45s in real life." The model picker's `estimatedTime` returns `"~45s"`. Users will be confused when mock mode shows 5s but the real model will take 45s.
6. **`recentGenerations` is a private-setter `[Generation]` stored in-memory** with no persistence. If the app is backgrounded and memory is freed, the list is lost. This is expected for MVP but should be documented.
7. **No cancellation support.** If the user navigates away during generation, the `Task` keeps running (consuming credits, making network calls). Long video generation (45s+) without cancellation is a UX problem.
8. **`GenerationService` is `@MainActor @Observable`** — correct per spec.

**Missing from spec:**
- The spec defines `checkPrompt(prompt:) async throws -> Bool` — implementation matches but has mock-mode bypass issue.

---

### 12. `AdForge/Services/FeedService.swift`

**Status: PARTIAL** (in-memory only; no real backend)

**Issues found:**
1. **`fetchFeed()` is 1-indexed** (page 1 is the first page). This is documented in the comment but is inconsistent with most pagination APIs (0-indexed). ViewModels must remember to pass `page: 1` for initial load and increment correctly. The `FeedViewModel` is not in scope for this audit but any off-by-one in the ViewModel would result in skipping the first 20 items.
2. **The feed ranking algorithm** is described in the PRD as "recency + vote count (simple algorithm)" (R-06). The current implementation returns items in insertion order — pure recency, no vote weighting. This is an MVP simplification but the PRD specifies a composite sort.
3. **`votedGenerationIds` is in-memory only** — if the app relaunches, the user can vote for the same item again. There is no persistence and no server-side deduplication.
4. **`voteForGeneration()` does not check `heartsRemaining`** — the user's daily vote allowance is tracked on `AFUser.heartsRemaining` and in `AuthService`, but `FeedService.voteForGeneration()` has no connection to that counter. A user could vote unlimited times without spending hearts.
5. **`allGenerations` starts as `Generation.mockFeed`** (4 hardcoded items). The feed will always show only these 4 items (plus anything generated in-session). There is no real Firestore pagination.
6. **No report integration** — `removeGeneration(id:)` exists but there's nothing that calls it when a report is submitted. The `ReportService` stores reports locally but doesn't trigger removal from the feed.
7. **`FeedService` spec signature `fetchFeed(page: Int) async throws -> [Generation]` matches** — correct.

**Missing from spec:**
- `voteForGeneration` should respect the `heartsRemaining` counter — currently completely decoupled.
- Real Firestore pagination and feed ranking.

---

### 13. `AdForge/Services/CompetitionService.swift`

**Status: PARTIAL**

**Issues found:**
1. **`submitEntry()` creates a `CompetitionEntry` with `mediaURL: ""`** (empty string) and `prompt: ""` (empty string). These are critical display fields. The entry needs to resolve the `Generation` by `generationId` from `GenerationService` before creating the `CompetitionEntry`. The TODO comment acknowledges this, but the bug means any submitted entry will appear as a blank card in the leaderboard.
2. **`submitEntry()` hardcodes `model: .fluxDev`** for all submitted entries regardless of the actual generation's model. Another consequence of not resolving the generation.
3. **`submitEntry()` hardcodes `userId: "local"` and `userDisplayName: "You"`** — real user info is not populated.
4. **`userSubmissions` only prevents re-submission within a session** — there is no persistence, so if the app relaunches, `userSubmissions` is empty and the user could submit to the same sub again. In production, the server would reject duplicates, but the client-side guard would fail silently.
5. **`fetchEntries()` validates `subId` against both `subs` (which may be empty on first call) and `DefaultSubs.all`** (line 54). This double-check is a workaround for `subs` being empty before `fetchSubs()` is called. The correct fix is to always seed `subs` from `DefaultSubs.all` in `init()`.
6. **`voteForEntry()` is not in the architecture spec.** The spec defines `CompetitionService` as having: `fetchSubs`, `fetchEntries`, `submitEntry`, `fetchLeaderboard`. The implemented `voteForEntry` is an addition — not a problem, but undocumented.
7. **`voteForEntry()` does not decrement `heartsRemaining`** — same issue as `FeedService`: hearts are completely disconnected from voting actions.
8. **`CompetitionService` is `@MainActor @Observable`** — correct per spec.
9. **`alreadySubmitted` error is thrown based on `userSubmissions.contains(subId)`**, but the spec says one submission per sub. The current logic is correct conceptually, though it's only enforced in-session.
10. **`generateMockEntries()` always generates 6 entries regardless of subId** — video-only subs (e.g., Viral Short Video) will show image entries. This is fine for mock data but misleading.

**Missing from spec:**
- `GenerationService` integration in `submitEntry()` to populate `mediaURL`, `prompt`, and `model`.
- Persistent submission tracking.

---

### 14. `AdForge/Services/AdService.swift`

**Status: STUB** (AppLovin MAX is entirely simulated)

**Issues found:**
1. **`showRewardedAd()` always returns `true`** — 100% completion rate in mock mode. Real ads have user skip/close behaviors that must be handled. The PRD specifies that credits are only awarded on completion.
2. **No AppLovin MAX SDK integration.** No `import AppLovinSDK` or equivalent. The entire class is a 2-second `Task.sleep` simulation. R-03 (Rewarded ad integration) is **not implemented**.
3. **`loadRewardedAd()` uses `try? await Task.sleep(...)` with a discarded error** — if the `Task` is cancelled (e.g., app goes to background), the `sleep` is cancelled but the error is silently dropped, and `isAdReady = true` is still set. This means a cancelled load would incorrectly mark an ad as ready.
4. **`Task { await loadRewardedAd() }` at line 70** — this is an unstructured `Task` created inside an `@MainActor` context. Under Swift 6 strict concurrency, spawning a new unstructured `Task` from `@MainActor` is fine (it inherits the actor), but there is no handle kept, so it cannot be cancelled. If `showRewardedAd()` is called rapidly in succession, multiple background preload tasks could be queued.
5. **No ad failure / retry handling.** The PRD (R-03) states: "Given an ad network failure, when the ad fails to load, then the user sees a retry option (not a dead end)." The mock `AdService` cannot fail, so this path is never tested.
6. **`isAdReady` and `isLoading` are correct observable properties** per spec.
7. **The `ensureAdLoaded()` method is a nice addition** not in the spec — no issue.

**Missing from spec:**
- Real AppLovin MAX `ALRewardedAd` integration
- Delegate callbacks for ad events (completion, failure, click)
- Ad unit ID configuration

---

### 15. `AdForge/Services/ReportService.swift`

**Status: PARTIAL**

**Issues found:**
1. **Reports are stored only in `UserDefaults`** on the client. The PRD (R-14) requires reports to be submitted to a server-side moderation queue. `TODO` comment acknowledges this.
2. **`reportContent()` hardcodes `reporterId: "local"`** — real user ID not populated.
3. **No integration with `FeedService.removeGeneration()`** — after 3 unique reports, content should be auto-hidden per PRD Section 10. The `ReportService` stores reports but doesn't count unique reporters per generation or trigger auto-hide. This is the most important moderation behavior missing.
4. **`reportedGenerationIds` is persisted across app sessions** — good. It correctly prevents a single user from reporting the same content twice.
5. **`ReportService` is `@MainActor @Observable`** — correct per spec.
6. **The spec defines `reportContent(generationId:category:) async throws` — matches exactly.**

**Missing from spec:**
- Server-side report submission (Firestore write)
- Auto-hide logic after 3 unique reports
- Cross-user report aggregation (requires server-side state)

---

### 16. `AdForge/Utilities/Extensions.swift`

**Status: COMPLETE**

**Issues found:**
1. **`Date.relativeString` creates a new `DateFormatter` inside the `default` case every time it is called.** `DateFormatter` is expensive to initialize. This should be a static/cached formatter.
2. **`Date.mediumString`, `Date.timeString` also create `DateFormatter` instances per call.** Same performance concern. In a scrolling feed with many timestamps, this could cause hitching.
3. **`View.hideKeyboard()` uses `UIApplication.shared.sendAction(...)`** which is a UIKit call from a SwiftUI context. This is fine on iOS 17 but a more SwiftUI-idiomatic approach would be `@FocusState`. Minor style issue.
4. **`errorBanner(_:)` modifier uses `.task { try? await Task.sleep(...) }` to auto-dismiss** — if the parent view is refreshed (e.g., list reload) while the banner is showing, a new `.task` is started that competes with the existing one, potentially leading to early or duplicate dismissal. This is a known SwiftUI task-identity issue.
5. **`Color(hex:)` extension is defined in `Extensions.swift`** but `Constants.swift` does not use it (uses raw RGB values instead). This is minor inconsistency — not a bug.
6. **`String.isNotEmpty` is also privately defined in `PromptFilter.swift`** (as a `private extension String`). This creates a duplicate definition. In Swift, private extensions in different files are scoped to their file, so there's no compilation conflict, but it's redundant and could cause confusion.
7. **`UIImage.resized(to:)` uses `min(widthRatio, heightRatio)` to maintain aspect ratio** — this is correct "fit" scaling (never crops). If "fill" scaling is ever needed (e.g., for watermark output), a different method is needed.

**Missing from spec:** All extensions described in or implied by the spec are present.

---

### 17. `AdForge/Utilities/PromptFilter.swift`

**Status: PARTIAL**

**Issues found:**
1. **Client-side blocklist is hardcoded** — the architecture spec and PRD both describe the server-side blocklist as the primary safety gate (updatable without an app update). The client filter is correctly described as a backup layer, which matches the comments. However, the client list cannot be updated without an app release. If a new attack vector is discovered (e.g., a prompt phrasing that bypasses both filters), the client-side list offers no protection until the next app update.
2. **Simple `contains()` substring matching** — easily bypassed by misspellings, zero-width characters, homoglyph substitutions (e.g., "n·ude", "nak3d"). This is acknowledged in comments ("minimal client-side filter"). Not a critical issue given it's a backup layer, but worth documenting.
3. **`isPromptSafe()` rejects empty prompts (`return false`)** — this causes `GenerationService.generateImage()` to throw `GenerationError.unsafePrompt` for empty input. The error message "Your prompt was flagged" is misleading for an empty prompt. The empty-prompt case should return a more specific error or be handled before safety filtering.
4. **`String.isNotEmpty` is defined as `private extension String` here**, duplicating the same extension in `Extensions.swift`. See Extensions.swift issue #6.
5. **`blockedTerms` uses partial-word matching** — "explicit" would flag "explicitly" in legitimate prompts like "explicitly labeled product." "gore" would flag "gorgeous." These false positives could frustrate legitimate users.

**Missing from spec:** The spec defines a `PromptFilter` utility — present and functionally complete as a backup layer.

---

### 18. `AdForge/Utilities/WatermarkRenderer.swift`

**Status: COMPLETE**

**Issues found:**
1. **`applyWatermark(to:) async` variant calls `DispatchQueue.global(qos: .userInitiated).async` and accesses `UIImage`.** Under Swift 6 strict concurrency, `UIImage` is documented as `@MainActor`-isolated in UIKit, but is actually safe to use on background threads for read-only operations (drawing). The `UIGraphicsBeginImageContextWithOptions` call in the synchronous overload is also UIKit-based. Swift 6 may emit a "crossing actor boundary" warning for passing `UIImage` into a non-isolated `DispatchQueue`. **This could fail to compile under Swift 6 strict concurrency.**
2. **The icon rendering in the watermark** (lines 67–73) draws a purple circle as an "AdForge icon approximation" — there is no real app icon composited. For a beta this is acceptable, but it should be replaced with the actual app logo for production.
3. **`applyWatermark(to:)` has two overloads with the same base signature** — one sync and one async. In Swift, this is legal. But calls like `await applyWatermark(to: image)` will always resolve to the async overload, which is correct. The sync overload is called inside `DispatchQueue.global().async`. This is fine.
4. **No deep link is embedded into the watermark.** The PRD (R-11, Section 12.5) specifies: "A deep link (Universal Link) that opens the creation in-app or redirects to App Store if not installed." The watermark renderer only adds a text/visual overlay — it does not encode a deep link into the image metadata or share payload. The share sheet integration (separate file) would need to append the deep link as accompanying text.
5. **`UIGraphicsBeginImageContextWithOptions` is deprecated in iOS 17** in favor of `UIGraphicsImageRenderer`. The code already uses `UIGraphicsImageRenderer` in `UIImage.resized(to:)` (in `Extensions.swift`) but `WatermarkRenderer` still uses the old API. This will produce a deprecation warning on iOS 17+.

**Missing from spec:** All spec-required behavior is present. Deep link attachment is a gap (see issue #4).

---

### 19. `AdForge/Utilities/ModelExtensions.swift`

**Status: COMPLETE**

**Issues found:**
1. **`Sub: Hashable` is implemented in a separate extension file rather than in `Competition.swift`** where `Sub` is defined. This is a style choice but causes the `Hashable` conformance to be easy to miss when reading `Competition.swift`.
2. **`Equatable` conformance for `Sub` (`==` operator) compares only `id`** — two `Sub` instances with the same `id` but different `name` or `isActive` would be considered equal. This could cause bugs if the same sub ID is used for two different Sub configurations. For an immutable struct with a stable `id`, this is the correct pattern.

**Missing from spec:** Nothing.

---

### 20. `AdForge/Utilities/PreviewHelpers.swift`

**Status: COMPLETE**

**Issues found:**
1. **`AppState.preview` is `@MainActor static var`** — correct. This will not cause issues.
2. **`AppState.preview` creates a real `AppState()` with real service instances** (albeit all in mock/stub mode). This means SwiftUI previews instantiate all 7 services. If a service's `init()` has side effects (e.g., `CreditService.init()` reads `UserDefaults`), previews could be affected by leftover test state. In practice this is unlikely to cause issues but is worth noting.
3. **`Generation.mock` and `CompetitionEntry.mocks` are aliases** for existing mock data — fine, just avoiding re-definition.

**Missing from spec:** Nothing.

---

## Summary

### Total files audited: 20

| Category | Count | Files |
|---|---|---|
| App/ | 2 | Constants.swift, AppState.swift |
| Models/ | 5 | User.swift, Generation.swift, Competition.swift, CreditTransaction.swift, Badge.swift |
| Services/ | 8 | NetworkClient.swift, AuthService.swift, CreditService.swift, GenerationService.swift, FeedService.swift, CompetitionService.swift, AdService.swift, ReportService.swift |
| Utilities/ | 5 | Extensions.swift, PromptFilter.swift, WatermarkRenderer.swift, ModelExtensions.swift, PreviewHelpers.swift |

### Files by completeness status

| Status | Files |
|---|---|
| **COMPLETE** | Constants.swift, User.swift, Generation.swift, Competition.swift, CreditTransaction.swift, Badge.swift, NetworkClient.swift, Extensions.swift, WatermarkRenderer.swift, ModelExtensions.swift, PreviewHelpers.swift |
| **PARTIAL** | AppState.swift, CreditService.swift, GenerationService.swift, FeedService.swift, CompetitionService.swift, ReportService.swift, PromptFilter.swift |
| **STUB** | AuthService.swift (no real Apple Sign-In), AdService.swift (no real AppLovin MAX) |

**11 COMPLETE / 7 PARTIAL / 2 STUB**

---

### Critical Issues (would prevent compilation or crash at runtime)

| # | File | Issue |
|---|---|---|
| C-01 | `GenerationService.swift` | **JSON decoding bug**: `NetworkClient` uses `.convertFromSnakeCase`. Backend returns camelCase fields (`imageURL`, `thumbnailURL`, `videoURL`). Snake-case strategy converts `imageURL` → expects `image_u_r_l`. Real mode will fail to decode every API response. |
| C-02 | `WatermarkRenderer.swift` | **Swift 6 strict concurrency**: `UIImage` passed across actor boundaries into `DispatchQueue.global()`. May fail to compile under `SWIFT_STRICT_CONCURRENCY=complete`. |
| C-03 | `AuthService.swift` | **Entire Apple Sign-In is a stub**. R-01 is not implemented. App cannot authenticate real users. |
| C-04 | `AdService.swift` | **Entire rewarded ad system is a stub**. R-03 is not implemented. No AppLovin MAX SDK. App cannot earn credits via ads. |
| C-05 | `CompetitionService.swift` | **`submitEntry()` creates entries with empty `mediaURL`, `prompt`, and hardcoded `model: .fluxDev`** regardless of the actual generation. Any submission will appear as a blank/incorrect leaderboard entry. |
| C-06 | `NetworkClient.swift` | **No auth token on requests**. Production calls to the Vercel backend have no Authorization header. Server will reject all requests if auth is enforced. |

---

### Non-Critical Issues (logic bugs, missing edge cases, improvements)

| # | File | Issue |
|---|---|---|
| N-01 | `Constants.swift` | `Viral Short Video` sub has `votingWindowHours: 24`; PRD specifies 48 hours. |
| N-02 | `AppState.swift` | `collectDailyCredits()` copy-then-overwrite pattern loses concurrent mutations to `currentUser` during `await`. |
| N-03 | `AppState.swift` | No `signIn()` method on `AppState`; views must call `authService` directly. |
| N-04 | `AppState.swift` | `showingAuth` is never set to `true` by any AppState method. |
| N-05 | `User.swift` | `xpToNextLevel` is linear (`500 * level`); PRD says exponential thresholds. |
| N-06 | `User.swift` / `AuthService.swift` | Magic number `20` for daily hearts in two places; should be a constant. |
| N-07 | `User.swift` | No level-up logic anywhere in the codebase. `level` and `xp` are raw fields that never auto-update. |
| N-08 | `Generation.swift` | No `userDisplayName` on `Generation`; feed cannot display creator names without extra lookup. |
| N-09 | `Generation.swift` | `estimatedTime` strings ("~15s", "~45s") disagree with mock delays (4s, 5s). |
| N-10 | `CreditTransaction.swift` | `Vote`, `ReportCategory`, `ContentReport` are misplaced in this file. |
| N-11 | `CreditTransaction.swift` | Duplicate `id` values in `mockHistory` (`tx-mock-001` appears twice). |
| N-12 | `Badge.swift` | "Video Virtuoso" threshold is 10 videos (file) vs. 25 (PRD). |
| N-13 | `Badge.swift` | "Meme Lord" requirement is "win once" (file) vs. "50 meme submissions" (PRD). |
| N-14 | `Badge.swift` | No badge-award logic exists anywhere. |
| N-15 | `CreditService.swift` | Client-side credit storage contradicts the PRD security requirement ("no client-side manipulation possible"). |
| N-16 | `CreditService.swift` | `dailyFreeCreditsCollected` flag tracked independently in `AuthService` and `CreditService` — can desync. |
| N-17 | `CreditService.swift` | `adWatchesToday` tracked independently in `AuthService` and `CreditService` — can desync. |
| N-18 | `CreditService.swift` | `recordTransaction()` hardcodes `userId: "local"`. |
| N-19 | `GenerationService.swift` | `isMockMode = true` hardcoded; no build-flag or config toggle. |
| N-20 | `GenerationService.swift` | Default `userId: "local"` parameter will corrupt server-side user records. |
| N-21 | `GenerationService.swift` | No task cancellation support; generation continues after user navigates away. |
| N-22 | `FeedService.swift` | No heart/vote accounting — `voteForGeneration()` never decrements `heartsRemaining`. |
| N-23 | `FeedService.swift` | Feed ranking is insertion-order only; PRD requires recency + vote weighting. |
| N-24 | `FeedService.swift` | `votedGenerationIds` not persisted; vote deduplication resets on app restart. |
| N-25 | `FeedService.swift` | No integration with `ReportService` for auto-hiding reported content. |
| N-26 | `CompetitionService.swift` | `userSubmissions` not persisted across sessions. |
| N-27 | `CompetitionService.swift` | `voteForEntry()` never decrements `heartsRemaining`. |
| N-28 | `CompetitionService.swift` | `fetchEntries()` validation workaround (checks both `subs` and `DefaultSubs.all`); should seed `subs` in `init()`. |
| N-29 | `ReportService.swift` | No auto-hide after 3 reports; no cross-user report aggregation. |
| N-30 | `ReportService.swift` | `reporterId: "local"` hardcoded. |
| N-31 | `Extensions.swift` | `DateFormatter` created per call in `relativeString`, `mediumString`, `timeString` — performance issue in feed. |
| N-32 | `Extensions.swift` | `String.isNotEmpty` duplicated privately in `PromptFilter.swift`. |
| N-33 | `PromptFilter.swift` | Empty prompt throws `unsafePrompt` error with misleading message. |
| N-34 | `PromptFilter.swift` | Substring matching creates false positives ("gorgeous" contains "gore"). |
| N-35 | `WatermarkRenderer.swift` | Uses deprecated `UIGraphicsBeginImageContextWithOptions`; should use `UIGraphicsImageRenderer`. |
| N-36 | `WatermarkRenderer.swift` | No deep link embedded in watermark/share payload per PRD R-11. |

---

### Mock vs. Real Implementations

| Feature | Current State | Required for Production |
|---|---|---|
| Apple Sign-In | **MOCK** — random UUID, simulated delay | `ASAuthorizationAppleIDProvider` + Firebase Auth |
| Session persistence | **MOCK** — `UserDefaults` JSON blob | Firebase Auth token + Firestore user document |
| Credit ledger | **MOCK** — `UserDefaults` integers | Firestore server-side ledger + Cloud Functions |
| Image generation | **MOCK** — Unsplash placeholder after delay | Real Vercel proxy → Fal.ai `flux-2-pro` / `flux-2-dev` |
| Video generation | **MOCK** — static Big Buck Bunny MP4 after 5s | Real Vercel proxy → Fal.ai `wan-2.5` |
| Prompt safety check | **MOCK** — trusts local filter in mock mode | Server-side blocklist via `/api/check-prompt` |
| Rewarded ads | **MOCK** — 2-second sleep, always rewards | AppLovin MAX SDK with Unity Ads + AdMob fill |
| Feed | **MOCK** — 4 hardcoded items in memory | Firestore real-time collection with pagination |
| Voting (feed) | **MOCK** — in-memory counter, no persistence | Firestore vote document + heart decrement |
| Competition entries | **MOCK** — generated mock entries, no persistence | Firestore `competitionEntries` collection |
| Competition voting | **MOCK** — in-memory counter | Firestore vote document + heart decrement |
| Content reporting | **MOCK** — `UserDefaults` local storage | Firestore `reports` collection + Cloud Function trigger |
| Leaderboard | **MOCK** — in-memory sort of mock entries | Firestore query, sorted by `voteCount` descending |
| Watermark rendering | **REAL** — Core Graphics, functional | Replace deprecated API; add deep link to share payload |
| Prompt filter (local) | **REAL** — functional backup layer | Supplement with server-side blocklist |
| Network client | **REAL** — functional HTTP actor | Add auth header injection |

---

## PRD Requirement Checklist

### P0 Requirements (R-01 through R-14)

---

#### R-01: Apple Sign-In — supported?
**NO. CRITICAL GAP.**

`AuthService.signInWithApple()` is a stub that creates a local UUID-based user after a simulated delay. No `ASAuthorizationAppleIDProvider`, no `ASAuthorizationController`, no Firebase Auth. The acceptance criteria ("account created within 3 seconds," "auto-authenticated on relaunch") are superficially met by the mock, but there is no real Apple identity involved. R-01 is not production-ready.

---

#### R-02: Credit system with transparent cost preview — supported?
**PARTIALLY.**

- Credit costs are correctly defined in `Constants.swift` and `AIModel.creditCost`.
- `CreditService` has `spendCredits`, `earnCredits`, `collectDailyFree`, `canWatchAd`, `recordAdWatch` — all required methods.
- Cost preview logic depends on `AIModel.creditCost` being accessible before generation — this is available.
- **Gap:** Credit balance is client-side (UserDefaults), violating the PRD's anti-tamper requirement.
- **Gap:** "Insufficient credits" flow (prompt to watch ad) requires ViewModel orchestration not in scope for this audit, but the service layer supports it.
- **Core layer: PARTIAL.** Credit costs and deduction are correct; server-side security is absent.

---

#### R-03: Rewarded video ad integration — supported?
**NO. CRITICAL GAP.**

`AdService` is a 2-second sleep stub. No AppLovin MAX SDK, no real ad loading, no real completion callbacks. The acceptance criteria ("1,000 credits added within 1 second of completion" and "retry option on failure") are simulated only.

---

#### R-04: Image generation (2+ models) — supported?
**PARTIALLY.**

- `AIModel` correctly defines `fluxPro` and `fluxDev` with correct `creditCost` values (300 and 200 respectively) matching the architecture spec.
- `GenerationService.generateImage()` exists for both models.
- **Credit cost note:** Architecture spec defines `fluxPro = 300`, `fluxDev = 200`. The PRD Section 12.1 says "Image generation cost: 150–400 credits (varies by model)." Both values are within this range. ✓
- **Gap:** `isMockMode = true` — real Fal.ai calls do not occur.
- **Gap:** JSON decoding bug (C-01) would cause real mode to fail.
- **Core layer: PARTIAL.** Model definitions and generation flow are correct; real API calls don't work.

---

#### R-05: Video generation (1 model) — supported?
**PARTIALLY.**

- `AIModel.wan25` correctly defined with `creditCost = 1000` credits.
- **PRD cost check:** PRD Section 12.1 says video generation costs "800–1,200 credits." The architecture spec says `wan25 = 1000`. Both `Constants.swift` and `Generation.swift` use `1000` for Wan 2.5. ✓ (within range)
- `GenerationService.generateVideo()` exists.
- **Gap:** Mock mode only; same decoding bug as R-04.
- **Core layer: PARTIAL.** Model definition correct; real API not functional.

---

#### R-06: Community feed (infinite scroll) — supported?
**PARTIALLY.**

- `FeedService.fetchFeed(page:)` implements pagination.
- Deduplication logic present for pagination.
- **Gap:** Feed ranking is insertion-order only — PRD requires "recency + vote count."
- **Gap:** Only 4 hardcoded mock items; no real Firestore backend.
- **Gap:** No real-time updates.
- **Core layer: PARTIAL.**

---

#### R-07: Voting system (hearts) — supported?
**PARTIALLY.**

- `AFUser.heartsRemaining` tracks daily vote allowance — present.
- Heart refill at midnight UTC is implemented in `AuthService.resetDailyStateIfNeeded()` via calendar comparison.
- **Gap:** Daily heart count (20) is correct per PRD: "Users receive 20 hearts daily." ✓
- **Critical gap:** `FeedService.voteForGeneration()` and `CompetitionService.voteForEntry()` never decrement `heartsRemaining`. Hearts are tracked on the user model but are never actually consumed by voting actions. A user can vote unlimited times.
- **Gap:** Heart refill via "watch ad" is mentioned in PRD (US-20) but there is no service method for ad-triggered heart refill; only credit refill is implemented.
- **Core layer: PARTIAL.**

---

#### R-08: Competition Subs (6) — supported?
**MOSTLY YES, with one PRD misalignment.**

`DefaultSubs.all` in `Constants.swift` defines all 6 required Subs:
- Best Meme ✓ (24h voting) ✓
- Cinematic Landscape ✓ (48h voting) ✓
- Hyperrealistic Portrait ✓ (48h voting) ✓
- Surreal Dreamscape ✓ (48h voting) ✓
- Viral Short Video ✓ — **but `votingWindowHours: 24` instead of PRD's 48 hours** ✗
- Funny AI Fails ✓ (24h voting) ✓

The Sub names, descriptions, icons, and accepted types all match the PRD exactly. One voting window is wrong (see C-01 in constants).

**Core layer: MOSTLY SUPPORTED.** One voting window discrepancy.

---

#### R-09: Submit to competition — supported?
**PARTIALLY.**

- `CompetitionService.submitEntry(generationId:subId:)` is implemented.
- **Critical gap:** `submitEntry()` creates entries with empty `mediaURL` and `prompt`, and hardcoded `model: .fluxDev`. The entry on the leaderboard will appear blank.
- **Gap:** No Firestore write; entries are in-memory only and lost on app restart.
- **Core layer: PARTIAL.**

---

#### R-10: Leaderboard per Sub — supported?
**PARTIALLY.**

- `CompetitionService.fetchLeaderboard(subId:)` is implemented — sorts entries by `voteCount` descending.
- **Gap:** Based on mock data only; no real Firestore query.
- **Gap:** Voting window (24h or 48h) is respected via `CompetitionEntry.isVotingOpen` computed property — correctly implemented.
- **Core layer: PARTIAL (logic correct, backend absent).**

---

#### R-11: Share with watermark + deep link — supported?
**PARTIALLY.**

- `WatermarkRenderer.applyWatermark(to:)` correctly renders "made with AdForge" text in the bottom-right corner — matches PRD spec.
- **Gap:** No deep link (Universal Link) is encoded into the share payload. The PRD requires: "A deep link (Universal Link) that opens the creation in-app or redirects to App Store if not installed." The watermark renderer does not embed URLs.
- **Gap:** The share sheet integration (presumably in `ShareSheet.swift` — not in audit scope) is responsible for attaching the deep link as text; `WatermarkRenderer` should not need to embed it. However, it is not clear whether the deep link is wired up anywhere in the audited files.
- **Core layer: PARTIAL.**

---

#### R-12: Daily free credits — supported?
**MOSTLY YES.**

- `CreditService.collectDailyFree()` awards 500 credits per day.
- `CreditCost.dailyFree = 500` — matches PRD exactly. ✓
- `AuthService.resetDailyStateIfNeeded()` resets the flag at calendar-day boundaries.
- `AppState.collectDailyCredits()` is the call site.
- **Gap:** Two independent tracking flags can desync (see N-16).
- **Gap:** Client-side storage; server-side double-collection protection is absent.
- **Core layer: MOSTLY SUPPORTED.**

---

#### R-13: Prompt safety layer — supported?
**PARTIALLY.**

- `PromptFilter.isPromptSafe()` provides a client-side backup filter with a hardcoded blocklist — present and functional.
- `GenerationService.checkPrompt()` calls the server-side `/api/check-prompt` endpoint in non-mock mode.
- **Gap:** In mock mode (`isMockMode = true` — which is the current default), `checkPrompt()` always returns `true` after the local filter, bypassing the server blocklist entirely.
- **Gap:** Client-side list is not updatable without an app release (server-side list is, per PRD).
- **Gap:** The "generic refusal message" for blocked prompts is `GenerationError.unsafePrompt.errorDescription` = "Your prompt was flagged. Please revise and try again." This matches the PRD's "Try a different prompt" intent, though the wording differs slightly.
- **Core layer: PARTIAL.**

---

#### R-14: Content report button — supported?
**PARTIALLY.**

- `ReportService.reportContent(generationId:category:)` is implemented.
- `ReportCategory` includes all four required categories: `offensive`, `spam`, `deepfake`, `other` — matches PRD exactly. ✓
- **Gap:** Reports are stored locally only; no Firestore write.
- **Gap:** Auto-hide after 3 unique reports is not implemented anywhere in the core layer.
- **Gap:** Cross-user report aggregation is impossible without a backend.
- **Core layer: PARTIAL.**

---

### PRD Requirement Summary Table

| Req | Description | Core Layer Status | Blocking Gaps |
|-----|-------------|-------------------|---------------|
| R-01 | Apple Sign-In | ❌ NOT SUPPORTED | Entire auth is stub |
| R-02 | Credit system with cost preview | ⚠️ PARTIAL | Client-side only; no tamper protection |
| R-03 | Rewarded ad integration | ❌ NOT SUPPORTED | Entire ad service is stub |
| R-04 | Image generation (2+ models) | ⚠️ PARTIAL | Mock mode; JSON decode bug in real mode |
| R-05 | Video generation (1 model) | ⚠️ PARTIAL | Mock mode; same decode bug |
| R-06 | Community feed | ⚠️ PARTIAL | Mock data; no ranking algorithm |
| R-07 | Voting system (hearts) | ⚠️ PARTIAL | Hearts tracked but never consumed |
| R-08 | Competition Subs (6) | ✅ MOSTLY | Wrong voting window on Viral Short Video |
| R-09 | Submit to competition | ⚠️ PARTIAL | Entry created with blank fields |
| R-10 | Leaderboard per Sub | ⚠️ PARTIAL | Mock data only; logic correct |
| R-11 | Share with watermark + deep link | ⚠️ PARTIAL | Watermark renders; deep link absent |
| R-12 | Daily free credits | ✅ MOSTLY | Dual-flag desync risk |
| R-13 | Prompt safety layer | ⚠️ PARTIAL | Server check bypassed in mock mode |
| R-14 | Content report button | ⚠️ PARTIAL | Local only; no auto-hide; no server |

**Fully supported (no blocking gaps): 0 of 14**  
**Mostly supported (minor issues): 2 of 14** (R-08, R-12)  
**Partially supported (functional gaps): 10 of 14**  
**Not supported (stubs): 2 of 14** (R-01, R-03)

---

## Swift 6 Concurrency Compliance

| File | `@MainActor`? | `@Observable`? | Issues |
|---|---|---|---|
| AppState.swift | ✅ | ✅ | Copy-then-overwrite pattern hazardous across suspension points |
| AuthService.swift | ✅ | ✅ | `resetDailyStateIfNeeded()` unnecessarily `async` |
| CreditService.swift | ✅ | ✅ | Non-atomic read-modify-write across `await` (theoretical, safe on `@MainActor`) |
| GenerationService.swift | ✅ | ✅ | `NetworkClient.shared` (actor) called correctly from `@MainActor`; no isolation issues |
| FeedService.swift | ✅ | ✅ | No issues |
| CompetitionService.swift | ✅ | ✅ | No issues |
| AdService.swift | ✅ | ✅ | Unretained `Task` handle from `showRewardedAd()` |
| ReportService.swift | ✅ | ✅ | No issues |
| NetworkClient.swift | actor | N/A | `URLSession` is `Sendable`; no issues |
| WatermarkRenderer.swift | enum (static) | N/A | **Potential Swift 6 error**: `UIImage` across actor boundary into `DispatchQueue.global()` |
| PromptFilter.swift | enum (static) | N/A | No concurrency; no issues |
| Extensions.swift | N/A | N/A | No actor isolation issues; `UIApplication` access in `hideKeyboard()` is `@MainActor` in iOS 17+ |

**Overall Swift 6 verdict:** The architecture is correctly structured (`@MainActor @Observable` pattern used consistently across all service classes). Two issues need attention: (1) the `UIImage`/`WatermarkRenderer` actor boundary crossing, and (2) the copy-then-overwrite pattern in `AppState.collectDailyCredits()` which, while safe under `@MainActor`, is an anti-pattern that could introduce bugs if actor isolation changes.

---

## Top Priority Fixes Before Any Production Traffic

1. **Implement real Apple Sign-In** (`AuthService.swift`) — R-01 is completely blocked.
2. **Integrate AppLovin MAX SDK** (`AdService.swift`) — R-03 is completely blocked; ads are the entire revenue model.
3. **Fix JSON key decoding strategy** (`GenerationService.swift`, `NetworkClient.swift`) — real mode will silently fail to decode every API response.
4. **Wire up Firestore** for credits, feed, votes, competition entries, and reports — current client-side storage is insecure and single-device only.
5. **Decouple heart accounting from voting actions** — add `heartsRemaining` decrement to `FeedService.voteForGeneration()` and `CompetitionService.voteForEntry()`.
6. **Fix `CompetitionService.submitEntry()`** to resolve `mediaURL`, `prompt`, and `model` from `GenerationService` before creating the entry.
7. **Fix `Constants.swift`** — `Viral Short Video` `votingWindowHours` should be `48`, not `24`.
8. **Add auth header to `NetworkClient`** — all production API calls will fail without a valid token.
9. **Fix `WatermarkRenderer` Swift 6 compatibility** — replace `UIGraphicsBeginImageContextWithOptions` with `UIGraphicsImageRenderer` and resolve `UIImage` actor boundary issue.
10. **Consolidate daily state tracking** — unify the `dailyFreeCreditsCollected` and `adWatchesToday` flags between `AuthService` and `CreditService` to prevent split-brain desync.
