import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { createAdminClient } from "../_shared/supabase.ts";
import { callGeminiJson } from "../_shared/gemini.ts";

interface ReviewOutput {
  accuracy_score: number;
  engagement_score: number;
  clarity_score: number;
  formatting_score: number;
  uniqueness_score: number;
  overall_score: number;
  decision: "pass" | "rewrite" | "reject";
  feedback: string;
  accuracy_flag: boolean;
  rewrite_instructions?: string;
}

serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const supabase = createAdminClient();

  try {
    const { card_ids, pipeline_run_id } = await req.json();

    if (!card_ids?.length) return errorResponse("card_ids is required");
    if (!pipeline_run_id) return errorResponse("pipeline_run_id is required");

    // Update pipeline run: reviewer started
    await supabase.from("pipeline_runs").update({
      reviewer_status: "running",
      reviewer_started_at: new Date().toISOString(),
    }).eq("id", pipeline_run_id);

    // Fetch reviewer prompt
    const { data: prompt } = await supabase
      .from("content_prompts")
      .select("*")
      .eq("agent_role", "reviewer")
      .eq("is_active", true)
      .single();

    if (!prompt) throw new Error("No active reviewer prompt found");

    const passed: string[] = [];
    const rewrite: string[] = [];
    const rejected: string[] = [];

    for (const cardId of card_ids) {
      const startTime = Date.now();

      try {
        // Fetch the card
        const { data: card } = await supabase
          .from("cards")
          .select("*")
          .eq("id", cardId)
          .single();

        if (!card) {
          console.warn(`Card ${cardId} not found, skipping`);
          continue;
        }

        // Fill template
        const userPrompt = prompt.user_prompt_template
          .replace(/\{\{card_type\}\}/g, card.card_type ?? "")
          .replace(/\{\{title\}\}/g, card.title ?? "")
          .replace(/\{\{body\}\}/g, card.body ?? "")
          .replace(/\{\{summary\}\}/g, card.summary ?? "")
          .replace(/\{\{difficulty\}\}/g, String(card.difficulty_level ?? 3));

        // Call Gemini
        const { data: review, inputTokens, outputTokens } = await callGeminiJson<ReviewOutput>(
          prompt.system_prompt,
          userPrompt,
          {
            temperature: prompt.temperature ?? 0.3,
            maxTokens: prompt.max_tokens ?? 1000,
            model: prompt.model_name,
          },
        );

        const overallScore = review.overall_score ??
          ((review.accuracy_score + review.engagement_score + review.clarity_score +
            review.formatting_score + review.uniqueness_score) / 5);

        const decision = review.decision ?? (overallScore >= 4 ? "pass" : overallScore >= 3 ? "rewrite" : "reject");

        // Create revision record with scores
        await supabase.from("card_revisions").insert({
          card_id: cardId,
          pipeline_run_id,
          revision_number: 2,
          agent_role: "reviewer",
          accuracy_score: review.accuracy_score,
          engagement_score: review.engagement_score,
          clarity_score: review.clarity_score,
          formatting_score: review.formatting_score,
          uniqueness_score: review.uniqueness_score,
          overall_score: overallScore,
          decision,
          feedback: review.feedback ?? "",
        });

        // Update card based on decision
        if (decision === "pass") {
          await supabase.from("cards").update({
            status: "review",
            quality_score: Math.round(overallScore),
          }).eq("id", cardId);
          passed.push(cardId);
        } else if (decision === "rewrite") {
          // Keep as draft for rewrite
          await supabase.from("cards").update({
            quality_score: Math.round(overallScore),
          }).eq("id", cardId);
          rewrite.push(cardId);
        } else {
          await supabase.from("cards").update({
            status: "archived",
            quality_score: Math.round(overallScore),
          }).eq("id", cardId);
          rejected.push(cardId);
        }

        // Log to agent_logs
        await supabase.from("agent_logs").insert({
          pipeline_run_id,
          agent_role: "reviewer",
          card_id: cardId,
          model_used: prompt.model_name,
          prompt_id: prompt.id,
          input_tokens: inputTokens,
          output_tokens: outputTokens,
          cost_cents: 0,
          latency_ms: Date.now() - startTime,
          status: "success",
        });
      } catch (err) {
        const message = err instanceof Error ? err.message : "Review error";
        console.error(`Reviewer failed for card ${cardId}:`, message);

        await supabase.from("agent_logs").insert({
          pipeline_run_id,
          agent_role: "reviewer",
          card_id: cardId,
          status: "error",
          error_message: message,
          latency_ms: Date.now() - startTime,
        }).catch(() => {});
      }
    }

    // Update pipeline run
    await supabase.from("pipeline_runs").update({
      reviewer_status: "completed",
      reviewer_completed_at: new Date().toISOString(),
      reviewer_cards_passed: passed.length,
      reviewer_cards_failed: rejected.length,
      reviewer_cards_rewrite: rewrite.length,
    }).eq("id", pipeline_run_id);

    // Update prompt stats
    await supabase.from("content_prompts").update({
      total_uses: (prompt.total_uses ?? 0) + card_ids.length,
      last_used_at: new Date().toISOString(),
    }).eq("id", prompt.id);

    return jsonResponse({
      success: true,
      passed,
      rewrite,
      rejected,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Reviewer failed";
    console.error("pipeline-reviewer error:", message);
    return errorResponse(message, 500);
  }
});
