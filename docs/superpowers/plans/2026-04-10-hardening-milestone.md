# Hardening Milestone Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Vitest coverage for `backend/`, GitHub Actions CI, and shared rate limiting with optional Upstash Redis (per-route 50 req/IP/hour, matching today’s separate in-memory maps), without wiring production iOS or Firebase.

**Architecture:** Extract `checkPrompt` tests against real `blocklist.json`. Extract rate limiting into `backend/lib/rate-limit.ts` with a **memory** path (composite key `image|video` + IP) and **Redis** path using `@upstash/ratelimit` + `@upstash/redis` with **two** `Ratelimit` instances (image vs video) so limits stay independent. API routes import `checkRateLimit(route, ip)` and map Redis outage to **503** `{ "error": "rate_limit_unavailable" }`. Handler tests use `vi.mock` on `../lib/fal-client.js` so CI needs no `FAL_KEY`.

**Tech Stack:** Node 20, TypeScript (NodeNext), Vitest 3.x, Vercel Edge, Upstash Redis REST.

---

## File map (Phase A — backend)

| File | Role |
|------|------|
| `backend/package.json` | Add `vitest`, `@vitest/coverage-v8` (optional), `@upstash/redis`, `@upstash/ratelimit`; scripts `test`, `test:watch` |
| `backend/vitest.config.ts` | Resolve `.js` → `.ts` for local tests; `environment: 'node'` |
| `backend/tsconfig.json` | Extend `include` with `vitest.config.ts`, `lib/**/*.test.ts`, `api/**/*.test.ts` (or `**/*.test.ts` under backend) |
| `backend/lib/rate-limit.ts` | **New:** memory + Redis rate limit exports |
| `backend/lib/prompt-checker.test.ts` | **New:** golden tests for `checkPrompt` |
| `backend/lib/rate-limit.test.ts` | **New:** memory sliding window + mocked Redis failures |
| `backend/api/generate-image.ts` | Remove inline RL; `await checkRateLimit('image', ip)`; handle 503 |
| `backend/api/generate-video.ts` | Same for `'video'` |
| `backend/api/generate-image.test.ts` | **New:** `Request` → handler; mock Fal |
| `backend/api/generate-video.test.ts` | **New:** same pattern |
| `backend/.env.example` | Document `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN` |
| `README.md` | Short “Backend hardening” bullet under backend section |
| `.github/workflows/backend-ci.yml` | **New:** Node 20, `working-directory: backend`, `npm ci && npm test && npm run typecheck` |

**Phase B (Swift):** Deferred until Phase A merges; choose SPM (`AdForgeCore` package + `swift test`) **or** commit `.xcodeproj` — see final task.

---

### Task 1: Vitest scaffold and config

**Files:**
- Modify: `backend/package.json`
- Create: `backend/vitest.config.ts`
- Modify: `backend/tsconfig.json`

- [ ] **Step 1: Add dev dependencies**

Run in `backend/`:

```bash
cd backend && npm install -D vitest@^3.0.0 @vitest/coverage-v8@^3.0.0
```

Add scripts to `package.json`:

```json
"scripts": {
  "dev": "vercel dev",
  "deploy": "vercel --prod",
  "typecheck": "tsc --noEmit",
  "test": "vitest run",
  "test:watch": "vitest"
}
```

- [ ] **Step 2: Create `backend/vitest.config.ts`**

```typescript
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    globals: false,
    include: ["lib/**/*.test.ts", "api/**/*.test.ts"],
    coverage: {
      provider: "v8",
      reporter: ["text", "html"],
      include: ["lib/**/*.ts", "api/**/*.ts"],
      exclude: ["**/*.test.ts", "**/node_modules/**"],
    },
  },
});
```

- [ ] **Step 3: Extend `backend/tsconfig.json` `include`**

Append to the `include` array (keep existing entries):

```json
"vitest.config.ts",
"lib/**/*.test.ts",
"api/**/*.test.ts"
```

- [ ] **Step 4: Run typecheck (should still pass)**

```bash
cd backend && npm run typecheck
```

Expected: exit code 0.

- [ ] **Step 5: Run tests (empty suite passes)**

```bash
cd backend && npm test
```

Expected: Vitest runs with 0 tests or passes.

- [ ] **Step 6: Commit**

```bash
git add backend/package.json backend/package-lock.json backend/vitest.config.ts backend/tsconfig.json
git commit -m "chore(backend): add Vitest scaffold"
```

---

### Task 2: `checkPrompt` golden tests

**Files:**
- Create: `backend/lib/prompt-checker.test.ts`

- [ ] **Step 1: Write tests**

Create `backend/lib/prompt-checker.test.ts`:

```typescript
import { describe, it, expect } from "vitest";
import { checkPrompt } from "./prompt-checker.js";
import blocklist from "./blocklist.json" with { type: "json" };

describe("checkPrompt", () => {
  it("rejects empty and whitespace-only prompts", () => {
    expect(checkPrompt("")).toEqual({
      safe: false,
      reason: "empty_prompt",
    });
    expect(checkPrompt("   \t\n")).toEqual({
      safe: false,
      reason: "empty_prompt",
    });
  });

  it("accepts a benign creative prompt", () => {
    const r = checkPrompt("A watercolor painting of mountains at sunset.");
    expect(r.safe).toBe(true);
    expect(r.reason).toBeUndefined();
  });

  it("blocks a term from the blocklist (substring)", () => {
    const term = (blocklist.terms as string[])[0];
    expect(term.length).toBeGreaterThan(0);
    const r = checkPrompt(`something about ${term} here`);
    expect(r.safe).toBe(false);
    expect(r.reason).toBe("prohibited_content");
  });

  it("blocks celebrity / public figure names when present in blocklist", () => {
    const names = blocklist.celebrity_names as string[];
    if (names.length === 0) return;
    const name = names[0];
    const r = checkPrompt(`a portrait of ${name} at the beach`);
    expect(r.safe).toBe(false);
    expect(r.reason).toBe("public_figure_not_allowed");
  });
});
```

- [ ] **Step 2: Run tests**

```bash
cd backend && npm test
```

Expected: all tests pass.

- [ ] **Step 3: Commit**

```bash
git add backend/lib/prompt-checker.test.ts
git commit -m "test(backend): add checkPrompt golden tests"
```

---

### Task 3: Rate limit module (memory + Redis)

**Files:**
- Create: `backend/lib/rate-limit.ts`
- Create: `backend/lib/rate-limit.test.ts`
- Modify: `backend/package.json` (production deps)

- [ ] **Step 1: Install Upstash packages**

```bash
cd backend && npm install @upstash/redis @upstash/ratelimit
```

- [ ] **Step 2: Implement `backend/lib/rate-limit.ts`**

Behavior contract:

1. If `RATE_LIMIT_ENABLED === "false"` → `{ type: "allowed" }`.
2. If **either** `UPSTASH_REDIS_REST_URL` or `UPSTASH_REDIS_REST_TOKEN` is missing/empty → use **memory** sliding window per `route` + `ip` (composite key `` `${route}:${ip}` ``). Max **50** timestamps within **1 hour** window; on exceed return `{ type: "limited", retryAfterSeconds: number }`.
3. If **both** Redis env vars are set → use two lazy-initialized `Ratelimit` instances (prefix `adforge:rl:image` and `adforge:rl:video`), `Ratelimit.slidingWindow(50, "1 h")`, `analytics: false`. Call `limit(ip)`. If `success` → `{ type: "allowed" }`. If not → `retryAfterSeconds` from `Math.max(1, Math.ceil((result.reset - Date.now()) / 1000))` (Upstash exposes `reset` as ms timestamp).
4. If Redis path throws on **either** attempt (initial + one retry with fresh `limit()` call): return `{ type: "redis_unavailable" }` — **do not** fall back to memory.

Export:

```typescript
export type RateRoute = "image" | "video";

export type RateLimitResult =
  | { type: "allowed" }
  | { type: "limited"; retryAfterSeconds: number }
  | { type: "redis_unavailable" };

export function checkRateLimit(
  route: RateRoute,
  ip: string
): Promise<RateLimitResult>;
```

**Reference implementation (memory path — adapt imports to your file layout):**

```typescript
const RATE_LIMIT_MAX = 50;
const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000;

const memoryStore = new Map<string, { timestamps: number[] }>();

function memoryCheck(key: string): RateLimitResult {
  const now = Date.now();
  const entry = memoryStore.get(key) ?? { timestamps: [] };
  entry.timestamps = entry.timestamps.filter((t) => now - t < RATE_LIMIT_WINDOW_MS);
  if (entry.timestamps.length >= RATE_LIMIT_MAX) {
    const oldest = entry.timestamps[0]!;
    const retryAfterSeconds = Math.ceil(
      (oldest + RATE_LIMIT_WINDOW_MS - now) / 1000
    );
    return { type: "limited", retryAfterSeconds };
  }
  entry.timestamps.push(now);
  memoryStore.set(key, entry);
  if (memoryStore.size > 10_000) {
    for (const [k, val] of memoryStore) {
      if (val.timestamps.every((t) => now - t >= RATE_LIMIT_WINDOW_MS)) {
        memoryStore.delete(k);
      }
    }
  }
  return { type: "allowed" };
}

/** Test-only: clear memory maps between Vitest cases. */
export function resetRateLimitMemoryForTests(): void {
  memoryStore.clear();
}
```

**Redis path:** at module load, **do not** construct `Redis` if env is incomplete. Inside `checkRateLimit`, when both vars are set, `import("@upstash/ratelimit")` and `import("@upstash/redis")` once, cache `imageLimit` / `videoLimit` in module-level `let` after first successful init. Wrap `limit(ip)` in try/catch; on error, retry once; on second failure return `{ type: "redis_unavailable" }`.

- [ ] **Step 3: Write `backend/lib/rate-limit.test.ts`**

- With `RATE_LIMIT_ENABLED` unset: allow bypass by setting `process.env.RATE_LIMIT_ENABLED = "false"` in a test, then restore.
- Memory: call exported `resetRateLimitMemoryForTests()` in `beforeEach` (defined in `rate-limit.ts` for test use only).
- Assert 50th request in window allowed, 51st blocked with `retryAfterSeconds > 0`.
- Redis: `vi.mock("@upstash/redis", () => ({ Redis: class { ... } }))` and `vi.mock("@upstash/ratelimit", ...)` to force throw → expect `redis_unavailable` when both env vars are set.

- [ ] **Step 4: Run tests**

```bash
cd backend && npm test
```

- [ ] **Step 5: Commit**

```bash
git add backend/lib/rate-limit.ts backend/lib/rate-limit.test.ts backend/package.json backend/package-lock.json
git commit -m "feat(backend): shared rate limit with optional Upstash Redis"
```

---

### Task 4: Wire `generate-image` and `generate-video` handlers

**Files:**
- Modify: `backend/api/generate-image.ts`
- Modify: `backend/api/generate-video.ts`

- [ ] **Step 1: Replace inline rate limit in `generate-image.ts`**

- Delete local `RateLimitEntry`, `rateLimitMap`, and `checkRateLimit` function (lines 27–78).
- Import: `import { checkRateLimit } from "../lib/rate-limit.js";`
- After computing `ip`, use:

```typescript
const rl = await checkRateLimit("image", ip);
if (rl.type === "limited") {
  return json(
    {
      error: "rate_limit_exceeded",
      message: `Too many requests. Retry after ${rl.retryAfterSeconds} seconds.`,
      retryAfter: rl.retryAfterSeconds,
    },
    429,
    { "Retry-After": String(rl.retryAfterSeconds) }
  );
}
if (rl.type === "redis_unavailable") {
  return json({ error: "rate_limit_unavailable" }, 503);
}
```

- Update file header comment: remove TODO about Redis; note Upstash when env set.

- [ ] **Step 2: Mirror in `generate-video.ts`** with `checkRateLimit("video", ip)`.

- [ ] **Step 3: Run typecheck and tests**

```bash
cd backend && npm run typecheck && npm test
```

- [ ] **Step 4: Commit**

```bash
git add backend/api/generate-image.ts backend/api/generate-video.ts
git commit -m "refactor(backend): use shared rate limit in generate routes"
```

---

### Task 5: Handler tests with mocked Fal client

**Files:**
- Create: `backend/api/generate-image.test.ts`
- Create: `backend/api/generate-video.test.ts`

- [ ] **Step 1: Mock Fal — `backend/api/generate-image.test.ts`**

```typescript
import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("../lib/fal-client.js", () => ({
  generateImage: vi.fn(async () => ({
    imageURL: "https://example.com/img.png",
  })),
  generateVideo: vi.fn(),
}));

import handler from "./generate-image.js";
import { generateImage } from "../lib/fal-client.js";

function postRequest(body: object, headers?: Record<string, string>): Request {
  return new Request("http://localhost/api/generate-image", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-forwarded-for": "203.0.113.1",
      ...headers,
    },
    body: JSON.stringify(body),
  });
}

describe("POST /api/generate-image", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.RATE_LIMIT_ENABLED = "false";
  });

  it("returns 200 and image payload when valid", async () => {
    const res = await handler(
      postRequest({
        prompt: "A red balloon over a calm lake",
        model: "flux-2-pro",
        userId: "user-1",
      })
    );
    expect(res.status).toBe(200);
    const json = (await res.json()) as { imageURL: string };
    expect(json.imageURL).toContain("http");
    expect(generateImage).toHaveBeenCalledOnce();
  });

  it("returns 400 when prompt blocked", async () => {
    const res = await handler(
      postRequest({
        prompt: "snuff film realistic",
        model: "flux-2-pro",
        userId: "user-1",
      })
    );
    expect(res.status).toBe(400);
  });
});
```

Adjust import paths if Vitest resolves `default` export differently — use actual export from `generate-image.ts`.

- [ ] **Step 2: `generate-video.test.ts`** — same structure; mock `generateVideo`; valid model `wan-2.5`; assert `videoURL` in JSON.

- [ ] **Step 3: Run**

```bash
cd backend && npm test
```

- [ ] **Step 4: Commit**

```bash
git add backend/api/generate-image.test.ts backend/api/generate-video.test.ts
git commit -m "test(backend): generate-image and generate-video handlers with mocked Fal"
```

---

### Task 6: GitHub Actions workflow

**Files:**
- Create: `.github/workflows/backend-ci.yml`

- [ ] **Step 1: Add workflow**

```yaml
name: Backend CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: backend
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"
          cache-dependency-path: backend/package-lock.json
      - name: Install
        run: npm ci
      - name: Typecheck
        run: npm run typecheck
      - name: Test
        run: npm test
```

- [ ] **Step 2: Push branch and confirm workflow green** (or `act` locally if installed).

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/backend-ci.yml
git commit -m "ci: add backend test and typecheck workflow"
```

---

### Task 7: Environment and README

**Files:**
- Modify: `backend/.env.example`
- Modify: `README.md`

- [ ] **Step 1: Append to `backend/.env.example`**

```env
# -------------------------------------------------------------------
# Upstash Redis (optional — distributed rate limits on Vercel)
# -------------------------------------------------------------------
# Create a Redis database at https://console.upstash.com/ and paste REST credentials.
# If unset, the API falls back to in-memory rate limiting (single-instance only).
UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=
```

- [ ] **Step 2: README** — Under **Backend Setup** or **Environment Variables**, add 2–3 lines: Upstash optional; both vars required for Redis path; 503 if Redis down when configured.

- [ ] **Step 3: Commit**

```bash
git add backend/.env.example README.md
git commit -m "docs: document Upstash Redis for rate limiting"
```

---

### Task 8: Manual smoke (no commit)

- [ ] With only `FAL_KEY` in `.env.local`, `RATE_LIMIT_ENABLED=true`, **no** Upstash vars: `npx vercel dev` — hit `/api/generate-image` from curl with a safe prompt; expect 200 (or Fal error if key invalid — at least not 503 RL).
- [ ] With Upstash vars in Vercel preview: confirm 429 after abuse script (optional).

---

## Phase B — Swift tests (after Phase A merges)

Pick **one** path; do not do both unless you split work.

### Option A: Swift Package

**Files:** `AdForgeCore/Package.swift`, `Sources/AdForgeCore/PromptFilter.swift` (move or wrap existing filter), `Tests/AdForgeCoreTests/...`

- [ ] Add package; `swift test` in CI job `runs-on: macos-latest` or Ubuntu with Swift toolchain.
- [ ] Keep app target importing package when Xcode project exists.

### Option B: Committed Xcode project

- [ ] Add `.xcodeproj` + unit test target; extract testable types.
- [ ] CI: `xcodebuild test -scheme AdForge -destination 'platform=iOS Simulator,name=iPhone 16'`.

---

## Spec coverage checklist (plan self-review)

| Spec requirement | Task |
|------------------|------|
| Vitest + prompt tests | Task 1–2 |
| CI push/PR main | Task 6 |
| Shared rate limit + Redis optional | Task 3–4 |
| 503 `rate_limit_unavailable` when Redis configured but failing | Task 3–4 |
| No FAL_KEY in CI | Task 5 mocks |
| Docs for env | Task 7 |
| Phase B Swift deferred | Phase B section |

---

**Plan complete and saved to `docs/superpowers/plans/2026-04-10-hardening-milestone.md`. Two execution options:**

**1. Subagent-Driven (recommended)** — Dispatch a fresh subagent per task, review between tasks, fast iteration.

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints.

**Which approach?**
