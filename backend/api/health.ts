/**
 * GET /api/health
 *
 * Health check endpoint. Returns service status and version.
 * Used by monitoring tools, load balancers, and iOS app startup checks.
 *
 * Response: { status: "ok", version: string, timestamp: ISO string }
 *
 * Edge function — runs at the CDN edge worldwide.
 */

export const config = {
  runtime: "edge",
};

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
  "Content-Type": "application/json",
  // Prevent caching of health checks
  "Cache-Control": "no-store, no-cache, must-revalidate",
};

export default function handler(req: Request): Response {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  if (req.method !== "GET") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405,
      headers: CORS_HEADERS,
    });
  }

  return new Response(
    JSON.stringify({
      status: "ok",
      version: "1.0.0",
      timestamp: new Date().toISOString(),
    }),
    {
      status: 200,
      headers: CORS_HEADERS,
    }
  );
}
