/**
 * fal-client.ts
 * Fal.ai client wrapper for AdForge backend.
 * Handles model routing, API calls, and error normalisation.
 */

import * as fal from "@fal-ai/client";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface ImageResult {
  imageURL: string;
}

export interface VideoResult {
  videoURL: string;
}

// Fal.ai response shape for image models
interface FalImageOutput {
  images?: Array<{ url: string }>;
  image?: { url: string };
}

// Fal.ai response shape for video models
interface FalVideoOutput {
  video?: { url: string };
  videos?: Array<{ url: string }>;
}

// ---------------------------------------------------------------------------
// Model → endpoint mappings
// ---------------------------------------------------------------------------

const IMAGE_MODEL_ENDPOINTS: Record<string, string> = {
  "flux-2-pro": "fal-ai/flux-pro/v1.1",
  "flux-2-dev": "fal-ai/flux/dev",
};

const VIDEO_MODEL_ENDPOINTS: Record<string, string> = {
  "wan-2.5": "fal-ai/wan/v2.5",
};

// ---------------------------------------------------------------------------
// Initialisation
// ---------------------------------------------------------------------------

let _initialized = false;

/**
 * Configure the Fal.ai client with the API key from environment variables.
 * Safe to call multiple times — only runs once.
 */
export function initFal(): void {
  if (_initialized) return;

  const key = process.env["FAL_KEY"];
  if (!key || key.trim() === "") {
    throw new Error(
      "FAL_KEY environment variable is not set. " +
        "Add it to your .env.local or Vercel project settings."
    );
  }

  fal.config({
    credentials: key.trim(),
  });

  _initialized = true;
}

// ---------------------------------------------------------------------------
// Image generation
// ---------------------------------------------------------------------------

/**
 * Generate an image using the specified model.
 * @param prompt - The user-supplied text prompt
 * @param model  - AdForge model ID (e.g. "flux-2-pro")
 * @returns { imageURL } pointing to the generated image
 */
export async function generateImage(
  prompt: string,
  model: string
): Promise<ImageResult> {
  initFal();

  const endpoint = IMAGE_MODEL_ENDPOINTS[model];
  if (!endpoint) {
    throw new Error(
      `Unsupported image model: "${model}". ` +
        `Valid options: ${Object.keys(IMAGE_MODEL_ENDPOINTS).join(", ")}.`
    );
  }

  let result: { data: FalImageOutput };
  try {
    result = (await fal.subscribe(endpoint, {
      input: {
        prompt,
        num_images: 1,
        image_size: "landscape_4_3",
        output_format: "jpeg",
        safety_tolerance: "2", // conservative: 1–5, lower = stricter
      },
      logs: false,
    })) as { data: FalImageOutput };
  } catch (err) {
    throw normalizeFalError("generateImage", model, err);
  }

  // Handle both response shapes
  const imageURL =
    result.data.images?.[0]?.url ?? result.data.image?.url ?? null;

  if (!imageURL) {
    throw new Error(
      `Fal.ai returned no image URL for model "${model}". ` +
        "The model may be temporarily unavailable."
    );
  }

  return { imageURL };
}

// ---------------------------------------------------------------------------
// Video generation
// ---------------------------------------------------------------------------

/**
 * Generate a video using the specified model.
 * @param prompt - The user-supplied text prompt
 * @param model  - AdForge model ID (e.g. "wan-2.5")
 * @returns { videoURL } pointing to the generated video
 */
export async function generateVideo(
  prompt: string,
  model: string
): Promise<VideoResult> {
  initFal();

  const endpoint = VIDEO_MODEL_ENDPOINTS[model];
  if (!endpoint) {
    throw new Error(
      `Unsupported video model: "${model}". ` +
        `Valid options: ${Object.keys(VIDEO_MODEL_ENDPOINTS).join(", ")}.`
    );
  }

  let result: { data: FalVideoOutput };
  try {
    result = (await fal.subscribe(endpoint, {
      input: {
        prompt,
        num_frames: 81,       // ~5 seconds @ ~16fps for Wan 2.5
        resolution: "480p",
        aspect_ratio: "16:9",
      },
      logs: false,
      // Video generation can take 30–120 seconds — poll aggressively
      pollInterval: 3000,
    })) as { data: FalVideoOutput };
  } catch (err) {
    throw normalizeFalError("generateVideo", model, err);
  }

  const videoURL =
    result.data.video?.url ?? result.data.videos?.[0]?.url ?? null;

  if (!videoURL) {
    throw new Error(
      `Fal.ai returned no video URL for model "${model}". ` +
        "The model may be temporarily unavailable."
    );
  }

  return { videoURL };
}

// ---------------------------------------------------------------------------
// Error helpers
// ---------------------------------------------------------------------------

function normalizeFalError(op: string, model: string, err: unknown): Error {
  if (err instanceof Error) {
    // Surface Fal.ai-specific error messages
    if (err.message.includes("422") || err.message.includes("Unprocessable")) {
      return new Error(
        `Fal.ai rejected the request for model "${model}": ${err.message}`
      );
    }
    if (err.message.includes("429") || err.message.includes("rate limit")) {
      return new Error(
        `Fal.ai rate limit reached for model "${model}". Please retry shortly.`
      );
    }
    if (err.message.includes("401") || err.message.includes("Unauthorized")) {
      return new Error(
        "Fal.ai API key is invalid or expired. Check FAL_KEY in your environment."
      );
    }
    return new Error(`${op} failed for model "${model}": ${err.message}`);
  }
  return new Error(`${op} encountered an unexpected error for model "${model}".`);
}
