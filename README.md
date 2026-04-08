# AdForge

**Create. Compete. Win.**

AdForge is a free-to-play iOS app where users watch short rewarded video ads to earn credits, then use those credits to generate AI images, videos, and music. A built-in social layer turns every generation into a community competition.

Watch → Create → Share → Compete → Win

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    iOS Client                        │
│              SwiftUI + Swift 6, iOS 17+              │
│                                                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────────┐│
│  │  Studio   │ │   Feed   │ │  Comps   │ │ Profile ││
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬────┘│
│       │            │            │             │      │
│  ┌────┴────────────┴────────────┴─────────────┴────┐│
│  │              ViewModels (@Observable)            ││
│  └────────────────────┬────────────────────────────┘│
│                       │                              │
│  ┌────────────────────┴────────────────────────────┐│
│  │   Services (Auth, Credits, Gen, Feed, Comps)    ││
│  └────────────────────┬────────────────────────────┘│
└───────────────────────┼──────────────────────────────┘
                        │ HTTPS
┌───────────────────────┼──────────────────────────────┐
│              Vercel Edge Functions                    │
│                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │ /generate-   │  │ /generate-   │  │ /check-    │ │
│  │    image     │  │    video     │  │   prompt   │ │
│  └──────┬───────┘  └──────┬───────┘  └────────────┘ │
│         │                 │                          │
│  ┌──────┴─────────────────┴────────────────────────┐ │
│  │          Prompt Blocklist + Rate Limiter         │ │
│  └──────────────────────┬──────────────────────────┘ │
└─────────────────────────┼────────────────────────────┘
                          │ HTTPS
┌─────────────────────────┼────────────────────────────┐
│                    Fal.ai API                         │
│                                                      │
│     Flux 2 Pro  │  Flux 2 Dev  │  Wan 2.5            │
└──────────────────────────────────────────────────────┘
```

### Tech Stack

| Layer | Technology |
|-------|-----------|
| Client | SwiftUI + Swift 6, iOS 17+ |
| Auth | Firebase Auth (Apple Sign-In) |
| Database | Firestore |
| Media Storage | Cloudinary (30-day TTL) |
| AI Backend | Vercel Edge Functions → Fal.ai |
| Ad SDK | AppLovin MAX |
| Analytics | Mixpanel |

---

## Project Structure

```
AdForge/
├── AdForge/
│   ├── AdForgeApp.swift              # @main entry + MainTabView
│   ├── AdForge.entitlements
│   ├── App/
│   │   ├── AppState.swift            # Global observable state
│   │   └── Constants.swift           # Design tokens, credit costs, API endpoints
│   ├── Models/
│   │   ├── User.swift                # AFUser
│   │   ├── Generation.swift          # Generation + AIModel + GenerationType
│   │   ├── Competition.swift         # Sub + CompetitionEntry
│   │   ├── CreditTransaction.swift   # Credit ledger types
│   │   └── Badge.swift               # Badge definitions
│   ├── Services/
│   │   ├── NetworkClient.swift       # HTTP client actor
│   │   ├── AuthService.swift         # Apple Sign-In
│   │   ├── CreditService.swift       # Credit management
│   │   ├── GenerationService.swift   # Fal.ai proxy calls
│   │   ├── FeedService.swift         # Feed + voting
│   │   ├── CompetitionService.swift  # Subs + competitions
│   │   ├── AdService.swift           # Rewarded ads (AppLovin MAX)
│   │   └── ReportService.swift       # Content reporting
│   ├── ViewModels/
│   │   ├── StudioViewModel.swift
│   │   ├── FeedViewModel.swift
│   │   ├── CompetitionsViewModel.swift
│   │   └── ProfileViewModel.swift
│   ├── Views/
│   │   ├── Auth/
│   │   │   └── AuthView.swift
│   │   ├── Studio/
│   │   │   ├── StudioView.swift
│   │   │   ├── ModelPickerView.swift
│   │   │   ├── PromptInputView.swift
│   │   │   └── GenerationResultView.swift
│   │   ├── Feed/
│   │   │   ├── FeedView.swift
│   │   │   └── FeedCardView.swift
│   │   ├── Competitions/
│   │   │   ├── CompetitionsView.swift
│   │   │   ├── SubDetailView.swift
│   │   │   ├── LeaderboardView.swift
│   │   │   └── SubmitToSubSheet.swift
│   │   ├── Profile/
│   │   │   └── ProfileView.swift
│   │   └── Components/
│   │       ├── CreditBalanceView.swift
│   │       ├── WatchAdButton.swift
│   │       ├── ReportSheet.swift
│   │       ├── ShareSheet.swift
│   │       └── VoteButton.swift
│   └── Utilities/
│       ├── Extensions.swift
│       ├── PromptFilter.swift
│       └── WatermarkRenderer.swift
├── backend/
│   ├── api/
│   │   ├── generate-image.ts
│   │   ├── generate-video.ts
│   │   ├── check-prompt.ts
│   │   └── health.ts
│   ├── lib/
│   │   ├── blocklist.json
│   │   └── fal-client.ts
│   ├── package.json
│   ├── tsconfig.json
│   ├── vercel.json
│   └── .env.example
├── ARCHITECTURE.md
└── README.md
```

---

## Getting Started

### Prerequisites

- Xcode 16+ (Swift 6)
- Apple Developer Account
- Node.js 18+ (for backend)
- Vercel CLI (`npm i -g vercel`)

### iOS App Setup

1. **Create Xcode Project:**
   - Open Xcode → File → New → Project → iOS → App
   - Product Name: `AdForge`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployments: iOS 17.0

2. **Add Source Files:**
   - Drag all files from `AdForge/` into your Xcode project
   - Ensure "Copy items if needed" is checked
   - Add `AdForge.entitlements` to the target

3. **Firebase Setup:**
   - Create a project at [Firebase Console](https://console.firebase.google.com)
   - Add an iOS app with your bundle ID
   - Download `GoogleService-Info.plist` and add to the Xcode project
   - Enable Authentication → Apple Sign-In

4. **Add Dependencies (Swift Package Manager):**
   ```
   https://github.com/firebase/firebase-ios-sdk       (FirebaseAuth, FirebaseFirestore)
   https://github.com/AppLovin/AppLovin-MAX-Swift-Package  (AppLovinSDK)
   https://github.com/mixpanel/mixpanel-swift          (Mixpanel)
   ```

5. **Configure Signing:**
   - Set your Team and Bundle ID
   - Enable "Sign in with Apple" capability
   - Enable "Associated Domains" capability
   - Enable "Push Notifications" capability

6. **Build & Run** on simulator or device (iOS 17+)

### Backend Setup

1. **Install dependencies:**
   ```bash
   cd backend
   npm install
   ```

2. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env and add your Fal.ai API key
   ```

3. **Run locally:**
   ```bash
   npx vercel dev
   ```

4. **Deploy:**
   ```bash
   npx vercel --prod
   ```

5. **Update iOS app:** Set `API.baseURL` in `Constants.swift` to your deployed URL.

---

## MVP Features (P0)

- [x] Apple Sign-In authentication
- [x] Credit system with transparent cost preview
- [x] Rewarded video ad integration
- [x] Image generation (Flux 2 Pro, Flux 2 Dev)
- [x] Video generation (Wan 2.5)
- [x] Community feed with infinite scroll
- [x] Voting system (hearts, 20/day)
- [x] 6 Competition Subs with leaderboards
- [x] Submit to competition flow
- [x] Share to TikTok/Instagram with watermark + deep link
- [x] Daily free credits (500)
- [x] Server-side prompt blocklist
- [x] Content report button

## Phase 2 (Post-Launch)

- [ ] Prompt templates and style presets
- [ ] Remix / iterate on previous generation
- [ ] Follow creators
- [ ] XP, levels, badges
- [ ] Music generation (MiniMax Music 2.5)
- [ ] User-created Subs
- [ ] Optional IAP (remove ads / double credits)
- [ ] Android version

---

## Environment Variables

### Backend (.env)

| Variable | Description |
|----------|-------------|
| `FAL_KEY` | Fal.ai API key |
| `RATE_LIMIT_ENABLED` | Enable rate limiting (true/false) |

### iOS (Constants.swift)

| Constant | Description |
|----------|-------------|
| `API.baseURL` | Deployed Vercel backend URL |

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/generate-image` | Generate an image via Fal.ai |
| POST | `/api/generate-video` | Generate a video via Fal.ai |
| POST | `/api/check-prompt` | Check prompt against blocklist |
| GET | `/api/health` | Health check |

---

## License

Proprietary. All rights reserved.
