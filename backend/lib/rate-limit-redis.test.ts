import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";

const { limitSpy } = vi.hoisted(() => ({
  limitSpy: vi
    .fn()
    .mockRejectedValueOnce(new Error("redis down"))
    .mockRejectedValueOnce(new Error("redis down")),
}));

vi.mock("@upstash/redis", () => ({
  Redis: class {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    constructor(_opts: { url: string; token: string }) {}
  },
}));

vi.mock("@upstash/ratelimit", () => ({
  Ratelimit: class {
    static slidingWindow() {
      return {};
    }
    limit = (...args: unknown[]) => limitSpy(...args);
  },
}));

import { checkRateLimit } from "./rate-limit.js";

describe("checkRateLimit (redis path, mocked)", () => {
  const prevRate = process.env["RATE_LIMIT_ENABLED"];
  const prevUrl = process.env["UPSTASH_REDIS_REST_URL"];
  const prevToken = process.env["UPSTASH_REDIS_REST_TOKEN"];

  beforeEach(() => {
    limitSpy.mockClear();
    limitSpy
      .mockRejectedValueOnce(new Error("redis down"))
      .mockRejectedValueOnce(new Error("redis down"));
    process.env["RATE_LIMIT_ENABLED"] = "true";
    process.env["UPSTASH_REDIS_REST_URL"] = "https://example.upstash.io";
    process.env["UPSTASH_REDIS_REST_TOKEN"] = "test-token";
  });

  afterEach(() => {
    if (prevRate === undefined) delete process.env["RATE_LIMIT_ENABLED"];
    else process.env["RATE_LIMIT_ENABLED"] = prevRate;
    if (prevUrl === undefined) delete process.env["UPSTASH_REDIS_REST_URL"];
    else process.env["UPSTASH_REDIS_REST_URL"] = prevUrl;
    if (prevToken === undefined) delete process.env["UPSTASH_REDIS_REST_TOKEN"];
    else process.env["UPSTASH_REDIS_REST_TOKEN"] = prevToken;
  });

  it("returns redis_unavailable when limit() rejects twice", async () => {
    const r = await checkRateLimit("image", "198.51.100.1");
    expect(r).toEqual({ type: "redis_unavailable" });
    expect(limitSpy).toHaveBeenCalledTimes(2);
  });
});
