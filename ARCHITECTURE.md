# AdForge Architecture Spec — Shared Interfaces

This file defines ALL shared types, protocols, constants, and patterns used across the codebase. Every Swift file must conform to these definitions exactly.

## Swift Conventions
- Swift 6, strict concurrency
- @MainActor on all Observable classes
- @Observable macro (NOT ObservableObject/Published)
- async/await for all async work
- No Combine (use async sequences where needed)
- iOS 17+ minimum (use latest SwiftUI APIs)

## Design Tokens (Constants.swift)

```swift
enum Design {
    // Colors
    static let accent = Color(hex: "#7C3AED")       // Vibrant purple
    static let accentLight = Color(hex: "#A78BFA")
    static let background = Color(hex: "#0F0F0F")    // Near-black
    static let surface = Color(hex: "#1A1A2E")       // Card backgrounds
    static let surfaceLight = Color(hex: "#25253D")   // Elevated surfaces
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#9CA3AF")
    static let success = Color(hex: "#10B981")
    static let warning = Color(hex: "#F59E0B")
    static let error = Color(hex: "#EF4444")
    static let heart = Color(hex: "#EC4899")          // Pink for votes
    static let credit = Color(hex: "#FBBF24")         // Gold for credits
    
    // Typography
    static let titleFont: Font = .system(size: 28, weight: .bold, design: .rounded)
    static let headlineFont: Font = .system(size: 20, weight: .semibold, design: .rounded)
    static let bodyFont: Font = .system(size: 16, weight: .regular)
    static let captionFont: Font = .system(size: 13, weight: .medium)
    static let badgeFont: Font = .system(size: 11, weight: .bold)
    
    // Spacing
    static let paddingSM: CGFloat = 8
    static let paddingMD: CGFloat = 16
    static let paddingLG: CGFloat = 24
    static let paddingXL: CGFloat = 32
    static let cornerRadius: CGFloat = 16
    static let cornerRadiusSM: CGFloat = 10
    static let cornerRadiusXL: CGFloat = 24
}

enum CreditCost {
    static let fluxPro = 300
    static let fluxDev = 200
    static let wan25 = 1000
    static let kling25 = 800
    static let dailyFree = 500
    static let perAdWatch = 1000
    static let maxAdWatchesPerDay = 30
}

enum API {
    static let baseURL = "https://adforge-api.vercel.app"   // Vercel backend
    static let generateImage = "/api/generate-image"
    static let generateVideo = "/api/generate-video"
    static let checkPrompt = "/api/check-prompt"
}
```

## Data Models

### User
```swift
struct AFUser: Codable, Identifiable, Sendable {
    let id: String                    // Firebase Auth UID
    var displayName: String
    var avatarURL: String?
    var credits: Int
    var totalGenerations: Int
    var totalVotesReceived: Int
    var totalWins: Int
    var level: Int
    var xp: Int
    var currentStreak: Int
    var lastActiveDate: Date?
    var badges: [Badge]
    var joinedDate: Date
    var dailyFreeCreditsCollected: Bool
    var adWatchesToday: Int
    var heartsRemaining: Int          // Daily vote allowance
    var heartsLastRefill: Date?
}
```

### Generation
```swift
enum GenerationType: String, Codable, CaseIterable, Sendable {
    case image
    case video
}

enum AIModel: String, Codable, CaseIterable, Identifiable, Sendable {
    case fluxPro = "flux-2-pro"
    case fluxDev = "flux-2-dev"
    case wan25 = "wan-2.5"
    
    var id: String { rawValue }
    var displayName: String { ... }
    var type: GenerationType { ... }
    var creditCost: Int { ... }
    var description: String { ... }
    var estimatedTime: String { ... }  // "~10s", "~45s"
}

struct Generation: Codable, Identifiable, Sendable {
    let id: String
    let userId: String
    let prompt: String
    let model: AIModel
    let type: GenerationType
    let mediaURL: String              // Cloudinary URL
    let thumbnailURL: String?
    var voteCount: Int
    var isSubmittedToSub: Bool
    var subId: String?
    let createdAt: Date
    let creditCost: Int
}
```

### Competition / Sub
```swift
struct Sub: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let description: String
    let iconName: String              // SF Symbol name
    let acceptedTypes: [GenerationType]
    var isActive: Bool
    let votingWindowHours: Int        // 24 or 48
}

struct CompetitionEntry: Codable, Identifiable, Sendable {
    let id: String
    let generationId: String
    let subId: String
    let userId: String
    let userDisplayName: String
    var voteCount: Int
    let submittedAt: Date
    let votingEndsAt: Date
    let mediaURL: String
    let prompt: String
    let model: AIModel
}
```

### Other Models
```swift
struct Badge: Codable, Identifiable, Sendable {
    let id: String
    let name: String                  // "Meme Lord"
    let iconName: String              // SF Symbol
    let description: String
    let earnedAt: Date?
}

struct Vote: Codable, Sendable {
    let id: String
    let userId: String
    let generationId: String
    let createdAt: Date
}

enum ReportCategory: String, Codable, CaseIterable, Sendable {
    case offensive
    case spam
    case deepfake
    case other
}

struct ContentReport: Codable, Sendable {
    let id: String
    let reporterId: String
    let generationId: String
    let category: ReportCategory
    let createdAt: Date
}

struct CreditTransaction: Codable, Identifiable, Sendable {
    let id: String
    let userId: String
    let amount: Int                   // positive = earn, negative = spend
    let reason: CreditReason
    let createdAt: Date
}

enum CreditReason: String, Codable, Sendable {
    case dailyFree
    case adWatch
    case generation
    case competitionWin
    case streakBonus
}
```

## AppState (Observable root)
```swift
@MainActor @Observable
final class AppState {
    var currentUser: AFUser?
    var isAuthenticated: Bool
    var isLoading: Bool
    var selectedTab: AppTab
    var showingAuth: Bool
    var errorMessage: String?
    
    // Services (injected)
    let authService: AuthService
    let creditService: CreditService
    let generationService: GenerationService
    let feedService: FeedService
    let competitionService: CompetitionService
    let adService: AdService
    let reportService: ReportService
}

enum AppTab: Int, CaseIterable {
    case studio = 0
    case feed = 1
    case competitions = 2
    case profile = 3
    
    var title: String { ... }
    var iconName: String { ... }     // SF Symbol
}
```

## Service Classes (All @MainActor @Observable)

### AuthService
```
- signInWithApple() async throws -> AFUser
- signOut()
- checkExistingSession() async -> AFUser?
```

### CreditService
```
- fetchBalance() async -> Int
- spendCredits(amount: Int, reason: CreditReason) async throws
- earnCredits(amount: Int, reason: CreditReason) async
- collectDailyFree() async throws -> Bool
- canWatchAd() -> Bool
- recordAdWatch() async
```

### GenerationService
```
- generateImage(prompt: String, model: AIModel) async throws -> Generation
- generateVideo(prompt: String, model: AIModel) async throws -> Generation
- checkPrompt(prompt: String) async throws -> Bool   // true = safe
```

### FeedService
```
- fetchFeed(page: Int) async throws -> [Generation]
- voteForGeneration(id: String) async throws
- hasVoted(generationId: String) -> Bool
```

### CompetitionService
```
- fetchSubs() async throws -> [Sub]
- fetchEntries(subId: String) async throws -> [CompetitionEntry]
- submitEntry(generationId: String, subId: String) async throws
- fetchLeaderboard(subId: String) async throws -> [CompetitionEntry]
```

### AdService
```
- loadRewardedAd() async
- showRewardedAd() async throws -> Bool    // true = completed
- isAdReady: Bool
```

### ReportService
```
- reportContent(generationId: String, category: ReportCategory) async throws
```

## ViewModels

### StudioViewModel
```
- selectedType: GenerationType
- selectedModel: AIModel
- promptText: String
- isGenerating: Bool
- generationProgress: String?         // Status text during generation
- lastGeneration: Generation?
- availableModels: [AIModel]         // filtered by selectedType
- creditCost: Int                    // computed from selectedModel
- canGenerate: Bool                  // has enough credits
- generate() async
- watchAdAndGenerate() async
```

### FeedViewModel
```
- generations: [Generation]
- isLoading: Bool
- isLoadingMore: Bool
- loadFeed() async
- loadMore() async
- vote(for generation: Generation) async
- report(generation: Generation, category: ReportCategory) async
```

### CompetitionsViewModel
```
- subs: [Sub]
- selectedSub: Sub?
- entries: [CompetitionEntry]
- isLoading: Bool
- loadSubs() async
- loadEntries(for sub: Sub) async
- submitEntry(generationId: String, to sub: Sub) async
- vote(for entry: CompetitionEntry) async
```

### ProfileViewModel
```
- user: AFUser?
- userGenerations: [Generation]
- isLoading: Bool
- loadProfile() async
- loadUserGenerations() async
- signOut()
```

## View Hierarchy

### AdForgeApp.swift
```
@main App {
    WindowGroup {
        if appState.isAuthenticated {
            MainTabView(appState)     // Tab bar with 4 tabs
        } else {
            AuthView(appState)
        }
    }
}
```

### MainTabView
Tab bar with SF Symbol icons:
- Studio: wand.and.stars
- Feed: rectangle.stack.fill
- Competitions: trophy.fill  
- Profile: person.fill

### StudioView
- Top: Credit balance pill (gold coins icon + count)
- Model type selector (Image / Video segmented control)
- Horizontal model carousel (cards with model name, description, credit cost)
- Prompt text input (large, multi-line, placeholder: "Describe what you want to create...")
- "Generate" button (full-width, gradient purple, shows credit cost)
- OR "Watch Ad + Generate" if insufficient credits
- Result: Full-screen overlay with generated image/video, share/submit buttons

### FeedView
- Vertical scroll of FeedCardView items
- Each card: media (image or video player), prompt text, creator name, vote count + heart button, share button, report button (... menu)
- Pull to refresh
- Infinite scroll pagination

### CompetitionsView
- Grid of Sub cards (2 columns)
- Each card: icon, name, active entry count, time remaining
- Tap → SubDetailView with entries list + leaderboard toggle

### ProfileView
- User avatar, display name, level badge
- Stats row: generations | votes received | wins
- Credit balance
- Streak indicator
- Grid of user's creations (3 columns)
- Settings gear icon → sign out

### AuthView
- Dark background with logo
- App name "AdForge" in large text
- Tagline: "Create. Compete. Win."
- "Sign in with Apple" button (native ASAuthorizationAppleIDButton)
- Privacy note: "We only use your Apple ID to create your account."

## Backend API (Vercel Edge Functions, TypeScript)

### POST /api/generate-image
Request: { prompt, model, userId }
- Check prompt against blocklist
- Call Fal.ai with model-specific endpoint
- Return { imageURL, thumbnailURL }

### POST /api/generate-video
Request: { prompt, model, userId }
- Check prompt against blocklist
- Call Fal.ai with Wan 2.5 endpoint
- Return { videoURL, thumbnailURL }

### POST /api/check-prompt
Request: { prompt }
- Check against blocklist
- Return { safe: boolean }

### Blocklist (lib/blocklist.json)
JSON array of blocked terms/phrases. Generic refusal, no explanation.

## File List (what each subagent produces)

### iOS Core (Models + Services + App + Utilities)
1.  AdForge/App/Constants.swift
2.  AdForge/App/AppState.swift  
3.  AdForge/Models/User.swift
4.  AdForge/Models/Generation.swift
5.  AdForge/Models/Competition.swift
6.  AdForge/Models/CreditTransaction.swift
7.  AdForge/Models/Badge.swift
8.  AdForge/Services/NetworkClient.swift
9.  AdForge/Services/AuthService.swift
10. AdForge/Services/CreditService.swift
11. AdForge/Services/GenerationService.swift
12. AdForge/Services/FeedService.swift
13. AdForge/Services/CompetitionService.swift
14. AdForge/Services/AdService.swift
15. AdForge/Services/ReportService.swift
16. AdForge/Utilities/Extensions.swift
17. AdForge/Utilities/PromptFilter.swift
18. AdForge/Utilities/WatermarkRenderer.swift

### iOS UI (Views + ViewModels)
19. AdForge/ViewModels/StudioViewModel.swift
20. AdForge/ViewModels/FeedViewModel.swift
21. AdForge/ViewModels/CompetitionsViewModel.swift
22. AdForge/ViewModels/ProfileViewModel.swift
23. AdForge/Views/Auth/AuthView.swift
24. AdForge/AdForgeApp.swift (includes MainTabView)
25. AdForge/Views/Studio/StudioView.swift
26. AdForge/Views/Studio/ModelPickerView.swift
27. AdForge/Views/Studio/PromptInputView.swift
28. AdForge/Views/Studio/GenerationResultView.swift
29. AdForge/Views/Feed/FeedView.swift
30. AdForge/Views/Feed/FeedCardView.swift
31. AdForge/Views/Competitions/CompetitionsView.swift
32. AdForge/Views/Competitions/SubDetailView.swift
33. AdForge/Views/Competitions/LeaderboardView.swift
34. AdForge/Views/Competitions/SubmitToSubSheet.swift
35. AdForge/Views/Profile/ProfileView.swift
36. AdForge/Views/Components/CreditBalanceView.swift
37. AdForge/Views/Components/WatchAdButton.swift
38. AdForge/Views/Components/ReportSheet.swift
39. AdForge/Views/Components/ShareSheet.swift
40. AdForge/Views/Components/VoteButton.swift

### Backend
41. backend/api/generate-image.ts
42. backend/api/generate-video.ts
43. backend/api/check-prompt.ts
44. backend/lib/blocklist.json
45. backend/lib/fal-client.ts
46. backend/package.json
47. backend/tsconfig.json
48. backend/vercel.json
