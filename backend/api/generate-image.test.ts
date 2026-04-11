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
