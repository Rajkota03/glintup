/**
 * Shared Gemini API client for the content pipeline.
 * Uses Gemini 2.0 Flash (free tier: 1M tokens/day).
 */

const MAX_RETRIES = 3;
const BASE_DELAY_MS = 1000;

interface GeminiOptions {
  temperature?: number;
  maxTokens?: number;
  model?: string;
}

interface GeminiResult {
  text: string;
  inputTokens: number;
  outputTokens: number;
}

/**
 * Calls the Gemini API with retry logic and JSON mode.
 */
export async function callGemini(
  systemPrompt: string,
  userPrompt: string,
  options: GeminiOptions = {},
): Promise<GeminiResult> {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    throw new Error("GEMINI_API_KEY is not configured");
  }

  const model = options.model ?? "gemini-2.0-flash";
  const temperature = options.temperature ?? 0.7;
  const maxTokens = options.maxTokens ?? 2000;

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  const body = {
    systemInstruction: {
      parts: [{ text: systemPrompt }],
    },
    contents: [
      {
        parts: [{ text: userPrompt }],
      },
    ],
    generationConfig: {
      temperature,
      maxOutputTokens: maxTokens,
      responseMimeType: "application/json",
    },
  };

  let lastError: Error | null = null;

  for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 30000);

      const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
        signal: controller.signal,
      });

      clearTimeout(timeout);

      // Rate limited — wait and retry
      if (response.status === 429) {
        const delay = BASE_DELAY_MS * Math.pow(2, attempt);
        console.warn(`Gemini rate limited, retrying in ${delay}ms...`);
        await new Promise((r) => setTimeout(r, delay));
        continue;
      }

      if (!response.ok) {
        const errorBody = await response.text();
        console.error(`Gemini API error (${response.status}):`, errorBody);
        throw new Error(`Gemini API returned ${response.status}: ${errorBody}`);
      }

      const data = await response.json();

      // Extract text from response
      const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
      if (!text) {
        throw new Error("No text content in Gemini response");
      }

      // Extract token counts
      const inputTokens = data.usageMetadata?.promptTokenCount ?? 0;
      const outputTokens = data.usageMetadata?.candidatesTokenCount ?? 0;

      return { text, inputTokens, outputTokens };
    } catch (err) {
      lastError = err instanceof Error ? err : new Error(String(err));

      if (err instanceof DOMException && err.name === "AbortError") {
        lastError = new Error("Gemini API request timed out (30s)");
      }

      // Don't retry on non-retriable errors
      if (attempt < MAX_RETRIES - 1) {
        const delay = BASE_DELAY_MS * Math.pow(2, attempt);
        console.warn(`Gemini call failed, retrying in ${delay}ms...`, lastError.message);
        await new Promise((r) => setTimeout(r, delay));
      }
    }
  }

  throw lastError ?? new Error("Gemini call failed after retries");
}

/**
 * Calls Gemini and parses the JSON response.
 */
export async function callGeminiJson<T = unknown>(
  systemPrompt: string,
  userPrompt: string,
  options: GeminiOptions = {},
): Promise<{ data: T; inputTokens: number; outputTokens: number }> {
  const result = await callGemini(systemPrompt, userPrompt, options);

  try {
    // Try to parse directly
    const data = JSON.parse(result.text) as T;
    return { data, inputTokens: result.inputTokens, outputTokens: result.outputTokens };
  } catch {
    // Try to extract JSON from markdown code blocks
    const jsonMatch = result.text.match(/[\[{][\s\S]*[\]}]/);
    if (jsonMatch) {
      const data = JSON.parse(jsonMatch[0]) as T;
      return { data, inputTokens: result.inputTokens, outputTokens: result.outputTokens };
    }
    throw new Error("Could not parse JSON from Gemini response: " + result.text.substring(0, 200));
  }
}
