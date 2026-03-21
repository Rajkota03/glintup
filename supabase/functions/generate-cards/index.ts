import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { createAdminClient } from "../_shared/supabase.ts";

const VALID_CARD_TYPES = [
  "quick_fact",
  "insight",
  "visual",
  "story",
  "deep_read",
  "question",
  "quote",
];

const DEFAULT_CARD_TYPES = [
  "quick_fact",
  "insight",
  "visual",
  "quote",
  "question",
];

const MAX_CARDS = 20;

/**
 * Builds the prompt for Claude to generate learning cards.
 */
function buildPrompt(
  topic: string,
  count: number,
  cardTypes: string[],
): string {
  return `Generate exactly ${count} learning cards about "${topic}".

Each card must be one of these types: ${cardTypes.join(", ")}

Return a JSON array of card objects. Each card must have these fields:
- "card_type": one of the allowed types listed above
- "title": a concise, engaging title (max 80 chars)
- "body": the main content (markdown supported)
- "summary": a 1-2 sentence summary
- "difficulty_level": integer from 1 (beginner) to 5 (expert)
- "estimated_read_seconds": estimated time to read in seconds (15-180)
- "tags": array of 2-4 relevant tags (lowercase, no spaces, use hyphens)

Additional fields based on card_type:

For "visual" cards:
- "image_search_term": a descriptive Unsplash search query for a relevant image

For "quote" cards:
- "body" should contain the quote text
- "source_name": the person who said/wrote the quote (real quotes with proper attribution only)

For "story" cards:
- "body" should be a longer narrative (200-400 words) using markdown formatting
- "subtitle": a subtitle for the story

For "question" cards:
- "question_text": the question being asked
- "answer_options": array of 4 objects, each with "text" (string) and "is_correct" (boolean) -- exactly one must be correct
- "correct_answer_explanation": explanation of why the correct answer is right

For "quick_fact" and "insight" cards:
- "body" should be concise and informative (50-150 words)
- "source_name": credit the source if referencing specific data or research

Rules:
- All content must be factually accurate
- Use engaging, clear language suitable for curious adults
- Distribute difficulty levels across the cards
- Vary the card types across the set
- Do not include any text outside the JSON array

Respond ONLY with the JSON array, no other text.`;
}

/**
 * Calls the Anthropic Claude API and returns the parsed response.
 */
async function callClaude(prompt: string): Promise<Record<string, unknown>[]> {
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) {
    throw new Error("ANTHROPIC_API_KEY is not configured");
  }

  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-sonnet-4-20250514",
      max_tokens: 4096,
      messages: [
        {
          role: "user",
          content: prompt,
        },
      ],
    }),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    console.error("Claude API error:", response.status, errorBody);
    throw new Error(`Claude API returned ${response.status}`);
  }

  const data = await response.json();

  // Extract text content from the response
  const textContent = data.content?.find(
    (block: { type: string }) => block.type === "text",
  );
  if (!textContent?.text) {
    throw new Error("No text content in Claude response");
  }

  // Parse the JSON array from the response
  const jsonText = textContent.text.trim();

  // Try to extract JSON array even if wrapped in markdown code blocks
  const jsonMatch = jsonText.match(/\[[\s\S]*\]/);
  if (!jsonMatch) {
    throw new Error("Could not find JSON array in Claude response");
  }

  const cards = JSON.parse(jsonMatch[0]);
  if (!Array.isArray(cards)) {
    throw new Error("Claude response is not a JSON array");
  }

  return cards;
}

serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    if (req.method !== "POST") {
      return errorResponse("Method not allowed", 405);
    }

    const body = await req.json();
    const { topic, count, card_types } = body;

    // Validate input
    if (!topic || typeof topic !== "string" || topic.trim().length === 0) {
      return errorResponse("topic is required and must be a non-empty string");
    }

    if (!count || typeof count !== "number" || count < 1 || count > MAX_CARDS) {
      return errorResponse(`count must be a number between 1 and ${MAX_CARDS}`);
    }

    let cardTypes: string[] = DEFAULT_CARD_TYPES;
    if (card_types && Array.isArray(card_types)) {
      const invalid = card_types.filter(
        (t: string) => !VALID_CARD_TYPES.includes(t),
      );
      if (invalid.length > 0) {
        return errorResponse(
          `Invalid card types: ${invalid.join(", ")}. Valid types: ${VALID_CARD_TYPES.join(", ")}`,
        );
      }
      cardTypes = card_types;
    }

    // Generate cards via Claude
    const prompt = buildPrompt(topic.trim(), count, cardTypes);
    const generatedCards = await callClaude(prompt);

    const supabase = createAdminClient();

    // Prepare cards for insertion
    const cardsToInsert = generatedCards.map((card) => ({
      card_type: card.card_type as string,
      status: "draft",
      title: card.title as string,
      subtitle: (card.subtitle as string) ?? null,
      body: card.body as string,
      summary: (card.summary as string) ?? null,
      image_url: null, // Will be populated later with Unsplash images
      source_url: null,
      source_name: (card.source_name as string) ?? null,
      topic: topic.trim(),
      subtopic: null,
      tags: (card.tags as string[]) ?? [],
      difficulty_level: (card.difficulty_level as number) ?? 3,
      estimated_read_seconds: (card.estimated_read_seconds as number) ?? 30,
      question_text: (card.question_text as string) ?? null,
      answer_options: (card.answer_options as Record<string, unknown>[]) ?? null,
      correct_answer_explanation:
        (card.correct_answer_explanation as string) ?? null,
    }));

    // Insert cards into the database
    const { data: insertedCards, error: insertError } = await supabase
      .from("cards")
      .insert(cardsToInsert)
      .select("id, card_type, title");

    if (insertError) {
      console.error("Card insert error:", insertError);
      return errorResponse("Failed to save generated cards", 500);
    }

    // Collect image search terms for visual cards (for later Unsplash fetch)
    const imageSearchTerms = generatedCards
      .filter((c) => c.card_type === "visual" && c.image_search_term)
      .map((c) => ({
        title: c.title,
        search_term: c.image_search_term,
      }));

    return jsonResponse({
      success: true,
      cards_generated: insertedCards?.length ?? 0,
      cards: insertedCards,
      image_search_terms: imageSearchTerms,
    });
  } catch (err) {
    console.error("generate-cards error:", err);
    const message =
      err instanceof Error ? err.message : "Internal server error";
    return errorResponse(message, 500);
  }
});
