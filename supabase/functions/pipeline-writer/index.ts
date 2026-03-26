import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { createAdminClient } from "../_shared/supabase.ts";
import { callGeminiJson } from "../_shared/gemini.ts";

interface CardOutput {
  title: string;
  body: string;
  summary?: string;
  subtitle?: string;
  source_name?: string;
  tags?: string[];
  difficulty_level?: number;
  estimated_read_seconds?: number;
  image_search_term?: string;
  question_text?: string;
  answer_options?: { label: string; text: string }[];
  correct_answer?: string;
  correct_answer_explanation?: string;
}

serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const supabase = createAdminClient();

  try {
    const { brief_ids, pipeline_run_id } = await req.json();

    if (!brief_ids?.length) return errorResponse("brief_ids is required");
    if (!pipeline_run_id) return errorResponse("pipeline_run_id is required");

    // Update pipeline run: writer started
    await supabase.from("pipeline_runs").update({
      writer_status: "running",
      writer_started_at: new Date().toISOString(),
    }).eq("id", pipeline_run_id);

    const cardIds: string[] = [];
    let totalDrafted = 0;

    for (const briefId of brief_ids) {
      const startTime = Date.now();

      try {
        // Fetch the brief
        const { data: brief } = await supabase
          .from("content_briefs")
          .select("*")
          .eq("id", briefId)
          .single();

        if (!brief) {
          console.warn(`Brief ${briefId} not found, skipping`);
          continue;
        }

        // Fetch the writer prompt for this card type
        const { data: prompt } = await supabase
          .from("content_prompts")
          .select("*")
          .eq("agent_role", "writer")
          .eq("card_type", brief.suggested_card_type)
          .eq("is_active", true)
          .single();

        if (!prompt) {
          console.warn(`No writer prompt for ${brief.suggested_card_type}, skipping`);
          continue;
        }

        // Fill template placeholders
        const userPrompt = prompt.user_prompt_template
          .replace(/\{\{topic\}\}/g, brief.topic ?? "")
          .replace(/\{\{subtopic\}\}/g, brief.subtopic ?? "")
          .replace(/\{\{angle\}\}/g, brief.angle ?? "")
          .replace(/\{\{difficulty\}\}/g, String(brief.difficulty ?? 3))
          .replace(/\{\{source_hints\}\}/g, brief.source_hints ?? "");

        // Call Gemini
        const { data: card, inputTokens, outputTokens } = await callGeminiJson<CardOutput>(
          prompt.system_prompt,
          userPrompt,
          {
            temperature: prompt.temperature,
            maxTokens: prompt.max_tokens,
            model: prompt.model_name,
          },
        );

        // Insert card into cards table
        const { data: inserted, error: insertError } = await supabase
          .from("cards")
          .insert({
            card_type: brief.suggested_card_type,
            status: "draft",
            title: card.title ?? "Untitled",
            subtitle: card.subtitle ?? null,
            body: card.body ?? "",
            summary: card.summary ?? null,
            source_name: card.source_name ?? null,
            topic: brief.topic,
            subtopic: brief.subtopic,
            tags: card.tags ?? [],
            difficulty_level: card.difficulty_level ?? brief.difficulty ?? 3,
            estimated_read_seconds: card.estimated_read_seconds ?? 30,
            question_text: card.question_text ?? null,
            answer_options: card.answer_options ?? null,
            correct_answer_explanation: card.correct_answer_explanation ?? null,
          })
          .select("id")
          .single();

        if (insertError) {
          console.error(`Card insert failed for brief ${briefId}:`, insertError);
          continue;
        }

        const cardId = inserted!.id;
        cardIds.push(cardId);
        totalDrafted++;

        // Update brief: completed with card_id
        await supabase.from("content_briefs").update({
          status: "completed",
          card_id: cardId,
        }).eq("id", briefId);

        // Create revision record
        await supabase.from("card_revisions").insert({
          card_id: cardId,
          pipeline_run_id,
          revision_number: 1,
          agent_role: "writer",
          content_after: { title: card.title, body: card.body, summary: card.summary },
        });

        // Log to agent_logs
        await supabase.from("agent_logs").insert({
          pipeline_run_id,
          agent_role: "writer",
          card_id: cardId,
          brief_id: briefId,
          model_used: prompt.model_name,
          prompt_id: prompt.id,
          input_tokens: inputTokens,
          output_tokens: outputTokens,
          cost_cents: 0,
          latency_ms: Date.now() - startTime,
          status: "success",
        });

        // Update prompt stats
        await supabase.from("content_prompts").update({
          total_uses: (prompt.total_uses ?? 0) + 1,
          last_used_at: new Date().toISOString(),
        }).eq("id", prompt.id);
      } catch (err) {
        const message = err instanceof Error ? err.message : "Writer error";
        console.error(`Writer failed for brief ${briefId}:`, message);

        await supabase.from("agent_logs").insert({
          pipeline_run_id,
          agent_role: "writer",
          brief_id: briefId,
          status: "error",
          error_message: message,
          latency_ms: Date.now() - startTime,
        }).catch(() => {});
      }
    }

    // Update pipeline run: writer completed
    await supabase.from("pipeline_runs").update({
      writer_status: "completed",
      writer_completed_at: new Date().toISOString(),
      writer_cards_drafted: totalDrafted,
    }).eq("id", pipeline_run_id);

    return jsonResponse({
      success: true,
      cards_drafted: totalDrafted,
      card_ids: cardIds,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Writer failed";
    console.error("pipeline-writer error:", message);
    return errorResponse(message, 500);
  }
});
