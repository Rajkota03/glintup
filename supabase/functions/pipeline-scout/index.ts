import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { createAdminClient } from "../_shared/supabase.ts";
import { callGeminiJson } from "../_shared/gemini.ts";

interface Brief {
  subtopic: string;
  angle: string;
  suggested_card_type: string;
  difficulty: number;
  source_hints: string;
}

serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const startTime = Date.now();
  const supabase = createAdminClient();

  try {
    const { topic, count = 5, pipeline_run_id } = await req.json();

    if (!topic) return errorResponse("topic is required");
    if (!pipeline_run_id) return errorResponse("pipeline_run_id is required");

    // Update pipeline run: scout started
    await supabase.from("pipeline_runs").update({
      scout_status: "running",
      scout_started_at: new Date().toISOString(),
    }).eq("id", pipeline_run_id);

    // Fetch active scout prompt
    const { data: prompt } = await supabase
      .from("content_prompts")
      .select("*")
      .eq("agent_role", "scout")
      .eq("is_active", true)
      .single();

    if (!prompt) {
      throw new Error("No active scout prompt found in content_prompts");
    }

    // Fill template placeholders
    const userPrompt = prompt.user_prompt_template
      .replace(/\{\{topic\}\}/g, topic)
      .replace(/\{\{count\}\}/g, String(count));

    // Call Gemini
    const { data: briefs, inputTokens, outputTokens } = await callGeminiJson<Brief[]>(
      prompt.system_prompt,
      userPrompt,
      {
        temperature: prompt.temperature,
        maxTokens: prompt.max_tokens,
        model: prompt.model_name,
      },
    );

    // Insert briefs into content_briefs
    const briefRows = (Array.isArray(briefs) ? briefs : []).map((b) => ({
      pipeline_run_id,
      topic,
      subtopic: b.subtopic ?? null,
      angle: b.angle ?? "Untitled angle",
      suggested_card_type: b.suggested_card_type ?? "quick_fact",
      source_hints: b.source_hints ?? null,
      difficulty: b.difficulty ?? 3,
      priority: "normal",
      status: "pending",
    }));

    const { data: inserted, error: insertError } = await supabase
      .from("content_briefs")
      .insert(briefRows)
      .select("id");

    if (insertError) throw new Error(`Brief insert failed: ${insertError.message}`);

    const latencyMs = Date.now() - startTime;

    // Log to agent_logs
    await supabase.from("agent_logs").insert({
      pipeline_run_id,
      agent_role: "scout",
      model_used: prompt.model_name,
      prompt_id: prompt.id,
      input_tokens: inputTokens,
      output_tokens: outputTokens,
      cost_cents: 0, // Free tier
      latency_ms: latencyMs,
      status: "success",
    });

    // Update prompt usage stats
    await supabase.from("content_prompts").update({
      total_uses: (prompt.total_uses ?? 0) + 1,
      last_used_at: new Date().toISOString(),
    }).eq("id", prompt.id);

    // Update pipeline run: scout completed
    await supabase.from("pipeline_runs").update({
      scout_status: "completed",
      scout_completed_at: new Date().toISOString(),
      scout_briefs_generated: inserted?.length ?? 0,
    }).eq("id", pipeline_run_id);

    return jsonResponse({
      success: true,
      briefs_count: inserted?.length ?? 0,
      brief_ids: inserted?.map((b) => b.id) ?? [],
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Scout failed";
    console.error("pipeline-scout error:", message);

    // Log failure
    await supabase.from("agent_logs").insert({
      pipeline_run_id: (await req.json().catch(() => ({}))).pipeline_run_id,
      agent_role: "scout",
      status: "error",
      error_message: message,
      latency_ms: Date.now() - startTime,
    }).catch(() => {});

    // Update pipeline run
    await supabase.from("pipeline_runs").update({
      scout_status: "failed",
      scout_error: message,
    }).eq("id", (await req.json().catch(() => ({}))).pipeline_run_id).catch(() => {});

    return errorResponse(message, 500);
  }
});
