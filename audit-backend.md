# AdForge Backend Audit Report

**Date:** April 2026  
**Scope:** `/home/user/workspace/AdForge/backend/` — all files  
**References:** `ARCHITECTURE.md`, `AdForge_PRD_v2.md`, `@fal-ai/client` v1.5–1.6 SDK docs, Fal.ai model endpoint documentation  

---

## File-by-File Audit

---

### `backend/package.json`

**Status: COMPLETE**

| Item | Finding |
|------|---------|
| `@fal-ai/client` version | Pinned to `^1.5.0`. Current latest is `1.6.2`. The `^` semver range means `1.6.x` will be installed, which is fine — no breaking changes between 1.5 and 1.6. |
| TypeScript | `^5.7.0` — correct for strict mode + `verbatimModuleSyntax`-ready projects. |
| Node engine | `>=20.0.0` — appropriate for Vercel Edge. |
| Scripts | `dev`, `deploy`, `typecheck` all present. No `lint` or `test` scripts. |

**Issues:**

1. No test script and no test framework installed. There are zero unit tests for prompt-checker logic, model routing, or rate limiting — dangerous for safety-critical code.
2. No linting (eslint). With strict TypeScript this is acceptable but not ideal.
3. `"private": true` is set correctly — prevents accidental npm publish of the API key.

---

### `backend/tsconfig.json`

**Status: COMPLETE**

The TypeScript config is unusually strict and well-configured:
- `strict: true`, `noUncheckedIndexedAccess: true`, `exactOptionalPropertyTypes: true`, `noImplicitOverride: true`, `noPropertyAccessFromIndexSignature: true` — all enabled.
- `resolveJsonModule: true` — required for `import blocklist from "./blocklist.json"`.
- `esModuleInterop: true` — required for `import * as fal from "@fal-ai/client"`.
- `module: "NodeNext"` + `moduleResolution: "NodeNext"` — correct for Vercel Edge.

**Issues:**

1. **`lib: ["ES2022"]` is missing `"DOM"`** — Edge functions run in a Fetch API environment, not a browser DOM, but `Request`, `Response`, `Headers`, and `URL` are Web API globals that TypeScript needs type definitions for. Without `"lib": ["ES2022"]` including WebWorker or similar, these globals are untyped. The handlers use `Request` and `Response` directly. This will produce TypeScript errors: `Cannot find name 'Request'`, `Cannot find name 'Response'`. The correct lib should be `["ES2022", "WebWorker"]` or you need `@cloudflare/workers-types` / `@vercel/edge` types installed. **This will fail `tsc --noEmit` right now.**
2. `outDir: "./.vercel/output"` — Vercel Edge does not use a TypeScript compilation step this way; Vercel compiles internally. The outDir will never be used by the deploy pipeline and is misleading.
3. `verbatimModuleSyntax: false` — acceptable, but with `esModuleInterop: true` and `NodeNext` modules, setting this to `true` is the modern recommendation for catching import-type issues.

---

### `backend/vercel.json`

**Status: PARTIAL — has a critical routing bug**

**Issues:**

1. **OPTIONS preflight requests are routed to `/api/health` (line 22–25):**
   ```json
   {
     "src": "/api/(.*)",
     "methods": ["OPTIONS"],
     "dest": "/api/health"
   }
   ```
   This means any `OPTIONS` preflight to `/api/generate-image`, `/api/generate-video`, or `/api/check-prompt` is forwarded to the health endpoint, not the actual handler. The individual handlers do have their own `OPTIONS` logic, but they will never be reached for preflight requests — they'll all hit `/api/health` instead. This could break CORS preflight in certain configurations. For an iOS URLSession client, this typically isn't a problem (iOS doesn't send CORS preflights), but it will break any web-based client or API testing tool. The `continue: true` route at the top does add CORS headers inline, but the OPTIONS→health redirect is still architecturally wrong.

2. **Double CORS header definition:** CORS headers are defined in both the `routes[0]` entry (using `"headers"` on a route with `"continue": true`) and in the top-level `"headers"` array. This duplication can cause header doubling in some Vercel versions, resulting in `Access-Control-Allow-Origin: *, *` which some clients reject.

3. **`framework: null`** — correct for a pure API project without a frontend framework.

4. **`"runtime": "edge"` in `functions`** — overriding via `export const config = { runtime: "edge" }` in each file is redundant but harmless; Vercel picks one.

5. Missing route for `DELETE`, `PUT` — these will 404 rather than 405. Low priority since the API only uses GET/POST.

---

### `backend/.env.example`

**Status: COMPLETE**

Only two environment variables documented. File is correct and does not commit secrets. No issues beyond what's noted in the README.

---

### `backend/README.md`

**Status: COMPLETE**

Clear, correct documentation. The model routing table and rate limiting caveat are accurate. Minor: the README says the blocklist has "65+ blocked words/phrases" — the actual `terms` array has 68 entries, and "50 public figures" — the actual `celebrity_names` array has 50 entries. Both are approximately correct.

---

### `backend/lib/blocklist.json`

**Status: PARTIAL — meaningful gaps (see Security Assessment)**

**Issues:**

1. **Celebrity name matching is case-sensitive substring only** — the `prompt-checker.ts` lowercases the prompt before matching terms, but celebrity names are stored in PascalCase and compared via `lower.includes(name.toLowerCase())`. This is correct. However, there is no normalization of Unicode — `Beyoncé` in the list will not match `Beyonce` (no accent) or `Beyoncé` with a different Unicode encoding. This is a real bypass vector.

2. **No first-name-only blocking for high-risk celebrities** — a user can type "naked Billie" without the surname and bypass the list. This is a design tradeoff but creates a meaningful gap.

3. **`"Drake"` is blocked as a celebrity name** — this is a false positive risk. "Drake" is an extremely common English word (a male duck, a surname). A prompt like "a drake duck swimming in a lake" will be blocked with `reason: "public_figure_not_allowed"`. This will cause user frustration and false positives in nature/wildlife prompts.

4. **`"nigger"` and `"nigga explicit"` in `terms`** — the term `"nigga explicit"` requires the word "explicit" to appear adjacently. The bare slur without "explicit" is only caught by the regex pattern (which works). The term entry itself (`"nigga explicit"`) is overly specific — it should just be `"nigga"` or rely solely on the regex. As written, `"what a nigga like me do"` would be blocked by regex but `"nigga"` alone as a standalone term might pass the `terms` array check while relying entirely on the regex.

5. **`"faggot slur"` requires the word "slur" to appear** — same issue. The term `"faggot slur"` only matches if both words appear together. The standalone slur is caught by regex, but the terms entry is misleadingly specific.

6. **`"kike slur"`, `"spic slur"`, `"chink slur"`, `"coon slur"`, `"tranny slur explicit"`, `"gook slur"`** — all have the same "requires qualifying word" problem as above. These are effectively dead entries, relying entirely on the regex patterns to block the actual slurs.

7. **Regex pattern 5 (`\b(f[a@4][g*][g*][o0]t|f[a@4]g)\b`) is overly broad** — the second alternative `f[a@4]g` will match "fag" as a standalone word, which has common non-slur uses (British slang for cigarette, "faggot" in cooking). This could create false positives in UK English prompts. Medium risk.

8. **No blocklist entries for sexual content terms** — the blocklist focuses on CSAM, extreme violence, slurs, and named public figures. General explicit sexual content terms (e.g., "sex scene," "nude model," "erotic") are entirely absent from `terms`. The model's built-in safety filter is the first and presumably adequate line of defense (per PRD Layer 1), but there is no redundant server-side catch for explicit adult content that falls short of CSAM.

9. **No version or timestamp on the blocklist** — there is no way to audit when terms were added or removed. A `_meta` field with a version string and last-updated date would help with compliance and maintenance.

---

### `backend/lib/prompt-checker.ts`

**Status: COMPLETE — minor issues**

**Issues:**

1. **`import blocklist from "./blocklist.json" assert { type: "json" }`** — the `assert` syntax is deprecated in Node 22+ in favor of `with { type: "json" }`. With `module: "NodeNext"` in tsconfig and Node ≥20, this will emit a deprecation warning at runtime and may break in a future Node version. The correct syntax is:
   ```ts
   import blocklist from "./blocklist.json" with { type: "json" };
   ```
   This is a correctness issue in strict TypeScript + Node 22 environments.

2. **Pre-compilation of regex patterns at module load time** — this is correct and performant. The `pattern.lastIndex = 0` reset before each `.test()` call is also correct for global regexes. Good implementation.

3. **`checkPrompt` returns `{ safe: false, reason: "empty_prompt" }` for empty strings** — this reason leaks internal state to the API consumer. The generate-image handler will forward `reason: "empty_prompt"` to the iOS client in the `400` response body. The architecture spec says "no explanation" should be surfaced. However, empty prompts are already caught by input validation before `checkPrompt` is called in the API handlers, so this code path is unreachable in practice. Low risk but incorrect design.

4. **No maximum prompt length guard inside `checkPrompt` itself** — the function trusts callers to enforce the 2000-char limit. This is fine given the handlers validate first, but a defensive guard would be good practice for a shared utility.

5. **TypeScript cast `(blocklist.terms as string[])` and similar** — because `resolveJsonModule: true` is set, TypeScript infers the blocklist type from the JSON structure. The casts may be unnecessary if TypeScript can infer the types, or they may be required if TypeScript infers `readonly string[]` vs `string[]`. With `noUncheckedIndexedAccess: true` and `exactOptionalPropertyTypes: true`, this area could produce subtle type errors. Needs `tsc --noEmit` to confirm.

---

### `backend/lib/fal-client.ts`

**Status: PARTIAL — critical API compatibility issues**

This is the highest-risk file in the codebase. Multiple issues.

**Issue 1 — CRITICAL: Wrong import style for `@fal-ai/client`**

The code uses:
```ts
import * as fal from "@fal-ai/client";
```
Then calls `fal.config(...)` and `fal.subscribe(...)`.

The `@fal-ai/client` package exports a named `fal` instance, not a namespace:
```ts
import { fal } from "@fal-ai/client";
```
The `import * as fal` style may work at runtime due to `esModuleInterop: true` treating the default export as the namespace, but it is incorrect per the package's TypeScript types and the official documentation (every Fal.ai code example uses `import { fal } from "@fal-ai/client"`). With strict TypeScript, `import * as fal` will see the module namespace object, not the `fal` client instance. `fal.config` and `fal.subscribe` would be `undefined` on the namespace, causing a **runtime crash** on every request. This is the single most critical bug in the codebase.

**Issue 2 — CRITICAL: `fal.subscribe()` return type is `{ data: T, requestId: string }`, not `T`**

The code casts the result as `{ data: FalImageOutput }`:
```ts
result = (await fal.subscribe(endpoint, { ... })) as { data: FalImageOutput };
```
Then accesses `result.data.images?.[0]?.url`.

Per the official Fal.ai TypeScript API reference ([fal.ai/docs/api-reference/client-libraries/javascript/types.common](https://fal.ai/docs/api-reference/client-libraries/javascript/types.common)):
```ts
type Result<T> = {
  data: T;
  requestId: string;
}
```
The `{ data: T }` wrapping is **correct** — `subscribe()` does return `{ data, requestId }`, not the raw output. So `result.data.images` is the right access path. The cast is technically correct in structure but uses a manual type assertion instead of proper generics. However, accessing `result.data.images?.[0]?.url` is valid.

But: because of Issue 1 (wrong import), this code never executes correctly anyway.

**Issue 3 — CRITICAL: Wrong Wan 2.5 endpoint ID**

The code maps:
```ts
"wan-2.5": "fal-ai/wan/v2.5",
```

The actual Fal.ai endpoint for Wan 2.5 text-to-video is:
```
fal-ai/wan-25-preview/text-to-video
```
(confirmed at [fal.ai/models/fal-ai/wan-25-preview/text-to-video/api](https://fal.ai/models/fal-ai/wan-25-preview/text-to-video/api))

The endpoint `fal-ai/wan/v2.5` does not exist on Fal.ai. Every video generation request will return a 404 or model-not-found error from Fal.ai. **Video generation is completely broken.**

**Issue 4 — WRONG: Flux Pro endpoint may be outdated**

The code maps:
```ts
"flux-2-pro": "fal-ai/flux-pro/v1.1",
```

The endpoint `fal-ai/flux-pro/v1.1` does exist on Fal.ai and is active. However, the architecture spec calls the model `"flux-2-pro"` (implying Flux 2 / the second generation), while `fal-ai/flux-pro/v1.1` is "FLUX Pro 1.1" — not Flux 2. Fal.ai's actual "Flux 2 Pro" (if it exists by 2026) would be a different endpoint. As of the current documentation, `fal-ai/flux-pro/v1.1` is the latest v1 series. This may be intentional naming confusion in the PRD/spec, or it may be wrong. If Fal.ai has released a Flux 2 Pro model by 2026, this endpoint will be outdated.

**Issue 5 — Wrong parameters sent to Wan 2.5**

The video generation code sends:
```ts
input: {
  prompt,
  num_frames: 81,
  resolution: "480p",
  aspect_ratio: "16:9",
},
```

Per Fal.ai's Wan 2.5 schema:
- `num_frames` is **not an input parameter** for `fal-ai/wan-25-preview/text-to-video`. The input schema only accepts `prompt`, `audio_url`, `aspect_ratio`, `resolution`, `duration`, `negative_prompt`, `enable_prompt_expansion`, `seed`, `enable_safety_checker`. Sending `num_frames` as input will either be silently ignored or cause a validation error.
- `resolution: "480p"` — valid, but the default is `"1080p"`. Generating at 480p is low quality for a product claiming 720p output (the PRD specifies "MP4, 5 seconds, 720p"). This should be `"720p"` at minimum.

**Issue 6 — pollInterval parameter likely unsupported**

The code passes:
```ts
pollInterval: 3000,
```
to `fal.subscribe()`. The `@fal-ai/client` `subscribe()` options type does not document a `pollInterval` parameter in any official reference. This will be silently ignored (TypeScript will flag it as an unknown property with strict types, or the `as { data: FalVideoOutput }` cast hides the error). The default polling interval is used instead.

**Issue 7 — `_initialized` guard fails in Edge function environment**

The `initFal()` function uses a module-level `_initialized` flag:
```ts
let _initialized = false;

export function initFal(): void {
  if (_initialized) return;
  // ...
  _initialized = true;
}
```

In Vercel Edge Functions, module-level state does not persist between invocations. Each cold start re-evaluates the module, so `_initialized` is always `false` on a cold start. This means `fal.config()` is called on every cold-start invocation — which is correct behavior. The optimization only helps within a single warm execution context. This is not a bug, but the comment claiming it runs "only once" is misleading in a serverless context.

More importantly: `fal.config()` being called correctly will re-configure the client with the same key on every warm invocation — this is harmless but wasteful.

**Issue 8 — `output_format: "jpeg"` vs. spec requirement**

The generate-image call specifies `output_format: "jpeg"`. The architecture spec (ARCHITECTURE.md) says: "Output: PNG, minimum 1024x1024." The PRD says "PNG, minimum 1024x1024." The backend sends JPEG at `landscape_4_3` (1:1.33 ratio, likely 1024×768 or similar). This contradicts both the architecture spec and PRD's output format requirement.

**Issue 9 — `image_size: "landscape_4_3"` doesn't meet spec**

The PRD and architecture spec require "minimum 1024×1024." The `landscape_4_3` preset is 1024×768 (portrait-width = 1024, landscape height = 768) — this is below the minimum height requirement of 1024px. The correct preset for square 1024×1024 output would be `"square_hd"` or `"square"`.

**Issue 10 — No timeout on `fal.subscribe()` calls**

There is no timeout configured for the Fal.ai API calls. If Fal.ai is slow or unresponsive, the edge function will hang until Vercel's platform-level timeout kills it (30 seconds by default for Edge Functions on the free tier). For video generation, which the comment itself acknowledges can take 30–120 seconds, this means video generation will **always time out on free/hobby Vercel plans**. The `maxDuration` is commented out in the config export.

---

### `backend/api/generate-image.ts`

**Status: PARTIAL — functional logic correct, inherits fal-client bugs**

**Issues:**

1. **Rate limiter is broken in serverless Edge runtime** — see Security Assessment. This is the most important systemic issue.

2. **`userId` is accepted but never authenticated** — the endpoint accepts `{ prompt, model, userId }` but never verifies that the `userId` corresponds to a valid Firebase Auth session. Any caller can supply any userId string. The rate limiter is IP-based, not user-based, so a user on a cellular network could spoof userId to appear as any user. There is no Firebase JWT verification anywhere in the backend. This means the backend has no authentication — it's an open proxy to Fal.ai for anyone who discovers the URL.

3. **405 response for non-POST methods missing CORS headers** — line 102:
   ```ts
   return json({ error: "method_not_allowed" }, 405);
   ```
   This uses the `json()` helper which does include `CORS_HEADERS`. Actually this is fine — the helper always adds CORS headers. No issue here.

4. **Error message leakage** — on generation failure, the raw error message from Fal.ai is returned in the 500 response:
   ```ts
   return json({ error: "generation_failed", message }, 500);
   ```
   Fal.ai error messages may include internal details like rate limit counts, endpoint URIs, or model configuration details. These should be sanitized before returning to the client.

5. **Response shape mismatch vs. spec** — the architecture spec says the response should be `{ imageURL, thumbnailURL }`. The backend returns `{ imageURL, model, prompt }` — there is no `thumbnailURL` field. The iOS client's `GenerationService.generateImage()` likely expects `thumbnailURL` (or at least the architecture specifies it). This is a contract violation.

6. **`userId` sent as substring in logs** — `userId.toString().substring(0, 8)` is a reasonable privacy practice. OK.

7. **No request body size limit** — while a 2000-char prompt limit is enforced, there is no guard against an attacker sending a 50MB JSON body to exhaust memory. Vercel Edge has a 4MB request body limit by default, so this is mitigated at the platform level, but explicit validation is better practice.

---

### `backend/api/generate-video.ts`

**Status: PARTIAL — same issues as generate-image, plus video-specific problems**

**Issues:**

1. All issues from `generate-image.ts` apply (rate limiter broken, no auth, response shape mismatch, error leakage).

2. **`maxDuration` is commented out** — line 31:
   ```ts
   // maxDuration: 300,
   ```
   Video generation takes 30–120+ seconds. With the default 30-second Edge Function timeout on Vercel's hobby plan, every video generation will time out. Even with `maxDuration: 300` (5 minutes), you need a Vercel Pro or Enterprise plan. This will cause 100% failure rate for video generation in production on the default plan. The TODO comment acknowledges this but leaves the fix commented out.

3. **Response shape mismatch** — spec says `{ videoURL, thumbnailURL }`, backend returns `{ videoURL, model, prompt }`. No `thumbnailURL`.

4. **Same broken Wan 2.5 endpoint** — inherited from fal-client.ts.

---

### `backend/api/check-prompt.ts`

**Status: COMPLETE — well-implemented**

This is the cleanest file in the backend. Issues are minor:

1. **No rate limiting on check-prompt** — the README acknowledges this intentionally: "The check-prompt endpoint is not rate-limited." However, an attacker can use this endpoint as an oracle to enumerate the blocklist — repeatedly querying with slight variations to reverse-engineer which terms are blocked. The spec says "no explanation of why — this prevents users from reverse-engineering the blocklist," but the boolean `safe: false` response itself is still an oracle. Rate limiting this endpoint (even at a higher limit like 200/hour) would reduce oracle attacks.

2. **Returns `reason` field when `safe: false`** — the response is `{ safe: false, reason: "prohibited_content" }` or `{ safe: false, reason: "public_figure_not_allowed" }`. The reason `"public_figure_not_allowed"` reveals that the blocklist has a celebrity category, helping an attacker understand the blocklist structure. Per the PRD: "Generic refusal, no explanation." Only `{ safe: false }` should be returned. The `reason` field should be dropped entirely from the API response (it can remain internal for logging).

3. The CORS headers on `check-prompt.ts` include `"X-User-Id"` in the generate handlers but not in this handler's `CORS_HEADERS`. This is actually correct since check-prompt doesn't use `X-User-Id`, but it's inconsistent.

---

### `backend/api/health.ts`

**Status: COMPLETE**

No issues. Clean implementation. `Cache-Control: no-store` is correct for a health endpoint.

---

## Security Assessment

### Rate Limiter Effectiveness

**Rating: INEFFECTIVE in production**

The rate limiter in `generate-image.ts` and `generate-video.ts` uses a module-level `Map`:
```ts
const rateLimitMap = new Map<string, RateLimitEntry>();
```

**This is completely broken in Vercel Edge Functions.** Each Edge Function invocation runs in an isolated V8 isolate. Module-level state (the `rateLimitMap`) is **not shared between concurrent invocations** or even between sequential invocations on different physical edge nodes. At Vercel's global scale, there are hundreds of edge locations — each maintains its own independent `rateLimitMap`. A single user can exceed the intended limit by simply making requests to different geographic Vercel edge regions.

Even within a single edge node, Vercel's Edge Runtime does not guarantee module-level state persistence between invocations. The isolate may be recycled at any time.

**The rate limiter provides no meaningful protection in production.** The code acknowledges this with a TODO comment ("Replace with Redis (Upstash) for multi-instance production use"), but the acknowledgment in comments is not enough — at launch this must be addressed.

**Bypass vectors:**
- Use a VPN/proxy to rotate IP addresses — bypasses the IP-based check.
- Make requests to different Vercel regions — each region has its own (empty) rate limit map.
- The rate limiter resets on every cold start — attack during cold starts.
- `RATE_LIMIT_ENABLED` can be set to `"false"` — if an attacker can influence environment variables (e.g., via a misconfigured CI/CD), rate limiting is disabled entirely.
- The `x-forwarded-for` header is trusted without validation — a proxy can spoof it: `X-Forwarded-For: 1.2.3.4, known_safe_ip`. The code takes `split(",")[0].trim()`, trusting the leftmost IP. Vercel sets this header, but if Vercel ever passes through a user-supplied `X-Forwarded-For`, the IP can be spoofed.

**At `"unknown"` IP:** If both `x-forwarded-for` and `x-real-ip` are absent, all requests fall into the same `"unknown"` bucket. This means all anonymous/proxied requests share a single 50-request bucket — effectively a shared quota among all users hiding their IP, which an attacker could exhaust to DoS legitimate users.

### Blocklist Coverage and False Positive Risk

**CSAM coverage:** The CSAM section of `terms` is reasonable for obvious attempts. The regex patterns add leet-speak coverage. Key gap: the blocklist does not block `"8-year-old"`, `"7-year-old"` etc. (age-specified children with no explicit modifier), nor `"young girl/boy nude"` or `"shota"` variations beyond `"shotacon"`. Determined bad actors will find variants.

**False positive risk: MODERATE**

- `"Drake"` → blocks duck-related prompts ("a drake duck", "Drake Bay landscape")
- `"Bill Gates"` → unambiguous, low false positive risk
- `"Kim Jong Un"` → unambiguous
- `f[a@4]g` regex → can match "fag" in UK English cigarette context
- `"suicide method"` → this term requires all three words. A prompt saying "how to end your life" is not caught.
- `"drug synthesis"` → could catch a legitimate chemistry prompt about "drug synthesis in pharmaceutical research"
- `"nerve agent synthesis"` → correct to block, but `"nerve agent"` alone is not blocked (chemistry students discussing nerve agents for educational context)

**Verdict:** The blocklist is adequate for obvious bad-faith attempts but has meaningful gaps for sophisticated evasion. It will produce occasional false positives that frustrate legitimate users (Drake duck prompts being the clearest example).

### API Key Protection

**Rating: ADEQUATE**

The `FAL_KEY` is correctly stored as a Vercel environment variable and accessed via `process.env["FAL_KEY"]`. It is never logged, never returned in responses, and never included in client-side code. The key is only used server-side in `fal-client.ts`.

**Gap:** There is no validation that `FAL_KEY` is set at server startup — it is only validated when the first generation request arrives. If `FAL_KEY` is missing, the first user's request will fail with a 500. A health check that validates `FAL_KEY` at startup would catch misconfiguration earlier. The `/api/health` endpoint does not check whether the Fal.ai key is set.

**Gap:** The backend has no authentication mechanism. Anyone who knows the Vercel deployment URL can call the API without any credentials. This is an **open proxy** to Fal.ai. The `userId` parameter is accepted but never verified. An attacker who discovers the backend URL can consume unlimited Fal.ai API credits (limited only by the broken rate limiter). This is a potentially severe financial risk.

### Input Validation Gaps

1. **No validation that `model` is an allowed value before passing to fal-client** — the handlers check that `model` is a non-empty string, but any string is accepted. Garbage model IDs like `"../../../../etc/passwd"` are passed to `fal.subscribe()`. The fal-client does validate model against its known map and throws an error, but the validation happens deep in the call chain rather than at the API boundary.

2. **Prompt injection into Fal.ai:** The prompt is passed directly to Fal.ai after blocklist checking. There is no sanitization of special characters (backticks, JSON-like strings, etc.). Fal.ai's API accepts the prompt as a JSON string field, so this is not a traditional injection vector — but if Fal.ai ever does prompt expansion or system-prompt injection via special characters, this could be a risk.

3. **No validation of prompt encoding** — a prompt containing null bytes (`\u0000`) or right-to-left override characters could bypass the blocklist substring check (which operates on a simple `lower.includes()` without normalization). Example: inserting a zero-width space between characters could evade the regex patterns.

---

## Scalability Concerns

### What Breaks at 1k/10k/100k Requests Per Day

**At 1k requests/day (~0.01 req/s average):**
- The broken rate limiter is functionally irrelevant — it won't fill up meaningfully.
- The in-memory `rateLimitMap` fits easily in memory.
- Cold starts are frequent at this volume; `_initialized = false` on every cold start is benign.
- Everything mostly works except the broken endpoint IDs and import style.

**At 10k requests/day (~0.12 req/s average):**
- Rate limiter still technically "works" within a single region but provides no cross-region protection.
- `rateLimitMap` cleanup is triggered at 10,000 entries — at this scale this loop runs frequently:
  ```ts
  if (rateLimitMap.size > 10_000) {
    for (const [key, val] of rateLimitMap) {
      if (val.timestamps.every(...)) rateLimitMap.delete(key);
    }
  }
  ```
  The eviction iterates the entire map synchronously, which blocks the event loop. For a map with 10,001 entries, this is microseconds — acceptable.
- Edge function cold start time increases because the blocklist JSON is imported at module load time; 3,294 bytes is trivial.

**At 100k requests/day (~1.2 req/s average):**
- Rate limiting is completely ineffective across the Vercel global edge network.
- The `rateLimitMap` grows to 10,000 entries quickly and the eviction loop runs on nearly every request — linear scan of 10k entries, synchronous. On a hot path this could add 1–5ms of latency per request at this scale.
- **Memory leak:** The map cleanup only triggers when `size > 10_000`. With 10k unique IPs, each having up to 50 timestamp entries (50 × 8 bytes = 400 bytes per IP), the map uses ~4MB maximum before eviction. This is within Edge Function memory limits (128MB typically), but the eviction strategy has a flaw: `val.timestamps.every(t => now - t >= RATE_LIMIT_WINDOW_MS)` only evicts entries where ALL timestamps are expired. An IP that makes one request per hour will never be evicted (it always has one fresh timestamp). This is a slow leak.
- Fal.ai rate limits may kick in at this scale — the backend has no retry logic or circuit breaker beyond the PRD's "cost circuit breaker" (which is not implemented in the backend code at all).
- Video generation at 100k requests/day with Edge Function 30-second timeouts = near-total video generation failure.

**Cost projection at 100k requests/day (all images, Flux Dev):**
- 100k × $0.025 = $2,500/day = $75,000/month in Fal.ai costs
- At $14 eCPM with 4 ads/DAU: requires ~18k DAU to cover costs
- The PRD's cost circuit breaker is described but **not implemented** in this backend code.

### Edge Function Limitations

1. **30-second default timeout kills video generation.** Even on Vercel Pro (900s max), `fal.subscribe()` has no timeout — it will hold the connection for the full generation duration, tying up edge resources.

2. **No streaming support.** Clients must wait for the full generation to complete with no progress indication. The `onQueueUpdate` callback in `fal.subscribe()` could be used to stream progress to the client, but this is not implemented.

3. **No webhook/async pattern.** For video generation (30–120 seconds), the Edge Function holds an open connection. This is expensive in terms of concurrency slots. A better architecture would be: iOS app submits → backend returns a `requestId` → iOS polls a separate `/api/generation-status/:id` endpoint. This pattern is not implemented.

4. **Process isolation means no shared Fal.ai connection pooling.** Each invocation creates a fresh HTTP connection to Fal.ai. At scale, connection overhead adds latency.

---

## API Compatibility

### iOS Client Expected vs. Backend Actual

Based on the architecture spec's `GenerationService` definition and the iOS models:

| Dimension | iOS Client Expects | Backend Returns | Match? |
|-----------|--------------------|-----------------|--------|
| Image success response | `{ imageURL, thumbnailURL }` | `{ imageURL, model, prompt }` | **NO** — `thumbnailURL` is missing |
| Video success response | `{ videoURL, thumbnailURL }` | `{ videoURL, model, prompt }` | **NO** — `thumbnailURL` is missing |
| Prompt check response | `{ safe: boolean }` | `{ safe: bool }` or `{ safe: false, reason: string }` | **Partial** — extra `reason` field (harmless for Swift Codable if optional) |
| Error response | Not specified in spec | `{ error: string, message: string }` | Inconsistent — check-prompt returns `{ error: "invalid_request", message }` while generate handlers also return `{ error: "prompt_blocked", reason }` (note: `reason`, not `message`) |
| Rate limit error | Not specified | `{ error: "rate_limit_exceeded", message, retryAfter }` + `Retry-After` header | Reasonable, but iOS client must handle 429 |
| Image URL format | Cloudinary URL (per PRD) | Direct Fal.ai CDN URL | **Mismatch** — the PRD and spec say media is stored on Cloudinary. The backend returns the raw Fal.ai CDN URL with no Cloudinary upload step. Fal.ai CDN URLs have a TTL (typically 1 hour to 24 hours) and will become dead links. The Cloudinary upload pipeline is **entirely missing**. |

**Cloudinary upload gap — CRITICAL:** The architecture spec says `mediaURL` is a "Cloudinary URL" and the PRD specifies "Cloudinary or Supabase Storage (temporary, 30-day TTL on generated media)." The backend returns the raw Fal.ai CDN URL directly. Fal.ai CDN links expire — typically within hours to a few days. All generated media URLs stored in Firestore will become dead links. The feed will show broken images. This is a complete omission of a required pipeline stage.

**CORS for iOS:** iOS native URLSession does not send CORS preflight requests (`OPTIONS`) — CORS is a browser security mechanism. The CORS headers are therefore irrelevant for iOS clients but don't cause harm. However, the wildcard `Access-Control-Allow-Origin: *` is correct for any future web dashboard.

**Content-Type header:** `CORS_HEADERS` always sets `Content-Type: application/json` as part of the CORS headers object. This is correct for JSON API responses. OK.

**Authentication header:** The iOS client is expected to send `Authorization` or `X-User-Id` headers (both are in `Access-Control-Allow-Headers`), but the backend never reads or validates them. The `X-User-Id` header is ignored entirely.

---

## Summary

### Critical Issues (Will Break in Production)

1. **Wrong `fal` import style** — `import * as fal from "@fal-ai/client"` should be `import { fal } from "@fal-ai/client"`. With `esModuleInterop: true` this may work at runtime in some environments but is semantically wrong and will fail with strict TypeScript checking. In the Edge runtime it may cause `fal.config is not a function`. **Every generation request will fail at runtime.**

2. **Wrong Wan 2.5 endpoint** — `"fal-ai/wan/v2.5"` does not exist on Fal.ai. The correct endpoint is `"fal-ai/wan-25-preview/text-to-video"`. **Video generation is 100% broken.**

3. **Rate limiter is broken in Vercel Edge** — module-level `Map` state is not shared across isolates. The rate limiter provides zero cross-region protection. The backend is effectively unprotected against abuse at scale.

4. **No authentication** — `userId` is accepted but never verified against Firebase Auth. The backend is an open, unauthenticated proxy to Fal.ai. Any person who discovers the Vercel URL can consume Fal.ai API credits with no limit.

5. **Cloudinary upload pipeline is missing** — the backend returns raw Fal.ai CDN URLs that expire within hours. All media stored in Firestore will become dead links. Feed content will break. This is a fundamental architecture gap.

6. **Video generation always times out** — `maxDuration` is commented out; Edge Functions default to 30 seconds. Video generation takes 30–120 seconds. Every video generation call will time out in production.

7. **TypeScript compilation fails** — `tsconfig.json` does not include `"WebWorker"` in the `lib` array. `Request` and `Response` global types are unavailable. `tsc --noEmit` will fail with "Cannot find name 'Request'" across all handler files.

8. **Image output format violates spec** — backend generates JPEG at `landscape_4_3` (1024×768). Spec requires PNG at minimum 1024×1024. Wrong format and undersized.

### Non-Critical Issues (Improvements / Optimizations)

1. **`thumbnailURL` missing from responses** — spec defines it, backend omits it. iOS client will receive `nil` for `thumbnailURL` on every generation.

2. **`reason` field in `check-prompt` and `prompt_blocked` responses leaks blocklist structure** — PRD says no explanation should be given. Remove `reason` from API responses.

3. **`import blocklist from "./blocklist.json" assert { type: "json" }`** — deprecated `assert` syntax; should be `with { type: "json" }`.

4. **`pollInterval` in `fal.subscribe()` is an unknown parameter** — silently ignored but incorrect.

5. **`resolution: "480p"` for video** — PRD specifies 720p. Should be `"720p"` minimum.

6. **`num_frames` is not a valid Wan 2.5 input parameter** — silently ignored by Fal.ai.

7. **No Fal.ai call timeout** — unresponsive Fal.ai will hang the edge function until platform timeout.

8. **`Drake` blocks legitimate nature prompts** — false positive in celebrity blocklist.

9. **Several slur terms require qualifying words** (`"faggot slur"`, `"kike slur"` etc.) — effectively dead term entries; relies entirely on regex.

10. **`error_message` from Fal.ai exposed in 500 responses** — internal error details leaked to clients.

11. **No cost circuit breaker implemented** — PRD describes an automatic throttle when AI costs exceed 30% of revenue. This is entirely absent from the backend.

12. **Vercel OPTIONS routing bug** — all OPTIONS requests are routed to `/api/health` instead of the target handler. Breaks browser-based API testing; harmless for iOS.

13. **Double CORS header definitions** in `vercel.json` — potential header doubling.

14. **No PhotoDNA / CSAM hash-matching** — PRD calls this "non-negotiable" and required at MVP. The backend has no integration with any perceptual hash database. This is a legal compliance gap (18 U.S.C. § 2258A).

15. **No `_initialized` guard meaningful in Edge** — comment claims it runs "only once" but it resets on every cold start. Misleading.

16. **Health endpoint doesn't validate `FAL_KEY`** — a missing key is only discovered on the first real request.

17. **Zero tests** — safety-critical blocklist matching has no unit tests. A broken regex could silently stop blocking CSAM-adjacent content.

### Missing Features vs. Spec

| Spec Requirement | Implementation Status |
|------------------|-----------------------|
| `POST /api/generate-image` | Present but broken (wrong import, wrong output format, missing Cloudinary) |
| `POST /api/generate-video` | Present but broken (wrong import, wrong endpoint, timeouts) |
| `POST /api/check-prompt` | Present and mostly correct |
| `GET /api/health` | Present and correct |
| Blocklist updatable without app update | Implemented (JSON file) |
| Rate limiting | Implemented but broken in Edge |
| `thumbnailURL` in responses | Missing entirely |
| Cloudinary upload pipeline | Not implemented |
| Cost circuit breaker | Not implemented |
| PhotoDNA / CSAM hash matching | Not implemented (legal requirement per PRD) |
| Firebase Auth token verification | Not implemented |
| User-based rate limiting (not just IP) | Not implemented |
| Velocity checks (>50 items/day flagging) | Not implemented |
