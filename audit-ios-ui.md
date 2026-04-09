# AdForge iOS UI Audit

**Audited against:** `ARCHITECTURE.md`
**Scope:** `AdForgeApp.swift`, `ViewModels/` (4 files), `Views/Auth/`, `Views/Studio/` (4 files), `Views/Feed/` (2 files), `Views/Competitions/` (4 files), `Views/Profile/` (1 file), `Views/Components/` (5 files) — **22 files total**

---

## File-by-File Audit

---

### `AdForge/AdForgeApp.swift`

**Status: COMPLETE**

**Issues found:**
1. `AppState.preview` is referenced in `#Preview` — this static property must exist on `AppState`; if the core layer did not define it the preview will fail to compile.
2. `pressEvents(onPress:onRelease:)` modifier and its `PressEventModifier` are defined here. If any other file in the module also defines this extension on `View`, there will be a duplicate-definition error. All four Studio files call `.pressEvents(…)` on their buttons, so the extension defined here needs to be the single canonical source.
3. `TabContentView` is `private`. `SubDetailView` creates its own `CompetitionsViewModel` instance — this is fine architecturally, but the `TabContentView` tab-switching animation uses `.animation(.easeInOut, value: appState.selectedTab)`, which requires `AppTab` to conform to `Equatable`. The spec declares `AppTab: Int, CaseIterable` — `Int` raw value enums are `Equatable` by synthesis, so this is fine.
4. The custom tab bar implements a **glowing purple indicator** (a `Circle()` glow + active dot). The spec says "glowing purple indicator" — this interpretation matches intent.
5. No deep-link or `openURL` handling is wired in. Not required by spec but worth noting.

**Type mismatches / missing references:**
- `AppState.preview` — must exist in core layer (not defined in this file).
- `AppTab.allCases`, `AppTab.iconName` — spec marks `iconName` as `{ ... }` (computed); implementation relies on this being present.

---

### `ViewModels/StudioViewModel.swift`

**Status: COMPLETE**

**Issues found:**
1. `appState.creditService.recordAdWatch()` is called at line 132 — the spec's `CreditService` interface does **not** list `recordAdWatch()`. The spec only lists `canWatchAd()` and the ad-watch count is implicitly part of the service. If `CreditService` does not expose `recordAdWatch()`, this will not compile. **Compile-blocking.**
2. `canGenerateWithAd` and `adsRemainingToday` are extra computed properties not listed in the spec's ViewModel interface. They are used by `StudioView` and `WatchAdButton`, so they must stay consistent. They are not a problem unless the spec is treated as exhaustive. They appear safe.
3. `selectedType` `didSet` calls `availableModels.first ?? .fluxDev`. At Swift 6 strict concurrency, `didSet` on a stored property of an `@Observable @MainActor` class is fine since the class itself is `@MainActor`.
4. `generate()` sets `isGenerating = false` then calls `await generate()` recursively from `watchAdAndGenerate()`. This is intentional (chained generation after ad) but note that at line 133–135, `isGenerating` is set to `false` before `await generate()` is called, meaning `generate()` will re-enter and pass the `!isGenerating` guard. This is correct.
5. `appState.errorMessage` is written from within `generate()` and `watchAdAndGenerate()`. Since `AppState` is `@MainActor` and `StudioViewModel` is `@MainActor`, this is safe.

**Type mismatches / missing references:**
- `appState.creditService.recordAdWatch()` — **not in spec**. Will fail to compile if `CreditService` lacks this method.

---

### `ViewModels/FeedViewModel.swift`

**Status: COMPLETE**

**Issues found:**
1. Spec declares `vote(for generation: Generation) async` — implemented correctly.
2. `report(generation:category:)` calls `appState.reportService.reportContent(…)` — correct per spec.
3. `hasVoted(for:)` is an extra convenience wrapper not in spec but used consistently by `FeedView`. Not a problem.
4. `currentPage` is `var` but not in the spec interface. Fine as internal state.
5. `hasMore` is `private var`. The `loadMore()` guard checks `hasMore` — correct. No issue.

**Type mismatches / missing references:**
- None identified.

---

### `ViewModels/CompetitionsViewModel.swift`

**Status: COMPLETE**

**Issues found:**
1. `leaderboard: [CompetitionEntry]` is an extra property not listed in spec. It is used by `SubDetailView` and `LeaderboardView`. Not a spec mismatch per se, but the spec does define `fetchLeaderboard` on `CompetitionService`, so this is the correct integration.
2. `loadLeaderboard(for sub: Sub)` is an extra method not in spec ViewModel interface. Safe and correct.
3. `vote(for entry: CompetitionEntry)` calls `appState.feedService.voteForGeneration(id: entry.generationId)` — this reuses `FeedService` for competition voting. This is a cross-layer concern: if `CompetitionService` is intended to have its own vote endpoint, this would be wrong. The spec does not define a `CompetitionService.vote` method, so using `FeedService.voteForGeneration` is the only available option. Acceptable.
4. `DefaultSubs.all` is referenced at line 36 as a fallback. This constant must be defined in the core layer (likely `Competition.swift` or a separate constants file). It is **not** in the architecture spec. If missing, this is a compile error. **Potentially compile-blocking.**
5. `dailyChallengesSub` uses `$0.votingWindowHours == 24` to identify daily challenges — a brittle heuristic. Not a compile issue.

**Type mismatches / missing references:**
- `DefaultSubs.all` — not in spec. Must exist in the core layer.

---

### `ViewModels/ProfileViewModel.swift`

**Status: PARTIAL**

**Issues found:**
1. `loadUserGenerations()` fetches from `appState.feedService.fetchFeed(page: 0)` and filters by `userId`. This is **not** the intended approach — a user's own generations should have a dedicated endpoint or service method. As written, it only loads page 0 of the public feed and filters, so a user with no generations in the first page will see an empty grid even if they have creations on later pages. **Functional deficiency.**
2. `loadProfile()` only re-assigns `appState.currentUser` locally — it doesn't hit the network. Comment says "would hit network in real implementation." This is a stub. The spec lists `loadProfile() async` without a network-call requirement but implies a real fetch. **Partial implementation.**
3. No `loadUserGenerations()` guard reset — if called while `isLoading` is already true from `loadProfile()`, the guard on line 36 blocks. This is a minor race condition.

**Type mismatches / missing references:**
- None that will fail to compile, but the filtering approach is architecturally weak.

---

### `Views/Auth/AuthView.swift`

**Status: COMPLETE**

**Issues found:**
1. Two hardcoded `Color(red:green:blue:)` literals inside `FeatureBullet` calls (lines 58–65) — `Color(red: 0.6, green: 0.3, blue: 1.0)` and `Color(red: 0.3, green: 0.7, blue: 1.0)`. These are decorative per-feature accent colors and don't map to any `Design` token. Minor, acceptable.
2. `AnimatedOrb` uses hardcoded `Color(red: 0.49, green: 0.23, blue: 0.93)` (purple) and `Color(red: 0.86, green: 0.27, blue: 0.75)` (pink). These approximate `Design.accent` and `Design.heart` but are not token references. Minor design inconsistency.
3. `orbScale` and `orbOpacity` are declared as `@State` properties in `AuthView` (lines 10–11) but are **never used** — the actual animation state lives inside `AnimatedOrb`. These are dead state variables. Not a compile error, just dead code.
4. `SignInWithAppleButtonView.Coordinator.handleTap` is `@objc`. The `Coordinator` class does not inherit from `NSObject`. This **will not compile** — `@objc` requires the class or one of its superclasses to be an Objective-C class. **Compile-blocking.**
5. `AuthView` calls `appState.authService.signInWithApple()` directly but never updates `appState.isAuthenticated` — this is expected to happen inside `authService.signInWithApple()` or in `AppState` itself. If the core layer does not set `appState.isAuthenticated = true` on sign-in, the view will never transition. This is a cross-layer concern.
6. `#Preview` uses `AppState.preview` — same dependency as noted in `AdForgeApp.swift`.

**Type mismatches / missing references:**
- `Coordinator` must inherit `NSObject` for `@objc func handleTap()` to compile. **Compile-blocking.**
- `AppState.preview` must be defined in core layer.

---

### `Views/Studio/StudioView.swift`

**Status: COMPLETE**

**Issues found:**
1. `TypeSegmentedPicker` uses `GenerationType.allCases` — requires `GenerationType: CaseIterable`. Spec declares it as such; correct.
2. `CreditCostBadge` uses `Text` concatenation with `+` operator mixing `.foregroundStyle` — this is valid in SwiftUI 17+ using `AttributedString`-style text. Correct.
3. `GenerateButton` hardcodes `Color(red: 0.58, green: 0.19, blue: 0.82)` as the end color of the gradient. This is a close approximation of `Design.accent` darkened. Not using a token. Minor.
4. `StudioView` uses `@Bindable var appState: AppState` which requires `AppState` to conform to `Observable`. Spec confirms this. Correct.
5. `viewModel.showingResult` is bound with `$viewModel.showingResult` — for `@Observable` classes stored as `@State`, binding to properties requires `@Bindable`. The pattern `@State private var viewModel: StudioViewModel` + `$viewModel.showingResult` only works because `viewModel` is a reference type stored in a `@State` wrapper, allowing `@Bindable` extraction. This compiles but requires iOS 17+. Correct.
6. `WatchAdButton` is shown when `!viewModel.canGenerate && !promptText.isEmpty`. The `adsRemainingToday` property access on `viewModel` is valid (extra computed property defined in `StudioViewModel`). Correct.
7. The "credit cost" display uses `CreditCostBadge` inline in the scroll view — spec says "shows credit cost" on the Generate button, which this file also does. Both are present. Correct.

**Type mismatches / missing references:**
- `viewModel.adsRemainingToday` — extra property, must exist in `StudioViewModel` (it does). Fine.
- `$viewModel.selectedType`, `$viewModel.selectedModel`, `$viewModel.promptText`, `$viewModel.showingResult` — all valid for `@Observable` via `@Bindable` extraction from `@State`.

---

### `Views/Studio/ModelPickerView.swift`

**Status: COMPLETE**

**Issues found:**
1. `AIModel` extension defining `var iconName: String` is declared here. If a separate file (e.g., in the core layer) also defines `iconName` on `AIModel`, this will cause a **duplicate extension conflict**. The spec does **not** list `iconName` in the `AIModel` definition, so it is a UI-layer addition. As long as the core layer doesn't also add it, this is fine. **Potential compile conflict.**
2. `ModelCard` calls `.pressEvents(onPress:onRelease:)` — this extension is defined in `AdForgeApp.swift`. As long as both files are in the same module, this resolves correctly. No issue.
3. `AIModel.allCases.filter { $0.type == .image }` in the preview — requires `AIModel.type` to exist. Spec defines it as a computed property. Correct.

**Type mismatches / missing references:**
- `model.iconName` — added by extension in this file. No conflict expected unless core layer also defines it.
- `model.displayName`, `model.description`, `model.estimatedTime`, `model.creditCost` — all required by spec (`{ ... }` computed properties). Must exist in core layer. Correct per spec.

---

### `Views/Studio/PromptInputView.swift`

**Status: COMPLETE**

**Issues found:**
1. No issues found. All tokens used. Placeholder text matches spec ("Describe what you want to create..."). Character counter, suggestion chips all implemented cleanly.
2. `.pressEvents(onPress:onRelease:)` used on `SuggestionChip` — correct, defined in `AdForgeApp.swift`.
3. `onChange(of: promptText)` uses two-argument form `{ _, newValue in }` — correct Swift 6 / iOS 17 API.

**Type mismatches / missing references:**
- None.

---

### `Views/Studio/GenerationResultView.swift`

**Status: COMPLETE**

**Issues found:**
1. `VideoPlayerView` creates `AVPlayer(url: url)` inline in a `let` constant inside `body`. In SwiftUI, creating an `AVPlayer` in `body` is problematic — `body` is called repeatedly and each call creates a new player, immediately deallocating the previous one. **The video will not play reliably.** Should be `@State private var player: AVPlayer?`. **Functional bug.**
2. `saveToPhotos()` calls `UIImageWriteToSavedPhotosAlbum` without requesting `NSPhotoLibraryAddUsageDescription` permission first. On iOS 14+, `UIImageWriteToSavedPhotosAlbum` triggers the permission dialog automatically, but the Info.plist key must be present. This is outside the UI layer but worth flagging.
3. `saveToPhotos()` only handles `type == .image`. For videos, the function does nothing (`saveSuccess` still animates to `true`). The "Save" button will appear to succeed for videos but won't actually save. **Functional bug for video generation type.**
4. `ShareSheet` is used with `items: [generation.mediaURL, ...]` where `mediaURL` is a `String`. The `UIActivityViewController` will share the raw URL string, not the actual media. For images, this would ideally pass a `URL` or `UIImage`. Minor UX issue.
5. `ShimmerPlaceholder` is defined in this file. If used elsewhere (it is referenced from `FeedCardView.swift` line 121), this causes a **cross-file dependency** on a type in `GenerationResultView.swift`. In the same module this compiles fine, but it's poor encapsulation. `ShimmerPlaceholder` should be in `Components/`.
6. `Generation.mock` referenced in `#Preview` — must exist in core layer.
7. `ActionButton.pressEvents(…)` — correct.

**Type mismatches / missing references:**
- `Generation.mock` — must exist in core layer.
- `ShimmerPlaceholder` — defined here, used in `FeedCardView`. Same module, compiles fine. Encapsulation issue only.

---

### `Views/Feed/FeedView.swift`

**Status: COMPLETE**

**Issues found:**
1. No skeleton loading is shown when `isLoading && !generations.isEmpty` (i.e., during pull-to-refresh after initial load). The skeleton (`LoadingFeedView`) only shows when the list is empty. During pull-to-refresh the old list stays visible, which is acceptable UX.
2. Infinite scroll trigger is `.onAppear` on the last item — a standard pattern. Correct.
3. `viewModel.hasVoted(for: generation)` is an extra method not in spec — defined correctly in `FeedViewModel`. Fine.
4. The `FeedCardSkeleton` shimmer uses `GeometryReader` which can cause layout issues inside `VStack`. Minor layout risk.

**Type mismatches / missing references:**
- None.

---

### `Views/Feed/FeedCardView.swift`

**Status: COMPLETE**

**Issues found:**
1. `CreatorHeaderView` hardcodes `Text("Creator")` (line 94) instead of a real `displayName`. The comment acknowledges this: "Would use displayName from joined user data." The `Generation` model has `userId` but no `userDisplayName` field. The spec's `Generation` struct does not include a `userDisplayName` property — only `userId`. This is a known data model gap. The creator name will always show "Creator" in the feed. **Functional gap vs. spec intent.**
2. `ShimmerPlaceholder` is used here (line 121) but is defined in `GenerationResultView.swift`. This compiles within the same module but is an encapsulation issue.
3. `Date.timeAgoDisplay` extension is defined here. If another file also defines this extension (no other file in scope does), there would be a conflict. Fine as-is.
4. `AFUser.mock` is referenced in `#Preview` — must exist in core layer.
5. `BottomBarView.onReport` takes `() -> Void` — the report action here just shows the sheet, and the sheet calls `onReport(category)`. Correct delegation.
6. `MediaView` shows video thumbnail but does not play the video inline (intentional — tapping would need to navigate). Spec says "video player" on cards — this shows a thumbnail with a play icon overlay, not an actual `AVPlayer`. This is a deliberate choice for performance in a feed. **Mild spec gap** (spec says "video player" but an inline thumbnail is acceptable UX).

**Type mismatches / missing references:**
- `Generation.mock` — must exist in core layer.
- `AFUser.mock` — must exist in core layer.
- `ShimmerPlaceholder` — defined in `GenerationResultView.swift`. Accessible within module.

---

### `Views/Competitions/CompetitionsView.swift`

**Status: COMPLETE**

**Issues found:**
1. `Sub` must conform to `Hashable` for use in `NavigationLink(value: sub)`. The spec declares `Sub: Codable, Identifiable, Sendable` but does **not** include `Hashable`. `NavigationLink(value:)` requires the value type to be `Hashable`. **Compile-blocking unless `Sub` conforms to `Hashable` in the core layer.**
2. `SubCard` shows a hardcoded `"Live"` badge (line 212) instead of an actual entry count. The spec says "active entry count" on the card. This is a **spec gap** — there's no `entryCount` field on `Sub`, and the VM doesn't provide it here.
3. `DailyChallengeCard` is not itself a `NavigationLink` — it has no tap action. Users see the daily challenge spotlight but can't tap it to navigate to `SubDetailView`. **Functional gap** — the daily challenge card should be tappable.
4. `TimeBadge` shows `votingWindowHours` as a static label (e.g., "24h") rather than a countdown. The spec says "time remaining" — this always shows the window duration, not how much time is left. **Spec gap** (no deadline timestamp available on `Sub`).
5. `DefaultSubs.all` referenced in `CompetitionsViewModel` fallback — not in this file directly, but affects this view.
6. `Sub.self` used in `.navigationDestination(for: Sub.self)` — requires `Hashable`. See issue 1.

**Type mismatches / missing references:**
- `Sub` must be `Hashable` for `NavigationLink(value:)` — **compile-blocking if not declared in core layer.**

---

### `Views/Competitions/SubDetailView.swift`

**Status: COMPLETE**

**Issues found:**
1. `SubDetailView` creates a **new** `CompetitionsViewModel` instance (line 22) instead of sharing the one already created in `CompetitionsView`. This means `subs` list is re-fetched unnecessarily, and any state from the parent is lost. This is an architectural choice — acceptable for isolation but slightly wasteful. Not a compile issue.
2. `SubmitToSubSheet` is called with `generationId: nil` (line 101). This is intentional — the sheet lets the user pick a generation. The sheet handles `nil` correctly. Fine.
3. `SubmitToSubSheet` takes an `onSubmit: ((String) -> Void)?` parameter. The call site passes `onSubmit: { generationId in Task { await viewModel.submitEntry(…) } }` — this creates a `Task` inside a non-async closure, which is correct.
4. `DefaultSubs.all[0]` used in `#Preview` — requires `DefaultSubs.all` to have at least one element. **Potentially runtime crash** if empty, though not a compile issue.
5. `EntryCard` shows `hasVoted: false` hardcoded (line 277). There's no `hasVoted` check for competition entries — the `CompetitionsViewModel` doesn't expose an equivalent of `FeedViewModel.hasVoted(for:)`. Users can vote multiple times on the same competition entry. **Functional bug.**

**Type mismatches / missing references:**
- `DefaultSubs.all` — not in spec. Must exist in core layer.
- `DefaultSubs.all[0]` in preview — array must not be empty.

---

### `Views/Competitions/LeaderboardView.swift`

**Status: COMPLETE**

**Issues found:**
1. `PodiumView` renders 2nd place on the left and 1st in the center — the classic podium layout. Correct.
2. `CompetitionEntry.mocks` referenced in `#Preview` — must exist in core layer. **Potentially compile-blocking if absent.**
3. `medalIcon` uses `"medal.fill"` for both 2nd and 3rd place. As of iOS 17, `medal.fill` exists in SF Symbols. Correct.
4. No animation on the podium (e.g., no staggered entry). This is an omission vs. a rich UX but not a spec requirement.

**Type mismatches / missing references:**
- `CompetitionEntry.mocks` — must exist in core layer.

---

### `Views/Competitions/SubmitToSubSheet.swift`

**Status: COMPLETE**

**Issues found:**
1. `ShapeStyle` extension at lines 382–392 defines `eraseToAnyShapeStyle()`. The instance method `func eraseToAnyShapeStyle() -> AnyShapeStyle` at line 388 is a **duplicate of the protocol extension** above it. The static method at line 383 (`static func eraseToAnyShapeStyle<S>`) extends `ShapeStyle where Self == AnyShapeStyle`, which is a more constrained overload. These two together are odd but won't cause a compile error — the instance method will always be preferred. However, this is unnecessarily complex. The simpler pattern is just `AnyShapeStyle(myStyle)`.
2. `ConfirmButton` background uses `.eraseToAnyShapeStyle()` to cast either a `LinearGradient` or `Color` (actually `Design.surfaceLight` which is a `Color`) to `AnyShapeStyle`. The `background(_:)` modifier accepting `ShapeStyle` doesn't require erasure in iOS 17 — `.background(canSubmit ? LinearGradient(...) : Design.surfaceLight)` won't compile due to type mismatch in ternary, so the erasure approach is the correct workaround. The implementation is valid.
3. `availableSubs` is initialized to `DefaultSubs.all` (line 16). Same dependency on `DefaultSubs`.
4. `loadRecentGenerations()` has the same limitation as `ProfileViewModel` — it fetches page 0 of the global feed and filters by userId. Only the user's generations on page 0 will appear.
5. `SelectedGenerationConfirmation` shows only the first 16 chars of the ID — purely informational. Fine.

**Type mismatches / missing references:**
- `DefaultSubs.all` — not in spec. Must exist in core layer.

---

### `Views/Profile/ProfileView.swift`

**Status: COMPLETE**

**Issues found:**
1. `CreditBalanceLargeView` (defined locally in this file) is a **duplicate of concept** — `CreditBalanceView` in `Components/` is the canonical pill component. The profile has its own expanded version. Not a problem but worth noting.
2. `XPBar` uses hardcoded `xpPerLevel = 1000` (line 211). This magic number is not in the spec's `AFUser` model or `Constants.swift`. If the actual XP-per-level calculation is different, the bar will be wrong. Minor.
3. `StreakView` uses a fire emoji (`🔥`) in a hardcoded string (line 358) — `"Keep it going! 🔥"`. The spec says no emojis (design guideline), and this is user-facing text. Minor.
4. `ProfileViewModel.loadUserGenerations()` fetches only page 0 (see ViewModel audit). The `CreationThumbnail` grid will only show the user's items from page 0 of the global feed.
5. `ProfileHeaderView` gracefully handles `nil` user. Correct.
6. `LevelBadge` and `XPBar` are implemented — not in spec but add meaningful context. Fine.
7. `Divider()` in `StatsRow` is used as a vertical divider but SwiftUI's `Divider()` is horizontal by default. Setting `.frame(height: 40)` limits its height, making it appear as a short horizontal rule, not a vertical separator. This is a **layout bug** — to get a vertical divider between stats, `.frame(width: 1, height: 40)` is needed, or use `Rectangle()`. **Visual bug.**

**Type mismatches / missing references:**
- None that will fail to compile.

---

### `Views/Components/CreditBalanceView.swift`

**Status: COMPLETE**

**Issues found:**
1. `DispatchQueue.main.asyncAfter` at line 43 — using `DispatchQueue` instead of `Task.sleep` is fine in an `@MainActor` context for UI animations but is not the Swift 6 idiomatic approach. Not a compile issue, but could produce a warning depending on concurrency settings.
2. `contentTransition(.numericText(countsDown:))` — correct iOS 17 API. Fine.
3. Animation on credit change is well-implemented with `displayedCredits` mirroring + pulse.

**Type mismatches / missing references:**
- None.

---

### `Views/Components/WatchAdButton.swift`

**Status: COMPLETE**

**Issues found:**
1. `gradientAngle` is declared as `@State private var gradientAngle: Double = 0` (line 11) but is **never used** anywhere in the view body. Dead state variable. Minor.
2. The button's gradient uses hardcoded green colors `Color(red: 0.05, green: 0.72, blue: 0.56)` — not a `Design` token. Intentional (the ad button is styled distinctly from the purple theme). Acceptable.
3. `pressEvents(onPress:onRelease:)` used — correct.

**Type mismatches / missing references:**
- None.

---

### `Views/Components/ReportSheet.swift`

**Status: COMPLETE**

**Issues found:**
1. `ReportSheet` receives `onReport: (ReportCategory) -> Void` and calls it synchronously. The `FeedViewModel.report(generation:category:)` is `async`. The sheet passes the category back to `FeedCardView`'s closure, which wraps it in `Task { await viewModel.report(…) }`. This async handoff is correct.
2. `isSubmitting` is set to `true` but the dismiss happens via `DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)` — not Swift 6 idiomatic (`Task.sleep` preferred). Minor.
3. All `Design` tokens used correctly. Clean.
4. `.presentationDetents([.medium, .large])` — correct iOS 16+ API. Fine.

**Type mismatches / missing references:**
- None.

---

### `Views/Components/ShareSheet.swift`

**Status: COMPLETE**

**Issues found:**
1. `ShareSheet` wraps `UIActivityViewController`. This is correct for iOS. No watermark is applied to shared media. The spec states "Share sheet with watermark" as a requirement. The watermark rendering is supposed to be handled by `WatermarkRenderer.swift` (core layer file #18), but `ShareSheet` here passes the raw `mediaURL` string — **no watermark is applied**. This is a **spec gap**. The share flow should fetch the image, apply a watermark via `WatermarkRenderer`, then pass the watermarked `UIImage` to the share sheet.
2. The convenience initializer `init(mediaURLString:caption:generationId:)` shares `mediaURLString` as a plain `String`. `UIActivityViewController` will share the URL text, not the actual downloaded image. This is a UX issue.
3. Preview compiles fine with static data.

**Type mismatches / missing references:**
- `WatermarkRenderer` — referenced in spec file list (#18) but not called from `ShareSheet`. **Missing watermark integration.**

---

### `Views/Components/VoteButton.swift`

**Status: COMPLETE**

**Issues found:**
1. `Int.compactFormatted` extension defined here. If any other file defines the same extension on `Int`, there will be a duplicate. No other file in scope does. Fine.
2. The particle burst animation uses `DispatchQueue.main.asyncAfter` at line 72 — not Swift 6 idiomatic. Minor.
3. `hasVoted` is passed in but there is no server-state check inside the button itself — the caller is responsible for providing the correct `hasVoted` value. In `EntryCard` (`SubDetailView.swift` line 277), `hasVoted: false` is hardcoded. This means the vote button in competition entries never reflects a voted state. **Functional issue** (traced to `SubDetailView`, not `VoteButton` itself).
4. Animation sequence uses sequential `withAnimation` calls — the `.delay` chains are correct.

**Type mismatches / missing references:**
- None.

---

## Cross-Layer Compatibility Issues

The following items reference types, properties, or methods that may not exist or may differ in the core layer:

| # | Location | Reference | Issue |
|---|----------|-----------|-------|
| 1 | `StudioViewModel.watchAdAndGenerate()` | `appState.creditService.recordAdWatch()` | `recordAdWatch()` is **not** in the `CreditService` spec. Only `canWatchAd()` and `recordAdWatch` is absent. **Compile-blocking.** |
| 2 | `AuthView.SignInWithAppleButtonView.Coordinator` | `@objc func handleTap()` | `Coordinator` does not inherit `NSObject`. `@objc` requires an `NSObject` subclass. **Compile-blocking.** |
| 3 | `CompetitionsView`, `SubDetailView`, `SubmitToSubSheet` | `DefaultSubs.all` | `DefaultSubs` is not in the architecture spec. Must be defined in the core layer (likely `Competition.swift`). **Compile-blocking if absent.** |
| 4 | `CompetitionsView` | `NavigationLink(value: sub)` and `.navigationDestination(for: Sub.self)` | Requires `Sub: Hashable`. Spec declares `Sub: Codable, Identifiable, Sendable` — **no `Hashable`**. **Compile-blocking.** |
| 5 | All `#Preview` blocks (10 files) | `AppState.preview` | Static property must exist on `AppState`. Not in spec. **Compile-blocking in all previews if absent.** |
| 6 | `GenerationResultView #Preview` | `Generation.mock` | Static mock property must exist on `Generation`. Not in spec. **Compile-blocking in preview.** |
| 7 | `FeedCardView #Preview` | `AFUser.mock` | Static mock property must exist on `AFUser`. Not in spec. **Compile-blocking in preview.** |
| 8 | `LeaderboardView #Preview` | `CompetitionEntry.mocks` | Array of mocks must exist on `CompetitionEntry`. Not in spec. **Compile-blocking in preview.** |
| 9 | `ModelPickerView` | `AIModel.iconName` (extension added here) | Spec does not define `iconName` on `AIModel`. If core layer also adds it, duplicate extension. **Potential compile conflict.** |
| 10 | `GenerationResultView` (line 252) in `ModelBadge` | `model.iconName` | References the extension defined in `ModelPickerView.swift`. Both files must be compiled in same module (they are). Fine as long as no duplicate exists. |
| 11 | `ProfileViewModel.loadUserGenerations()` | `appState.feedService.fetchFeed(page: 0)` | Using `FeedService` to get user-specific generations is architecturally incorrect. `FeedService` is a public feed, not a user profile service. The `Generation` model has `userId` for filtering but relying on page 0 is brittle. |
| 12 | `CompetitionsViewModel.vote(for:)` | `appState.feedService.voteForGeneration(id:)` | Uses `FeedService` to vote on competition entries. No `CompetitionService` vote method is in spec, so this is the only option — but semantically it conflates feed votes and competition votes. |
| 13 | `ShareSheet` | `WatermarkRenderer` (spec file #18) | Spec requires watermarked sharing. `WatermarkRenderer` exists in the file list but is never called from `ShareSheet`. Integration missing. |
| 14 | `StudioViewModel.canGenerate` | `user.credits >= creditCost` | Accesses `AFUser.credits` — this is a direct property read. Correct per spec. Fine. |
| 15 | `FeedViewModel.vote(for:)` | `user.heartsRemaining > 0` | Accesses `AFUser.heartsRemaining` — correct per spec. Fine. |

---

## UI Completeness Checklist

From the architecture spec, each view requirement:

- [x] **Custom tab bar with glowing purple indicator** — Implemented in `AdForgeApp.swift`. Uses a `Circle()` glow blur + accent dot. Matches spec intent. ✅
- [x] **Auth view with animated gradient orb** — `AnimatedOrb` in `AuthView.swift` uses pulsing scale + rotation. ✅
- [x] **Studio: type picker, model carousel, prompt input, cost preview, generate button** — All present in `StudioView.swift` + sub-files. ✅
- [x] **Studio: loading overlay during generation** — `GeneratingOverlay` with pulsing rings and sparkle rotation. ✅
- [x] **Generation result sheet with save/share/submit** — `GenerationResultView` with three `ActionButton`s. ✅ (save has video bug; share lacks watermark)
- [x] **Feed: infinite scroll, pull to refresh, skeleton loading** — All present in `FeedView.swift`. ✅
- [x] **Feed cards: avatar, media, vote button, share, report** — `FeedCardView` with `CreatorHeaderView`, `MediaView`, `BottomBarView`. ✅ (avatar shows initial only, not real avatar image)
- [x] **Competitions: Sub grid, daily challenge spotlight** — `CompetitionsView` with 2-col `LazyVGrid` and `DailyChallengeCard`. ✅ (daily challenge card not tappable — see issue)
- [x] **Sub detail: entries/leaderboard toggle** — `SubDetailView` with `DetailTabPicker` and conditional view. ✅
- [x] **Leaderboard: podium for top 3** — `LeaderboardView` with `PodiumView` and `PodiumBlock`. ✅
- [x] **Submit to Sub sheet** — `SubmitToSubSheet` with generation picker + sub picker. ✅
- [x] **Profile: avatar, stats, credits, streak, creation grid** — `ProfileView` with all sections. ✅ (stats row divider is horizontal, not vertical — visual bug)
- [x] **Credit balance pill component** — `CreditBalanceView` in `Components/`. ✅
- [x] **Watch ad button** — `WatchAdButton` in `Components/`. ✅
- [x] **Report sheet** — `ReportSheet` with categories and optional text. ✅
- [x] **Share sheet with watermark** — `ShareSheet` implemented. ❌ **Watermark NOT applied** — `WatermarkRenderer` is never called.
- [x] **Vote button with animation** — `VoteButton` with bounce scale + particle burst. ✅

---

## Summary

### Total files audited: 22

---

### Compile-blocking issues (5 confirmed, 4 conditional)

**Confirmed — will not compile:**

1. **`AuthView.swift` line 276** — `Coordinator` uses `@objc func handleTap()` without inheriting from `NSObject`. Fix: `class Coordinator: NSObject { ... }`.
2. **`StudioViewModel.swift` line 132** — `appState.creditService.recordAdWatch()` is not in the `CreditService` spec. If the core layer does not implement this method, the call will fail. Fix: add `recordAdWatch() async` to `CreditService`, or replace with `earnCredits` + a manual write to `adWatchesToday`.
3. **`CompetitionsView.swift`** — `NavigationLink(value: sub)` requires `Sub: Hashable`. The spec declares `Sub: Codable, Identifiable, Sendable` only. Fix: add `Hashable` conformance to `Sub` in core layer.
4. **`CompetitionsViewModel.swift` / `SubmitToSubSheet.swift`** — `DefaultSubs.all` is referenced but not in the spec. Must be defined in the core layer.

**Conditional — compile-blocking only if mock/preview properties are absent (will break all Xcode previews):**

5. `AppState.preview` — referenced in 10 `#Preview` blocks.
6. `Generation.mock` — referenced in `GenerationResultView` and `FeedCardView` previews.
7. `AFUser.mock` — referenced in `FeedCardView` preview.
8. `CompetitionEntry.mocks` — referenced in `LeaderboardView` preview.

---

### Functional / UI bugs (non-compile)

1. **Video player re-creation on every `body` re-render** (`GenerationResultView.swift`) — `AVPlayer` is created inline; will not play reliably.
2. **Save-to-Photos for video type silently does nothing** (`GenerationResultView.swift`) — `saveToPhotos()` only handles `.image`.
3. **No watermark applied to shared media** (`ShareSheet.swift`) — `WatermarkRenderer` never called. Spec requires watermark on shared content.
4. **Daily challenge card not tappable** (`CompetitionsView.swift`) — `DailyChallengeCard` has no `NavigationLink` or `.onTapGesture`.
5. **Competition entry vote button always shows `hasVoted: false`** (`SubDetailView.swift` line 277) — users can re-vote indefinitely.
6. **Stats row dividers are horizontal** (`ProfileView.swift`) — `Divider()` is horizontal by default; vertical divider needs `Rectangle().frame(width: 1)`.
7. **Creator name hardcoded as "Creator"** (`FeedCardView.swift`) — `Generation` model lacks a `userDisplayName` field.
8. **`loadUserGenerations()` only queries page 0** (`ProfileViewModel.swift`, `SubmitToSubSheet.swift`) — users with many generations will see incomplete results.
9. **`TimeBadge` shows window duration, not time remaining** (`CompetitionsView.swift`) — misleading for the "time remaining" spec requirement.
10. **Dead `@State` variables** — `orbScale`/`orbOpacity` in `AuthView` (lines 10–11); `gradientAngle` in `WatchAdButton` (line 11). Harmless but should be removed.
11. **`DispatchQueue.main.asyncAfter` used instead of `Task.sleep`** — in `CreditBalanceView`, `ReportSheet`, `VoteButton`. Not a compiler error under Swift 6 strict concurrency but generates warnings in strict mode.

---

### Missing features vs. spec

1. **Watermark on share** — `WatermarkRenderer` (core file #18) never integrated into `ShareSheet` or generation result sharing flow.
2. **Real-time countdown on competition cards** — `TimeBadge` shows static window hours; spec says "time remaining."
3. **Sub entry count on Sub cards** — `SubCard` shows "Live" badge instead of actual entry count (no count field on `Sub` model).
4. **Real creator display name in feed** — feed cards need a joined user lookup or the `Generation` model needs a denormalized `userDisplayName`.
5. **Video save to Photos** — only images are saved; videos silently succeed without saving.
6. **User avatar image in feed** — `CreatorHeaderView` shows initial letter only; `AFUser.avatarURL` is never fetched/displayed in the feed context.
7. **Daily collect button** — spec's `CreditService.collectDailyFree()` is never called from any view. No UI exists for collecting daily free credits. (The spec does list `dailyFreeCreditsCollected` on `AFUser` and `collectDailyFree()` on `CreditService`.)
