/**
 * POST /api/generate-video
 *
 * Generates an AI video via Fal.ai after safety-checking the prompt.
 *
 * Request body: { prompt: string, model: string, userId: string }
 * Response:
 *   200 { videoURL: string, model: string, prompt: string }
 *   400 { error: "prompt_blocked", reason: string }
 *   400 { error: "invalid_request", message: string }
 *   429 { error: "rate_limit_exceeded", retryAfter: number }
 *   500 { error: "generation_failed", message: string }
 *
 * Edge function — runs at the CDN edge worldwide.
 *
 * Rate limiting: max 50 requests per IP per hour per route. Upstash Redis when
 * configured; otherwise in-memory. See generate-image.ts.
 *
 * Note: Video generation typically takes 30–120 seconds. The Edge Function
 * runtime has a maximum execution time of 30s by default. Vercel Pro/Enterprise
 * plans allow up to 900s for Edge Functions — ensure the project plan is
 * appropriate, or consider using a Serverless Function (not Edge) for video.
 */

import { checkPrompt } from "../lib/prompt-checker.js";
import { generateVideo } from "../lib/fal-client.js";
import { checkRateLimit } from "../lib/rate-limit.js";

export const config = {
  runtime: "edge",
  // Increase max duration if your Vercel plan supports it
  maxDuration: 300,
};

// ---------------------------------------------------------------------------
// CORS headers
// ---------------------------------------------------------------------------

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-User-Id",
  "Content-Type": "application/json",
};

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

export default async function handler(req: Request): Promise<Response> {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  // Rate limit check
  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ??
    req.headers.get("x-real-ip") ??
    "unknown";

  const rl = await checkRateLimit("video", ip);
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

  // Parse body
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return json(
      { error: "invalid_request", message: "Request body must be valid JSON." },
      400
    );
  }

  if (typeof body !== "object" || body === null) {
    return json(
      { error: "invalid_request", message: "Request body must be a JSON object." },
      400
    );
  }

  const { prompt, model, userId } = body as Record<string, unknown>;

  if (typeof prompt !== "string" || prompt.trim().length === 0) {
    return json(
      { error: "invalid_request", message: '"prompt" must be a non-empty string.' },
      400
    );
  }

  if (typeof model !== "string" || model.trim().length === 0) {
    return json(
      { error: "invalid_request", message: '"model" must be a non-empty string.' },
      400
    );
  }

  if (typeof userId !== "string" || userId.trim().length === 0) {
    return json(
      { error: "invalid_request", message: '"userId" must be a non-empty string.' },
      400
    );
  }

  const cleanPrompt = prompt.trim();

  if (cleanPrompt.length > 2000) {
    return json(
      {
        error: "invalid_request",
        message: "Prompt exceeds maximum length of 2000 characters.",
      },
      400
    );
  }

  // Safety check
  const safety = checkPrompt(cleanPrompt);
  if (!safety.safe) {
    return json(
      {
        error: "prompt_blocked",
        reason: safety.reason ?? "prohibited_content",
      },
      400
    );
  }

  // Generate video
  try {
    const result = await generateVideo(cleanPrompt, model.trim());

    return json(
      {
        videoURL: result.videoURL,
        thumbnailURL: result.videoURL,
        model: model.trim(),
        prompt: cleanPrompt,
      },
      200
    );
  } catch (err) {
    const message =
      err instanceof Error ? err.message : "Unexpected error during generation.";

    console.error("[generate-video] generation failed:", message, {
      model,
      userId: userId.toString().substring(0, 8),
    });

    if (
      message.includes("Unsupported video model") ||
      message.includes("rejected the request")
    ) {
      return json({ error: "invalid_request", message }, 400);
    }

    console.error("[generate-video] raw error:", message);
    return json({ error: "generation_failed", message: "Generation failed. Please try again." }, 500);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function json(
  data: unknown,
  status: number,
  extraHeaders?: Record<string, string>
): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS_HEADERS, ...extraHeaders },
  });
}
