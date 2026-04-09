# AdForge — Product Requirements Document

**Version:** 2.0  
**Date:** April 8, 2026  
**Author:** D. Gibson  
**Status:** Draft — Ready for Engineering Handoff

---

## 1. Problem Statement

Premium AI creative tools are locked behind $10–$50/month subscriptions (Midjourney $10/mo, Runway $15/mo, Udio $10/mo). Gen Z and younger creators — the most prolific content-producing demographic — are largely priced out. Free tiers are crippled: 25 images/month on Leonardo, 10 seconds of video on Pika, watermarked outputs everywhere.

Meanwhile, this audience watches 50+ minutes of short-form video daily and is conditioned to ad-supported free models (Spotify Free, YouTube, TikTok itself). They will trade 30 seconds of attention for creative output — that exchange just doesn't exist today.

The gap: no app offers unlimited AI generation funded by rewarded ads inside a social-competitive loop. The closest analogues are Remini (photo enhancement, no generation), Wonder (basic image gen, no social layer), and Dawn AI (avatars only). None combine multi-modal generation + social feed + gamified competitions.

**Evidence supporting the model:**
- Rewarded video completion rates exceed 95%, vs. 60–70% for non-rewarded formats ([MAF](https://maf.ad/en/blog/rewarded-ads-stats/)).
- US iOS rewarded video eCPMs averaged $19.63 in Q4 2024, with the broader range sitting at $8–$20 ([Yango Ads](https://yango-ads.com/blog/rewarded-video-ads-for-mobile-apps)).
- Players who engage with rewarded ads are 4x more likely to make in-app purchases ([MAF](https://maf.ad/en/blog/rewarded-ads-stats/)).
- Fal.ai 2026 pricing makes per-generation costs low enough ($0.025/image, ~$0.05/s video) to maintain positive margins even at conservative eCPMs.

---

## 2. Business & Product Goals

### Primary Goals (6-month horizon)

| Goal | Target | Measurement |
|------|--------|-------------|
| Monthly Active Users | 500k MAU | Mixpanel + App Store Connect |
| Monthly Ad Revenue | $50k–$200k | Ad network dashboard |
| AI Cost as % of Revenue | < 25% | Internal cost tracking |
| Day-7 Retention | ≥ 40% | Mixpanel cohort analysis |

### Secondary Goals

| Goal | Target | Measurement |
|------|--------|-------------|
| Competition Submission Rate | ≥ 20% of all generations | Backend event tracking |
| App Store Rating | ≥ 4.7 stars | App Store Connect |
| Organic Install Rate | ≥ 60% of total installs | Attribution via Mixpanel |

### User Goals vs. Business Goals

| User Goals | Business Goals |
|------------|----------------|
| Create high-quality AI content for free | Maximize ad impressions per session |
| Gain social validation and followers | Drive viral sharing loops back to app |
| Win competitions and earn status | Sustain retention through gamification |
| Share content to TikTok/IG natively | Grow organic installs via watermarked shares |

---

## 3. Non-Goals (Explicitly Out of Scope)

| Non-Goal | Rationale |
|----------|-----------|
| Android version at launch | Focus resources on single platform; iOS has higher eCPMs and better rewarded ad infrastructure. Android is Phase 2. |
| Real-money prizes or payouts | Triggers gambling/sweepstakes regulation. Rewards are in-app only (credits, badges, titles). |
| User-uploaded training / fine-tuning | Massive liability, storage cost, and moderation burden. All generation uses hosted API models only. |
| Chat or direct messaging | Triggers Apple's 1.2 UGC guideline for anonymous chat ([Apple, Feb 2026](https://developer.apple.com/news/?id=d75yllv4)), adds moderation load with zero revenue upside. |
| Text generation / chatbot features | Out of scope. Visual and audio creation only. |
| Crypto, NFTs, or blockchain integration | App Store guideline 3.1.5(b) scrutiny, audience doesn't care, adds complexity. |
| Subscription-only premium tier at launch | Validate ad model first. Optional IAP hybrid tested in Phase 2. |

---

## 4. Target Audience

**Primary:** Gen Z / younger Millennials (17–28), heavy TikTok/Instagram users, meme creators, music producers, digital artists.

**Secondary:** High-school and college students who want creative AI tools without paying subscription fees.

**Psychographics:**
- Motivated by instant gratification and social validation
- Comfortable with ad-supported free models
- Create content for social media, not professional use
- Competitive — drawn to leaderboards, streaks, and status

---

## 5. User Stories

### Onboarding & First Experience

| ID | Story | Priority |
|----|-------|----------|
| US-01 | As a new user, I want to sign in with Apple ID in one tap so that I can start creating immediately. | P0 |
| US-02 | As a new user, I want to generate my first image without watching an ad so that I understand the value before committing attention. | P0 |
| US-03 | As a new user, I want a 30-second tutorial showing the Watch → Create → Share loop so that I understand how the app works. | P1 |

### Generation Studio

| ID | Story | Priority |
|----|-------|----------|
| US-04 | As a creator, I want to see exactly how many credits a generation will cost before I commit so that I don't waste credits. | P0 |
| US-05 | As a creator, I want to watch a single rewarded video ad to earn credits so that I can generate content for free. | P0 |
| US-06 | As a creator, I want to choose between multiple AI models for image generation so that I can compare quality and style. | P0 |
| US-07 | As a creator, I want to use prompt templates and style presets so that I can get good results without prompt engineering skill. | P1 |
| US-08 | As a creator, I want to generate short videos from a text prompt so that I can create video content. | P0 |
| US-09 | As a creator, I want to remix a previous generation (edit/iterate) so that I can refine my work. | P1 |
| US-10 | As a creator, I want a "Meme Mode" that auto-formats images with text overlays so that I can create shareable memes quickly. | P2 |
| US-11 | As a creator, I want side-by-side model comparison so that I can pick the best output before spending credits. | P2 |

### Social Feed

| ID | Story | Priority |
|----|-------|----------|
| US-12 | As a user, I want to scroll an infinite vertical feed of community creations so that I can discover content and get inspired. | P0 |
| US-13 | As a user, I want to vote (heart) on creations I like so that I can support other creators. | P0 |
| US-14 | As a user, I want to share a creation to TikTok/Instagram with a watermark and deep link so that my followers can find the app. | P0 |
| US-15 | As a user, I want to follow other creators so that I see their work in my feed. | P1 |

### Competitions

| ID | Story | Priority |
|----|-------|----------|
| US-16 | As a creator, I want to submit my generation to a themed competition (Sub) with one tap so that I can compete. | P0 |
| US-17 | As a user, I want to browse active competitions and see submission deadlines so that I can participate. | P0 |
| US-18 | As a user, I want to see a real-time leaderboard for each competition so that I know where I stand. | P0 |
| US-19 | As a winner, I want to earn bonus credits and a visible badge so that my achievement is recognized. | P1 |
| US-20 | As a user, I want to earn hearts (votes) daily and refill them by watching ads so that I always have a reason to engage. | P1 |

### Profile & Gamification

| ID | Story | Priority |
|----|-------|----------|
| US-21 | As a user, I want a profile showing my creations, badges, level, and competition history so that I have a sense of progression. | P1 |
| US-22 | As a user, I want to earn XP from generations, votes, and competition wins so that I level up over time. | P1 |
| US-23 | As a user, I want daily login streaks and bonus credit rewards so that I have a reason to come back every day. | P1 |

---

## 6. Requirements

### P0 — Must Ship (MVP)

| Req | Description | Acceptance Criteria |
|-----|-------------|---------------------|
| R-01 | **Apple Sign-In authentication** | Given a new user, when they tap "Sign in with Apple," then an account is created and they land on the Home screen within 3 seconds. Given a returning user, when they open the app, then they are auto-authenticated. |
| R-02 | **Credit system with transparent cost preview** | Given a user viewing the generation screen, when they select a model and prompt, then the exact credit cost is displayed before generation starts. Given a user with insufficient credits, when they attempt to generate, then they are prompted to watch an ad or shown their balance. |
| R-03 | **Rewarded video ad integration** | Given a user who taps "Watch Ad," when the ad completes (15–30s), then 1,000 credits are added to their balance within 1 second. Given an ad network failure, when the ad fails to load, then the user sees a retry option (not a dead end). |
| R-04 | **Image generation (2+ models)** | Given a user with sufficient credits, when they submit a prompt, then an image is generated and displayed within 15 seconds. Output: PNG, minimum 1024x1024. Models at launch: Flux 2 Pro, Flux 2 Dev. |
| R-05 | **Video generation (1 model)** | Given a user with sufficient credits, when they submit a text or image prompt, then a 5-second MP4 video is generated within 60 seconds. Model at launch: Wan 2.5. |
| R-06 | **Community feed (infinite scroll)** | Given a user on the Feed tab, when they scroll, then new community creations load continuously. Feed is ranked by recency + vote count (simple algorithm). |
| R-07 | **Voting system (hearts)** | Given a user viewing a creation in the feed, when they tap the heart icon, then 1 vote is recorded and the count updates in real time. Users receive 20 hearts daily, refilled at midnight UTC. |
| R-08 | **Competition Subs (6 at launch)** | Given a user on the Competitions tab, when they browse, then they see 6 active Subs with submission counts, deadlines, and leaderboards. Subs at launch: Best Meme, Cinematic Landscape, Hyperrealistic Portrait, Surreal Dreamscape, Viral Short Video, Funny AI Fails. |
| R-09 | **Submit to competition** | Given a user who has just generated content, when they tap "Submit to Sub," then they can choose a Sub and their entry appears on the leaderboard within 5 seconds. |
| R-10 | **Leaderboard per Sub** | Given a user viewing a Sub, when they tap "Leaderboard," then they see entries ranked by vote count with 24-hour or 48-hour voting windows. |
| R-11 | **Share to TikTok / Instagram** | Given a user viewing their creation, when they tap "Share," then the image/video is exported with a small AdForge watermark and deep link. The system share sheet opens with TikTok and Instagram as options. |
| R-12 | **Daily free credits** | Given any user, when they open the app for the first time each day, then 500 free credits are added to their balance (no ad required). |
| R-13 | **Prompt safety layer** | Given a user submitting a prompt, when the prompt contains blocked terms, then generation is refused with a generic "Try a different prompt" message. Blocklist maintained server-side and updatable without app update. |
| R-14 | **Content report button** | Given a user viewing any creation in the feed or a Sub, when they tap the report icon, then a report is submitted with category (offensive / spam / other) and the content is flagged for review. |

### P1 — Should Ship (Fast Follow, Weeks 1–4 Post-Launch)

| Req | Description |
|-----|-------------|
| R-15 | Prompt templates and style presets (curated library of 20+) |
| R-16 | Remix / iterate on previous generation |
| R-17 | Follow creators and personalized feed ranking |
| R-18 | XP, levels, and progression system |
| R-19 | Badges and titles ("Meme Lord," "Video Virtuoso") |
| R-20 | Daily login streaks and bonus credit multipliers |
| R-21 | Weekly Grand Challenges with larger prize pools |
| R-22 | "Prompt of the Day" daily mini-challenge |
| R-23 | Global "Hall of Fame" for all-time top creations |
| R-24 | Additional image models (SD3, Lumina) |

### P2 — Could Ship (Phase 2+)

| Req | Description |
|-----|-------------|
| R-25 | Music generation (MiniMax Music 2.5 or equivalent) |
| R-26 | User-created Subs (moderated) |
| R-27 | Side-by-side model comparison view |
| R-28 | "Meme Mode" auto-formatting |
| R-29 | Seasonal themed events (Halloween Horror, etc.) |
| R-30 | Optional IAP: remove ads / double credits ($4.99 one-time or $2.99/mo) |
| R-31 | Android version |
| R-32 | Advanced gamification (duets, creator tiers, seasonal rankings) |

---

## 7. Core User Flows

### 7.1 Onboarding

```
App Launch → Apple Sign-In (one tap) → 500 free credits granted
→ Tutorial overlay: "Watch one ad → Generate your first meme"
→ User generates first image with free credits → Prompt to share or submit to Sub
```

### 7.2 Generation (Studio Tab)

```
Studio Tab → Choose type (Image / Video)
→ Select model (carousel) → Enter prompt (or pick template)
→ See credit cost preview → Sufficient credits? → Generate
                           → Insufficient? → Watch Ad → Generate
→ Output displayed → Save to Camera Roll / Share / Submit to Sub
```

### 7.3 Competition

```
Competitions Tab → Browse active Subs → Tap into a Sub
→ View entries + leaderboard → Submit own entry (from gallery or generate new)
→ Vote on others' entries (spend hearts) → Check rank
```

### 7.4 Daily Engagement Loop

```
Open App → Receive 500 daily credits → Check "Prompt of the Day"
→ Generate → Submit to competition → Vote on feed → Watch ads for more credits
→ Check leaderboard position → Share wins to TikTok/IG → Close
```

---

## 8. Technical Architecture

### Platform & Frameworks

| Layer | Technology |
|-------|------------|
| Client | SwiftUI + Swift 6, iOS 17+ |
| Auth | Firebase Auth (Apple Sign-In + anonymous fallback) |
| Database | Firestore (user profiles, credits, votes, leaderboards) |
| Media Storage | Cloudinary or Supabase Storage (temporary, 30-day TTL on generated media) |
| AI Backend | Serverless proxy (Vercel Edge Functions or Railway) → Fal.ai API |
| Ad SDK | AppLovin MAX (primary mediation) with Unity Ads + AdMob as fill |
| Analytics | Mixpanel (product events) + App Store Connect (acquisition) |
| Push Notifications | Firebase Cloud Messaging |

### AI Cost Table (Fal.ai 2026 Pricing)

| Type | Model | Cost per Gen | Credit Cost to User | Margin per Ad Watch |
|------|-------|-------------|---------------------|---------------------|
| Image | Flux 2 Pro | ~$0.035 | 300 credits | Ad revenue ($0.008–$0.020) minus $0.035 = varies |
| Image | Flux 2 Dev | ~$0.025 | 200 credits | Higher margin (cheaper model) |
| Video (5s) | Wan 2.5 | ~$0.25 | 1,000 credits | Requires ~1 full ad watch to cover |
| Video (5s) | Kling 2.5 Turbo | ~$0.15 | 800 credits | Better margin than Wan |

**Key insight:** At $10 eCPM (pessimistic), one ad watch = $0.01 revenue. A user watching 3 ads = $0.03. One image costs $0.025–$0.035. Margins are tight at low eCPMs but widen fast as traffic quality scores improve and eCPMs climb toward the $15–$20 range.

### Anti-Abuse

- Rate limit: Max 30 ad watches per device per day (prevents bot farming).
- Device fingerprinting via DeviceCheck API.
- Server-side credit ledger (not client-side — prevents tampering).
- Velocity checks: Flag accounts generating > 50 items/day.

---

## 9. Revenue Model & Unit Economics

### Revenue Streams

1. **Rewarded video ads** (100% of launch revenue)
2. **Optional IAP** (Phase 2): Remove ads / double credits, $4.99 one-time or $2.99/mo

### Scenario Modeling

| Scenario | eCPM | DAU | Ads/DAU/Day | Daily Revenue | Monthly Revenue | AI Cost (25%) | Net Monthly |
|----------|------|-----|-------------|---------------|-----------------|---------------|-------------|
| Pessimistic | $8 | 30k | 3 | $720 | $21,600 | $5,400 | $16,200 |
| Base | $14 | 80k | 4 | $4,480 | $134,400 | $33,600 | $100,800 |
| Optimistic | $20 | 150k | 5 | $15,000 | $450,000 | $112,500 | $337,500 |

**Formula:** Daily Revenue = (DAU × Ads/Day × eCPM) / 1,000

**Key assumptions:**
- eCPM range of $8–$20 is grounded in [2026 iOS benchmarks](https://adreact.com/blog/app-ad-revenue-benchmarks-2026/) (US iOS rewarded video sits $8–$20, with the national average near $19.63 for established apps).
- New apps with unproven traffic quality will likely start at the $8–$12 range and climb over 60–90 days as ad network optimization kicks in.
- AI cost percentage is conservative at 25%; actual may be lower if image gen dominates (cheaper per-unit than video).

### Cost Circuit Breaker

If AI costs exceed 30% of trailing 7-day ad revenue, the system automatically:
1. Disables the most expensive generation type (video first, then higher-cost image models).
2. Increases credit cost for expensive models by 50%.
3. Alerts the team via Slack webhook.

This prevents a cost spiral if eCPMs drop or API pricing changes.

---

## 10. Trust & Safety — Lean Launch Approach

The goal is to ship fast with the minimum defensible moderation stack, then scale moderation investment proportionally to user growth. This is not a chat app or a dating app — the risk surface is narrower because all content is AI-generated via managed APIs with built-in safety filters.

### Layer 1: Model-Level Filtering (Free — Already Built In)

All generation runs through Fal.ai's hosted models. These models (Flux, Wan, Kling) already reject prompts that request:
- Explicit sexual content / nudity
- Graphic violence / gore
- Real person deepfakes (celebrity likeness)
- Hate symbols and slurs

This is the first and strongest line of defense, and it costs nothing to maintain. If a model refuses a prompt, the user sees: "This prompt can't be processed. Try something different."

### Layer 2: Server-Side Prompt Blocklist (Low Effort)

A lightweight keyword/phrase blocklist on the serverless proxy that catches what the models might miss. Maintained as a JSON file, updatable without shipping an app update. Covers:
- Known CSAM-adjacent terminology
- Specific real-person names (politicians, celebrities) to reduce deepfake risk
- Targeted slurs and hate speech terms

Blocked prompts return the same generic refusal. No explanation of why — this prevents users from reverse-engineering the blocklist.

### Layer 3: Reactive Moderation (Report System)

- Every piece of content in the feed and competitions has a report button.
- Reports are categorized: Offensive / Spam / Deepfake / Other.
- Reported content is auto-hidden from the feed after 3 unique reports (threshold configurable).
- A lightweight admin dashboard (simple web panel) shows flagged content for manual review.
- At MVP scale, manual review is handled by the founding team — no need for dedicated moderators until 100k+ DAU.

### Layer 4: Automated Hash Matching (Non-Negotiable Legal Requirement)

Integration with PhotoDNA or equivalent perceptual hashing service to scan generated outputs against known CSAM databases. This is required under federal law (18 U.S.C. § 2258A) for any service that handles visual media. If a match is found:
- Content is blocked from publishing.
- User account is immediately suspended.
- Report is filed with NCMEC as required by law.

This is the one area with zero grey area — it must be in the MVP.

### What We're NOT Building at Launch

- No proactive AI-based content scanning of every generation before it hits the feed.
- No human review queue for every submission.
- No appeals system (email support handles edge cases).
- No real-time content classification model.

These can be added incrementally if Apple requests them during review or if moderation volume demands it post-launch.

### App Store Review Strategy

Apple's [Guideline 1.2 (User-Generated Content)](https://developer.apple.com/news/?id=d75yllv4) requires: a way to filter objectionable content, a mechanism to report offensive content, and the ability to block abusive users. The MVP satisfies all three:
- Filter: Model-level + prompt blocklist
- Report: In-app report button
- Block: User block feature (hides their content from your feed)

Apple does not require pre-moderation of all content. Reactive moderation with a report system is the standard for most UGC apps that pass review.

---

## 11. Age Rating & Compliance

### App Store Rating: 17+

Setting the App Store age rating to 17+ is the strategic call. Rationale:
- Avoids the app being classified as "directed at children," which would trigger full COPPA compliance (parental consent, data minimization, no behavioral advertising).
- The app is a general-audience creative tool. It is not designed for, marketed to, or themed around children under 13.
- 17+ rating means parental controls on younger users' devices will block the download by default — Apple handles the gating at the OS level.

### State Age Verification Laws (Texas, Utah, Louisiana, California)

As of 2026, [these states require app stores to verify user ages and share age category data with developers](https://www.loeb.com/en/insights/publications/2025/12/app-store-age-verification-laws-trigger-new-federal-and-state-childrens-privacy-requirements). Apple and Google have launched APIs for this.

**Our approach:**
- Integrate Apple's Age Category API when it becomes mandatory for our app category.
- If we receive a signal that a user is under 13, we do not collect personal data from that user and restrict access to ad-watching (no behavioral ads for under-13).
- If we receive a signal that a user is under 17, we allow read-only access to the feed but disable generation and ad-watching.
- Privacy policy and ToS explicitly state the app is intended for users 17+.

### Data Collection (Minimal by Design)

| Data Collected | Purpose | Stored Where |
|---------------|---------|--------------|
| Apple ID (hashed) | Authentication | Firebase Auth |
| Generated content | Display in feed/competitions | Cloudinary (30-day TTL) |
| Vote and credit history | Gameplay mechanics | Firestore |
| Device ID (DeviceCheck) | Anti-abuse | Firebase |
| Ad interaction events | Revenue attribution | Ad SDK (AppLovin) |

No email addresses, no phone numbers, no location data, no contacts, no photos library access. The less you collect, the less you have to defend.

---

## 12. Key Features — Detailed Specs

### 12.1 Credit System

| Parameter | Value |
|-----------|-------|
| Daily free grant | 500 credits (no ad required) |
| Credits per ad watch | 1,000 credits |
| Image generation cost | 150–400 credits (varies by model) |
| Video generation cost (5s) | 800–1,200 credits (varies by model) |
| Max ad watches per day | 30 (anti-abuse cap) |
| Credit expiration | None (credits persist indefinitely) |

Credit balance is stored server-side in Firestore. Client displays a cached value, synced on every transaction. No client-side manipulation possible.

### 12.2 Generation Types (MVP)

| Type | Models | Output | Max Wait Time |
|------|--------|--------|---------------|
| Image | Flux 2 Pro, Flux 2 Dev | PNG, 1024x1024+ | 15 seconds |
| Video | Wan 2.5 | MP4, 5 seconds, 720p | 60 seconds |

Post-MVP additions: Kling 2.5 Turbo (video), SD3 (image), Lumina (image), MiniMax Music 2.5 (audio).

### 12.3 Competitions & Subs

**Launch Subs (6):**

| Sub Name | Content Type | Voting Window |
|----------|-------------|---------------|
| Best Meme | Image | 24 hours |
| Cinematic Landscape | Image | 48 hours |
| Hyperrealistic Portrait | Image | 48 hours |
| Surreal Dreamscape | Image | 48 hours |
| Viral Short Video | Video | 48 hours |
| Funny AI Fails | Image or Video | 24 hours |

**Competition Cycle:**
- Daily mini-challenges: "Prompt of the Day" rotates at midnight UTC. Top 10 earn bonus credits.
- Weekly Grand Challenges (P1): Top 3 earn credits + exclusive badge.
- Seasonal events (P2): Multi-week themed competitions.

### 12.4 Gamification (P1 — Fast Follow)

| Mechanic | Details |
|----------|---------|
| XP Sources | +10 per generation, +5 per vote cast, +50 per competition entry, +200 per competition win |
| Levels | 1–100, displayed on profile. Level thresholds increase exponentially. |
| Badges | "Meme Lord" (50 meme submissions), "Video Virtuoso" (25 video gens), "Streak Master" (7-day streak) |
| Streaks | Consecutive daily logins. 3-day streak = 2x daily credits. 7-day = 3x. Break resets to 1x. |

### 12.5 Social Sharing

Every shared creation includes:
- A small, non-intrusive AdForge watermark (bottom-right corner).
- A deep link (Universal Link) that opens the creation in-app or redirects to App Store if not installed.
- Native share sheet integration for TikTok, Instagram Stories, iMessage, and general share.

---

## 13. Success Metrics

### MVP Launch (First 30 Days)

| Metric | Target | How Measured |
|--------|--------|-------------|
| Downloads | 100k | App Store Connect |
| DAU / MAU ratio | ≥ 30% | Mixpanel |
| Ad watches per DAU per day | ≥ 3 | Ad SDK + Mixpanel |
| Generations per DAU per day | ≥ 2 | Backend events |
| Competition submission rate | ≥ 20% of generations | Backend events |
| Day-1 retention | ≥ 55% | Mixpanel cohort |
| Day-7 retention | ≥ 40% | Mixpanel cohort |
| Day-30 retention | ≥ 20% | Mixpanel cohort |
| App Store rating | ≥ 4.7 | App Store Connect |
| ARPDAU (ad revenue) | $0.03–$0.08 | Ad network dashboard |

### Leading Indicators (Weekly Check)

- Share-to-install conversion rate (deep link → download)
- Viral coefficient (installs driven per active user)
- Prompt template usage rate (measures onboarding quality)
- Heart (vote) utilization rate (are users spending all their daily hearts?)
- Feed scroll depth (engagement quality)

### Lagging Indicators (Monthly Review)

- eCPM trend (should climb as traffic quality improves)
- AI cost per generation (should decline as we optimize model routing)
- LTV:CAC ratio (if/when paid UA starts)
- Revenue per MAU

---

## 14. Distribution & Growth Strategy

"TikTok virality" is not a strategy. Here is the actual plan:

### Organic (Primary)

1. **Watermark + deep link on every shared creation.** This is the core viral mechanic. Every image/video shared to TikTok or IG is a free ad for AdForge. Optimize the watermark to be visible but not annoying — think "made with AdForge" in clean small text.
2. **Seed content on TikTok and Instagram.** Pre-launch, create 20–30 TikTok accounts that post AdForge-generated content daily with CTAs. Target meme, AI art, and "satisfying video" niches. Budget: $0 (sweat equity) + $500 for boosting top performers.
3. **Competition results as content.** Weekly "Top 10 AI Memes" or "Best AI Videos This Week" compilations posted to social. These perform well in algorithm-driven feeds.
4. **Creator partnerships.** Identify 10–20 mid-tier TikTok creators (50k–500k followers) in the AI/creative space. Offer early access + featured placement in-app in exchange for content featuring the app. No cash spend at launch.

### Paid (Phase 2, Post-Validation)

- TikTok Spark Ads (boost organic posts that perform well)
- Apple Search Ads (branded + category terms)
- Target CPI of $0.50–$1.50

### ASO (App Store Optimization)

- Primary keywords: "AI image generator free," "AI video maker," "AI art," "meme maker"
- Localized screenshots showing generation + competition UX
- App Preview video showing the Watch → Create → Share loop in 15 seconds

---

## 15. Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| Fal.ai rate limits or pricing increase | High | Maintain integration layer that supports multiple providers (Replicate, Together.ai as fallbacks). Cost circuit breaker auto-throttles expensive generation types. |
| App Store rejection on first submission | Medium | Follow Apple's 1.2 UGC requirements exactly. Include report/block/filter. Prepare a detailed "App Review Information" note explaining the moderation stack. |
| Low initial eCPMs ($5–$8) | High | Model the pessimistic case and ensure the app survives on image-only generation (cheapest per-unit cost). Video generation can be gated behind higher credit costs if margins are thin. |
| Ad fraud / bot farming | Medium | DeviceCheck + server-side rate limits + velocity checks. 30 ad watches/day hard cap. |
| Moderation volume exceeds capacity | Medium | Auto-hide on 3 reports. Increase threshold if false-positive rate is high. Hire part-time moderator at 50k+ DAU. |
| Content goes viral for wrong reasons (offensive output) | Low | Model-level filters handle the worst cases. Prompt blocklist catches the rest. If an incident occurs, manually remove + issue a community note. |
| State age verification laws expand scope | Medium | Architecture supports age-gating. If required, restrict under-17 users to read-only mode. Privacy policy already declares 17+ intent. |

---

## 16. Open Questions

| # | Question | Owner | Blocking? |
|---|----------|-------|-----------|
| OQ-1 | Which AppLovin MAX ad format configuration maximizes eCPM for our demographic? Need to A/B test rewarded video length (15s vs 30s). | Growth / Ad Ops | No — can test post-launch |
| OQ-2 | Should anonymous/device-ID-only accounts be allowed, or require Apple Sign-In for all users? Anonymous lowers friction but complicates moderation. | Product | Yes — decide before engineering starts |
| OQ-3 | What is Fal.ai's rate limit at scale? Do we need a dedicated enterprise plan or pre-purchased capacity for launch? | Engineering | Yes — validate before launch |
| OQ-4 | Do we need to register as an "electronic service provider" under 18 U.S.C. § 2258A before launch, or does using Fal.ai's hosted models (where they handle the image generation) shift that obligation? | Legal | Yes — get a legal opinion |
| OQ-5 | What's the right 30-day TTL for generated media on Cloudinary? Too short = broken feed links. Too long = storage costs balloon. | Engineering | No — can adjust post-launch |
| OQ-6 | Should "Prompt of the Day" be editorially curated or auto-generated? | Content / Product | No |
| OQ-7 | Apple Search Ads budget for launch week? | Growth | No — organic first |

---

## 17. MVP Scope & Timeline (8–10 Weeks)

### Team Assumption
This timeline assumes 1–2 iOS engineers + 1 backend/infra engineer + 1 designer (part-time).

### Sprint Breakdown

| Week | Deliverable |
|------|-------------|
| 1–2 | Project setup, Firebase config, auth flow (Apple Sign-In), basic tab bar shell, Fal.ai proxy deployed on Vercel. |
| 3–4 | Generation Studio: image generation with Flux 2 Pro/Dev, credit system, credit cost preview, rewarded ad integration (AppLovin MAX). |
| 5–6 | Video generation (Wan 2.5), community feed (infinite scroll + voting), media upload to Cloudinary. |
| 7–8 | Competitions: 6 Subs, submission flow, leaderboards, voting windows. Share flow with watermark + deep link. |
| 9–10 | Profile screen, daily free credits, prompt blocklist, report button, anti-abuse (rate limits, DeviceCheck). QA, App Store submission prep, ASO assets. |

### Phase 2 Roadmap (Post-Launch)

| Timeline | Feature |
|----------|---------|
| Weeks 1–4 post-launch | Prompt templates, remix, follow system, XP/levels, badges |
| Months 2–3 | Music generation, weekly Grand Challenges, seasonal events |
| Months 3–4 | Optional IAP (remove ads / double credits) |
| Month 4+ | Android version, user-created Subs, advanced gamification |

---

## 18. Appendix: Generation Cost Reference

Based on [Fal.ai](https://fal.ai) published pricing as of March 2026:

| Model | Type | Per-Unit Cost | Notes |
|-------|------|--------------|-------|
| Flux 2 Pro | Image | ~$0.035/image | Highest quality, slower |
| Flux 2 Dev | Image | ~$0.025/image | Good quality, faster, cheaper |
| SD3 | Image | ~$0.02/image | Phase 2 |
| Wan 2.5 | Video | ~$0.05/second ($0.25 for 5s) | Primary video model |
| Kling 2.5 Turbo | Video | ~$0.03/second ($0.15 for 5s) | Cheaper alternative, Phase 2 |
| Hailuo | Video | ~$0.04/second ($0.20 for 5s) | Phase 2 |
| MiniMax Music 2.5 | Audio | ~$0.035/generation (30s) | Phase 2 |

---

*This document is the single source of truth for AdForge MVP. All design and engineering work should reference this PRD. Open questions tagged as "Blocking" must be resolved before sprint planning begins.*
