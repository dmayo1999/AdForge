import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("../lib/fal-client.js", () => ({
  generateImage: vi.fn(),
  generateVideo: vi.fn(async () => ({
    videoURL: "https://example.com/out.mp4",
  })),
}));

import handler from "./generate-video.js";
import { generateVideo } from "../lib/fal-client.js";

function postRequest(body: object, headers?: Record<string, string>): Request {
  return new Request("http://localhost/api/generate-video", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-forwarded-for": "203.0.113.2",
      ...headers,
    },
    body: JSON.stringify(body),
  });
}

describe("POST /api/generate-video", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.RATE_LIMIT_ENABLED = "false";
  });

  it("returns 200 and video payload when valid", async () => {
    const res = await handler(
      postRequest({
        prompt: "A red balloon floating over water",
        model: "wan-2.5",
        userId: "user-2",
      })
    );
    expect(res.status).toBe(200);
    const json = (await res.json()) as { videoURL: string };
    expect(json.videoURL).toContain("http");
    expect(generateVideo).toHaveBeenCalledOnce();
  });

  it("returns 400 when prompt blocked", async () => {
    const res = await handler(
      postRequest({
        prompt: "snuff film realistic",
        model: "wan-2.5",
        userId: "user-2",
      })
    );
    expect(res.status).toBe(400);
  });
});
