import { describe, it, expect, beforeEach, afterAll } from "vitest";
import { checkRateLimit, resetRateLimitMemoryForTests } from "./rate-limit.js";

describe("checkRateLimit (memory)", () => {
  const prevRate = process.env["RATE_LIMIT_ENABLED"];
  const prevUrl = process.env["UPSTASH_REDIS_REST_URL"];
  const prevToken = process.env["UPSTASH_REDIS_REST_TOKEN"];

  beforeEach(() => {
    resetRateLimitMemoryForTests();
    process.env["RATE_LIMIT_ENABLED"] = "true";
    delete process.env["UPSTASH_REDIS_REST_URL"];
    delete process.env["UPSTASH_REDIS_REST_TOKEN"];
  });

  afterAll(() => {
    if (prevRate === undefined) delete process.env["RATE_LIMIT_ENABLED"];
    else process.env["RATE_LIMIT_ENABLED"] = prevRate;
    if (prevUrl === undefined) delete process.env["UPSTASH_REDIS_REST_URL"];
    else process.env["UPSTASH_REDIS_REST_URL"] = prevUrl;
    if (prevToken === undefined) delete process.env["UPSTASH_REDIS_REST_TOKEN"];
    else process.env["UPSTASH_REDIS_REST_TOKEN"] = prevToken;
  });

  it("allows all requests when RATE_LIMIT_ENABLED is false", async () => {
    process.env["RATE_LIMIT_ENABLED"] = "false";
    for (let i = 0; i < 60; i++) {
      const r = await checkRateLimit("image", "203.0.113.1");
      expect(r.type).toBe("allowed");
    }
  });

  it("allows 50 requests then blocks the 51st (same route + IP)", async () => {
    const ip = "203.0.113.10";
    for (let i = 0; i < 50; i++) {
      const r = await checkRateLimit("image", ip);
      expect(r.type).toBe("allowed");
    }
    const last = await checkRateLimit("image", ip);
    expect(last.type).toBe("limited");
    if (last.type === "limited") {
      expect(last.retryAfterSeconds).toBeGreaterThan(0);
    }
  });

  it("tracks image and video limits independently in memory", async () => {
    const ip = "203.0.113.11";
    for (let i = 0; i < 50; i++) {
      expect((await checkRateLimit("image", ip)).type).toBe("allowed");
    }
    expect((await checkRateLimit("image", ip)).type).toBe("limited");
    expect((await checkRateLimit("video", ip)).type).toBe("allowed");
  });
});
