/**
 * POST /api/check-prompt
 *
 * Checks a user prompt against AdForge's content blocklist.
 *
 * Request body: { prompt: string }
 * Response:
 *   200 { safe: true }
 *   200 { safe: false, reason: string }
 *   400 { error: "invalid_request", message: string }
 *   405 { error: "method_not_allowed" }
 *
 * Edge function — runs at the CDN edge worldwide.
 */

import { checkPrompt } from "../lib/prompt-checker.js";

export const config = {
  runtime: "edge",
};

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Content-Type": "application/json",
};

export default async function handler(req: Request): Promise<Response> {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  // Parse and validate body
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return json(
      { error: "invalid_request", message: "Request body must be valid JSON." },
      400
    );
  }

  if (
    typeof body !== "object" ||
    body === null ||
    !("prompt" in body) ||
    typeof (body as Record<string, unknown>)["prompt"] !== "string"
  ) {
    return json(
      {
        error: "invalid_request",
        message: 'Request body must include a "prompt" string field.',
      },
      400
    );
  }

  const prompt = ((body as Record<string, unknown>)["prompt"] as string).trim();

  if (prompt.length === 0) {
    return json(
      { error: "invalid_request", message: "Prompt must not be empty." },
      400
    );
  }

  if (prompt.length > 2000) {
    return json(
      {
        error: "invalid_request",
        message: "Prompt exceeds maximum length of 2000 characters.",
      },
      400
    );
  }

  const result = checkPrompt(prompt);

  return json(
    result.safe
      ? { safe: true }
      : { safe: false, reason: result.reason },
    200
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function json(data: unknown, status: number): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: CORS_HEADERS,
  });
}
