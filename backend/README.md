# AdForge Backend

Vercel Edge Functions proxy between the AdForge iOS app and the Fal.ai AI generation API. Handles prompt safety checking, model routing, and rate limiting.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/health` | Health check |
| `POST` | `/api/check-prompt` | Safety-check a prompt before generation |
| `POST` | `/api/generate-image` | Generate an AI image |
| `POST` | `/api/generate-video` | Generate an AI video |

## Setup

### 1. Install dependencies

```bash
cd backend
npm install
```

### 2. Configure environment variables

```bash
cp .env.example .env.local
```

Open `.env.local` and set your Fal.ai API key:

```
FAL_KEY=your_fal_ai_api_key_here
```

Get a Fal.ai key at [fal.ai/dashboard/keys](https://fal.ai/dashboard/keys).

### 3. Run locally

```bash
npm run dev
```

This starts a local Vercel dev server at `http://localhost:3000`. All edge functions are available at their `/api/*` paths.

### 4. Deploy to production

```bash
npm run deploy
```

This runs `vercel --prod`, which builds and deploys to your Vercel project. The live URL will be printed on completion.

> **First deploy?** Run `vercel login` first, then `vercel link` to connect to your project.

## Environment Variables (Vercel)

Set these in your Vercel project dashboard under **Settings → Environment Variables**:

| Variable | Description | Required |
|----------|-------------|----------|
| `FAL_KEY` | Fal.ai API key | Yes |
| `RATE_LIMIT_ENABLED` | Enable IP rate limiting (`true`/`false`) | No (default: `true`) |

## Architecture

```
iOS App
  └── POST /api/check-prompt   ──► lib/prompt-checker.ts ──► blocklist.json
  └── POST /api/generate-image ──► lib/prompt-checker.ts
                                ──► lib/fal-client.ts ──► fal-ai/flux-pro/v1.1
  └── POST /api/generate-video ──► lib/prompt-checker.ts
                                ──► lib/fal-client.ts ──► fal-ai/wan/v2.5
```

## Model Routing

| AdForge Model ID | Fal.ai Endpoint |
|-----------------|-----------------|
| `flux-2-pro` | `fal-ai/flux-pro/v1.1` |
| `flux-2-dev` | `fal-ai/flux/dev` |
| `wan-2.5` | `fal-ai/wan/v2.5` |

## Rate Limiting

By default, each IP address is limited to **50 requests per hour** across image and video generation endpoints. The check-prompt endpoint is not rate-limited.

The current implementation uses an in-memory map (suitable for single-instance development and low-traffic production). For high-traffic production use, replace with a Redis-backed solution (e.g., [Upstash](https://upstash.com/)).

## Content Safety

Prompts are checked against `lib/blocklist.json` before any generation request is forwarded to Fal.ai. The blocklist covers:

- **terms** — 65+ blocked words/phrases (CSAM-adjacent content, extreme violence, slurs, deepfake patterns)
- **patterns** — 12 regex patterns to catch leet-speak and spacing-trick evasions
- **celebrity_names** — 50 public figures blocked to prevent deepfake generation

A blocked prompt returns HTTP 400 with `{ error: "prompt_blocked" }` — no explanation is surfaced to the client.
