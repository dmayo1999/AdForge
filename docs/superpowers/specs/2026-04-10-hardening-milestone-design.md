# Hardening Milestone — Design Spec

**Date:** 2026-04-10  
**Status:** Approved (conversational sign-off)  
**Milestone:** C — Engineering hardening before production feature work

## Summary

Add automated tests and continuous integration for the Vercel Edge backend, replace per-instance in-memory rate limiting with **Upstash Redis** (REST API, edge-compatible) when configured, and optionally add Swift-level tests in a **second phase** once the repo exposes a testable Swift target (Swift Package or committed Xcode project).

## Goals

1. **Backend tests** — Deterministic coverage for prompt safety (`checkPrompt`), shared rate-limit behavior, and generation route handlers with **mocked** Fal.ai / network (no live API keys in CI).
2. **CI** — On every push and pull request to `main`, run install, test, and TypeScript `typecheck` for `backend/`.
3. **Distributed rate limiting** — When `UPSTASH_REDIS_REST_URL` and `UPSTASH_REDIS_REST_TOKEN` are set, enforce the same logical limits (max 50 requests per client IP per hour, matching current behavior) using Redis. When unset, retain **in-memory** behavior for local development and single-instance preview deploys.
4. **Documentation** — Env vars and deployment notes for Redis; no change to README product claims beyond a short “Hardening” subsection if needed.

## Non-Goals

- Firebase Auth, Firestore, real AppLovin MAX, or turning off `GenerationService.isMockMode`.
- Android or new product features from README Phase 2.
- Load testing or production SLO guarantees (out of scope for this milestone).

## Architecture

### Rate limiting

- **Extract** the sliding-window logic currently duplicated or embedded in `generate-image.ts` and `generate-video.ts` into a shared module (e.g. `backend/lib/rate-limit.ts`).
- **Interface:** A single entry point used by both routes, e.g. `checkRateLimit(ip: string): Promise<{ allowed: boolean; retryAfter?: number }>` (async if Redis-backed).
- **Implementations:**
  - **Memory:** Current `Map`-based behavior; used when `RATE_LIMIT_ENABLED` is false (bypass) or when Redis env is missing (development).
  - **Redis:** Upstash via official client or REST; sliding or fixed window — implementation may choose fixed window for simplicity **provided** the user-visible limit semantics remain “50 per IP per hour” equivalent (document the exact algorithm in code comments).
- **Configuration:** Reuse `RATE_LIMIT_ENABLED`; when false, skip both memory and Redis checks.

### Backend tests

- **Runner:** Vitest (or Node test runner) with TypeScript via existing `tsconfig`.
- **Scope:** `checkPrompt` (golden cases: empty, safe, blocked term, regex, celebrity), rate-limit module (memory implementation, edge cases on window boundary), route handlers tested by invoking exported handler logic or small HTTP-level tests with mocked `generateImage` / `generateVideo` imports.
- **Secrets:** CI uses no real `FAL_KEY`; Fal client must be mockable or routes must inject a test double.

### Continuous integration

- **Platform:** GitHub Actions (repository is git-backed; workflow lives under `.github/workflows/`).
- **Triggers:** `push` and `pull_request` to `main`.
- **Job:** Node 20, `working-directory: backend`, `npm ci`, `npm test`, `npm run typecheck`.
- **Optional:** `paths` filters so only `backend/**` changes trigger the workflow (reduces noise; acceptable to skip in first PR if simplicity preferred).


### iOS testing (Phase B — after backend hardening lands)

The repo currently contains Swift sources **without** a checked-in `.xcodeproj`. Phase B is one of:

- **Option A:** Add a **Swift Package** (e.g. `AdForgeCore`) containing pure logic with **XCTest**, runnable on Linux/macOS CI; or  
- **Option B:** Commit the **Xcode project** and add a unit test target, then run `xcodebuild test` in CI.

Choice is deferred to the implementation plan; this spec only records that Phase B is **in scope for the balanced approach** but **sequenced after** Phase A (backend + CI + Redis).

## Error Handling and Operations

- When Redis URL and token are **set**, do **not** silently fall back to in-memory limits (that would undercut abuse protection across instances). On persistent Redis failure after a small retry budget, return **503** with a JSON body such as `{ "error": "rate_limit_unavailable" }` so operators can alert; clients already handle non-2xx.
- When Redis env is **unset**, use in-memory limiting as today (development and single-instance preview).
- Logging: minimal structured logs suitable for Vercel; avoid logging full client IPs in plaintext (optional hash or omit).

## Testing Strategy (Acceptance)

- CI passes on a clean clone with no `.env`.
- Prompt checker tests prevent regressions on blocklist behavior.
- Rate limit tests cover memory path; Redis path covered by unit tests with a **mock Redis client** or integration test against a test Upstash instance (only if secrets available in CI — otherwise mock only).
- Manual smoke: `vercel dev` still works with Redis unset.

## Implementation Plan Inputs

- **Redis client:** Choose Upstash REST-compatible packages for Edge (`@upstash/ratelimit` and/or `@upstash/redis`) with minimal dependencies.
- **Phase B Swift:** Choose SPM vs committed Xcode project when scheduling Phase B.