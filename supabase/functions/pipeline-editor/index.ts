import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { createAdminClient } from "../_shared/supabase.ts";
import { callGeminiJson } from "../_shared/gemini.ts";

interface EditorOutput {
  title: string;
  body: string;
  summary: string;
  changes_made: string;
}

serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const supabase = createAdminClient();

  try {
    const { card_ids, pipeline_run_id } = await req.json();

    if (!card_ids?.length) return errorResponse("card_ids is required");
    if (!pipeline_run_id) return errorResponse("pipeline_run_id is required");

    // Update pipeline run: editor started
    await supabase.from("pipeline_runs").update({
      editor_status: "running",
      editor_started_at: new Date().toISOString(),
    }).eq("id", pipeline_run_id);

    // Fetch editor prompt
    const { data: prompt } = await supabase
      .from("content_prompts")
      .select("*")
      .eq("agent_role", "editor")
      .eq("is_active", true)
      .single();

    if (!prompt) throw new Error("No active editor prompt found");

    const published: string[] = [];

    for (const cardId of card_ids) {
      const startTime = Date.now();

      try {
        // Fetch the card
        const { data: card } = await supabase
          .from("cards")
          .select("*")
          .eq("id", cardId)
          .eq("status", "review")
          .single();

        if (!card) {
          console.warn(`Card ${cardId} not in review status, skipping`);
          continue;
        }

        // Get latest reviewer feedback
        const { data: latestRevision } = await supabase
          .from("card_revisions")
          .select("feedback")
          .eq("card_id", cardId)
          .eq("agent_role", "reviewer")
          .order("created_at", { ascending: false })
          .limit(1)
          .single();

        const feedback = latestRevision?.feedback ?? "No specific feedback";

        // Fill template
        const userPrompt = prompt.user_prompt_template
          .replace(/\{\{card_type\}\}/g, card.card_type ?? "")
          .replace(/\{\{title\}\}/g, card.title ?? "")
          .replace(/\{\{body\}\}/g, card.body ?? "")
          .replace(/\{\{summary\}\}/g, card.summary ?? "")
          .replace(/\{\{feedback\}\}/g, feedback)
          .replace(/\{\{tone\}\}/g, prompt.tone ?? "curious");

        // Call Gemini
        const { data: edited, inputTokens, outputTokens } = await callGeminiJson<EditorOutput>(
          prompt.system_prompt,
          userPrompt,
          {
            temperature: prompt.temperature ?? 0.5,
            maxTokens: prompt.max_tokens ?? 2000,
            model: prompt.model_name,
          },
        );

        // Save content snapshot before updating
        const contentBefore = { title: card.title, body: card.body, summary: card.summary };
        const contentAfter = { title: edited.title, body: edited.body, summary: edited.summary };

        // Update card with polished content and publish
        await supabase.from("cards").update({
          title: edited.title ?? card.title,
          body: edited.body ?? card.body,
          summary: edited.summary ?? card.summary,
          status: "published",
          published_at: new Date().toISOString(),
        }).eq("id", cardId);

        published.push(cardId);

        // Create revision record
        await supabase.from("card_revisions").insert({
          card_id: cardId,
          pipeline_run_id,
          revision_number: 3,
          agent_role: "editor",
          decision: "publish",
          changes_made: edited.changes_made ?? "Polished content",
          content_before: contentBefore,
          content_after: contentAfter,
        });

        // Log to agent_logs
        await supabase.from("agent_logs").insert({
          pipeline_run_id,
          agent_role: "editor",
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
        const message = err instanceof Error ? err.message : "Editor error";
        console.error(`Editor failed for card ${cardId}:`, message);

        await supabase.from("agent_logs").insert({
          pipeline_run_id,
          agent_role: "editor",
          card_id: cardId,
          status: "error",
          error_message: message,
          latency_ms: Date.now() - startTime,
        }).catch(() => {});
      }
    }

    // Update pipeline run
    await supabase.from("pipeline_runs").update({
      editor_status: "completed",
      editor_completed_at: new Date().toISOString(),
      editor_cards_published: published.length,
    }).eq("id", pipeline_run_id);

    // Update prompt stats
    await supabase.from("content_prompts").update({
      total_uses: (prompt.total_uses ?? 0) + card_ids.length,
      last_used_at: new Date().toISOString(),
    }).eq("id", prompt.id);

    return jsonResponse({
      success: true,
      published,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Editor failed";
    console.error("pipeline-editor error:", message);
    return errorResponse(message, 500);
  }
});
