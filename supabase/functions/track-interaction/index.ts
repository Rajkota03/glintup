import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { createAdminClient, getUserId } from "../_shared/supabase.ts";

const VALID_INTERACTION_TYPES = [
  "read",
  "save",
  "unsave",
  "share",
  "view",
  "skip",
];

serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    if (req.method !== "POST") {
      return errorResponse("Method not allowed", 405);
    }

    // Authenticate user
    const userId = await getUserId(req);
    if (!userId) {
      return errorResponse("Unauthorized", 401);
    }

    const body = await req.json();
    const { card_id, edition_id, interaction_type, time_spent_seconds } = body;

    // Validate required fields
    if (!card_id || typeof card_id !== "string") {
      return errorResponse("card_id is required");
    }

    if (!interaction_type || typeof interaction_type !== "string") {
      return errorResponse("interaction_type is required");
    }

    if (!VALID_INTERACTION_TYPES.includes(interaction_type)) {
      return errorResponse(
        `interaction_type must be one of: ${VALID_INTERACTION_TYPES.join(", ")}`,
      );
    }

    if (
      time_spent_seconds == null ||
      typeof time_spent_seconds !== "number" ||
      time_spent_seconds < 0
    ) {
      return errorResponse("time_spent_seconds must be a non-negative number");
    }

    const supabase = createAdminClient();

    // 1. Insert into card_interactions
    const interactionRecord: Record<string, unknown> = {
      user_id: userId,
      card_id,
      interaction_type,
      time_spent_seconds,
      created_at: new Date().toISOString(),
    };

    if (edition_id && typeof edition_id === "string") {
      interactionRecord.edition_id = edition_id;
    }

    const { error: insertError } = await supabase
      .from("card_interactions")
      .insert(interactionRecord);

    if (insertError) {
      console.error("Insert interaction error:", insertError);
      return errorResponse("Failed to track interaction", 500);
    }

    // 2. If interaction_type is 'read', upsert into card_read_history
    if (interaction_type === "read") {
      const { error: readHistoryError } = await supabase
        .from("card_read_history")
        .upsert(
          {
            user_id: userId,
            card_id,
            last_read_at: new Date().toISOString(),
            read_count: 1, // Will be incremented via trigger or RPC if needed
          },
          { onConflict: "user_id,card_id" },
        );

      if (readHistoryError) {
        // Log but don't fail the request -- the interaction was already saved
        console.error("Upsert read history error:", readHistoryError);
      }
    }

    return jsonResponse({ success: true });
  } catch (err) {
    console.error("track-interaction error:", err);
    return errorResponse("Internal server error", 500);
  }
});
