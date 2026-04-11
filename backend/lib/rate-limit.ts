/**
 * Shared rate limiting for Edge routes.
 *
 * - RATE_LIMIT_ENABLED=false → allow all requests.
 * - If UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN are set → Upstash
 *   sliding window (50 req / IP / hour) per route (`image` vs `video`).
 * - Otherwise → in-memory sliding window (single-instance only).
 *
 * When Redis is configured, failures after one retry return `redis_unavailable`
 * (map to HTTP 503 in routes). No silent fallback to memory.
 */

import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type RateRoute = "image" | "video";

export type RateLimitResult =
  | { type: "allowed" }
  | { type: "limited"; retryAfterSeconds: number }
  | { type: "redis_unavailable" };

// ---------------------------------------------------------------------------
// Memory sliding window (same semantics as legacy inline handlers)
// ---------------------------------------------------------------------------

const RATE_LIMIT_MAX = 50;
const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000;

const memoryStore = new Map<string, { timestamps: number[] }>();

function memoryCheck(key: string): RateLimitResult {
  const now = Date.now();
  const entry = memoryStore.get(key) ?? { timestamps: [] };

  entry.timestamps = entry.timestamps.filter(
    (t) => now - t < RATE_LIMIT_WINDOW_MS
  );

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

/** Clears in-memory counters (Vitest only). */
export function resetRateLimitMemoryForTests(): void {
  memoryStore.clear();
}

// ---------------------------------------------------------------------------
// Redis (lazy singletons per isolate)
// ---------------------------------------------------------------------------

let redisClient: Redis | undefined;
let imageRatelimit: Ratelimit | undefined;
let videoRatelimit: Ratelimit | undefined;

function getRedisEnv(): { url: string; token: string } | null {
  const url = process.env["UPSTASH_REDIS_REST_URL"]?.trim();
  const token = process.env["UPSTASH_REDIS_REST_TOKEN"]?.trim();
  if (!url || !token) return null;
  return { url, token };
}

function initRedisLimiters(): { image: Ratelimit; video: Ratelimit } {
  if (imageRatelimit && videoRatelimit) {
    return { image: imageRatelimit, video: videoRatelimit };
  }

  const env = getRedisEnv();
  if (!env) {
    throw new Error("Redis env incomplete");
  }

  redisClient = new Redis({ url: env.url, token: env.token });

  imageRatelimit = new Ratelimit({
    redis: redisClient,
    limiter: Ratelimit.slidingWindow(50, "1 h"),
    prefix: "adforge:rl:image",
    analytics: false,
  });

  videoRatelimit = new Ratelimit({
    redis: redisClient,
    limiter: Ratelimit.slidingWindow(50, "1 h"),
    prefix: "adforge:rl:video",
    analytics: false,
  });

  return { image: imageRatelimit, video: videoRatelimit };
}

async function checkRateLimitRedis(
  route: RateRoute,
  ip: string
): Promise<RateLimitResult> {
  const run = async (): Promise<RateLimitResult> => {
    const { image, video } = initRedisLimiters();
    const limiter = route === "image" ? image : video;
    const result = await limiter.limit(ip);

    if (result.success) {
      return { type: "allowed" };
    }

    const retryAfterSeconds = Math.max(
      1,
      Math.ceil((result.reset - Date.now()) / 1000)
    );
    return { type: "limited", retryAfterSeconds };
  };

  try {
    return await run();
  } catch {
    try {
      return await run();
    } catch {
      return { type: "redis_unavailable" };
    }
  }
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

export async function checkRateLimit(
  route: RateRoute,
  ip: string
): Promise<RateLimitResult> {
  if (process.env["RATE_LIMIT_ENABLED"] === "false") {
    return { type: "allowed" };
  }

  if (!getRedisEnv()) {
    return memoryCheck(`${route}:${ip}`);
  }

  return checkRateLimitRedis(route, ip);
}
