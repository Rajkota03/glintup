import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { createAdminClient } from "../_shared/supabase.ts";

const DEFAULT_TOPICS = [
  "science", "history", "psychology", "technology",
  "arts", "business", "nature", "space",
];

/**
 * Invokes another Supabase Edge Function internally.
 */
async function invokeFunction(
  functionName: string,
  payload: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  const response = await fetch(`${supabaseUrl}/functions/v1/${functionName}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${serviceRoleKey}`,
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`${functionName} returned ${response.status}: ${body}`);
  }

  return await response.json();
}

/**
 * Process items in batches with concurrency limit.
 */
async function processBatch<T, R>(
  items: T[],
  batchSize: number,
  fn: (item: T) => Promise<R>,
): Promise<PromiseSettledResult<R>[]> {
  const results: PromiseSettledResult<R>[] = [];

  for (let i = 0; i < items.length; i += batchSize) {
    const batch = items.slice(i, i + batchSize);
    const batchResults = await Promise.allSettled(batch.map(fn));
    results.push(...batchResults);
  }

  return results;
}

serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const supabase = createAdminClient();
  const pipelineStart = Date.now();

  try {
    const body = await req.json().catch(() => ({}));
    const topics: string[] = body.topics ?? DEFAULT_TOPICS;
    const countPerTopic: number = body.count_per_topic ?? 4;
    const triggerType: string = body.trigger_type ?? "manual";

    // Create pipeline run record
    const { data: run, error: runError } = await supabase
      .from("pipeline_runs")
      .insert({
        status: "running",
        trigger_type: triggerType,
        scout_status: "pending",
        writer_status: "pending",
        reviewer_status: "pending",
        editor_status: "pending",
      })
      .select("id")
      .single();

    if (runError || !run) {
      return errorResponse("Failed to create pipeline run: " + runError?.message, 500);
    }

    const pipelineRunId = run.id;
    console.log(`Pipeline run ${pipelineRunId} started (${triggerType})`);

    // =========================================
    // STEP 1: SCOUT — Generate briefs per topic
    // =========================================
    console.log("Step 1: Scout starting...");
    const allBriefIds: string[] = [];

    const scoutResults = await processBatch(topics, 3, async (topic) => {
      const result = await invokeFunction("pipeline-scout", {
        topic,
        count: countPerTopic,
        pipeline_run_id: pipelineRunId,
      });
      return result;
    });

    for (const result of scoutResults) {
      if (result.status === "fulfilled" && result.value.brief_ids) {
        allBriefIds.push(...(result.value.brief_ids as string[]));
      } else if (result.status === "rejected") {
        console.error("Scout batch failed:", result.reason);
      }
    }

    console.log(`Scout completed: ${allBriefIds.length} briefs generated`);

    if (allBriefIds.length === 0) {
      await supabase.from("pipeline_runs").update({
        status: "failed",
        scout_status: "failed",
        scout_error: "No briefs generated",
        completed_at: new Date().toISOString(),
        duration_seconds: Math.round((Date.now() - pipelineStart) / 1000),
      }).eq("id", pipelineRunId);

      return jsonResponse({ success: false, error: "No briefs generated", pipeline_run_id: pipelineRunId });
    }

    // =========================================
    // STEP 2: WRITER — Create cards from briefs
    // =========================================
    console.log("Step 2: Writer starting...");

    // Batch briefs in groups of 5
    const writerResults = await processBatch(
      chunkArray(allBriefIds, 5),
      2,
      async (briefBatch) => {
        return await invokeFunction("pipeline-writer", {
          brief_ids: briefBatch,
          pipeline_run_id: pipelineRunId,
        });
      },
    );

    const allCardIds: string[] = [];
    for (const result of writerResults) {
      if (result.status === "fulfilled" && result.value.card_ids) {
        allCardIds.push(...(result.value.card_ids as string[]));
      }
    }

    console.log(`Writer completed: ${allCardIds.length} cards drafted`);

    if (allCardIds.length === 0) {
      await supabase.from("pipeline_runs").update({
        status: "failed",
        writer_status: "failed",
        writer_error: "No cards drafted",
        completed_at: new Date().toISOString(),
        duration_seconds: Math.round((Date.now() - pipelineStart) / 1000),
      }).eq("id", pipelineRunId);

      return jsonResponse({ success: false, error: "No cards drafted", pipeline_run_id: pipelineRunId });
    }

    // =========================================
    // STEP 3: REVIEWER — Score and filter cards
    // =========================================
    console.log("Step 3: Reviewer starting...");

    const reviewerResults = await processBatch(
      chunkArray(allCardIds, 5),
      2,
      async (cardBatch) => {
        return await invokeFunction("pipeline-reviewer", {
          card_ids: cardBatch,
          pipeline_run_id: pipelineRunId,
        });
      },
    );

    let passedCards: string[] = [];
    let rewriteCards: string[] = [];
    const rejectedCards: string[] = [];

    for (const result of reviewerResults) {
      if (result.status === "fulfilled") {
        passedCards.push(...(result.value.passed as string[] ?? []));
        rewriteCards.push(...(result.value.rewrite as string[] ?? []));
        rejectedCards.push(...(result.value.rejected as string[] ?? []));
      }
    }

    console.log(`Reviewer: ${passedCards.length} passed, ${rewriteCards.length} rewrite, ${rejectedCards.length} rejected`);

    // =========================================
    // STEP 3b: REWRITE — One retry for rewrites
    // =========================================
    if (rewriteCards.length > 0) {
      console.log(`Step 3b: Rewriting ${rewriteCards.length} cards...`);

      // Get brief IDs for rewrite cards
      const { data: rewriteBriefs } = await supabase
        .from("content_briefs")
        .select("id")
        .in("card_id", rewriteCards);

      if (rewriteBriefs?.length) {
        const rewriteBriefIds = rewriteBriefs.map((b) => b.id);

        // Re-run writer
        await invokeFunction("pipeline-writer", {
          brief_ids: rewriteBriefIds,
          pipeline_run_id: pipelineRunId,
        });

        // Re-run reviewer on rewritten cards
        const reReviewResult = await invokeFunction("pipeline-reviewer", {
          card_ids: rewriteCards,
          pipeline_run_id: pipelineRunId,
        }) as { passed?: string[] };

        if (reReviewResult.passed) {
          passedCards.push(...reReviewResult.passed);
        }
      }
    }

    // =========================================
    // STEP 4: EDITOR — Polish and publish
    // =========================================
    console.log("Step 4: Editor starting...");

    if (passedCards.length > 0) {
      await processBatch(
        chunkArray(passedCards, 5),
        2,
        async (cardBatch) => {
          return await invokeFunction("pipeline-editor", {
            card_ids: cardBatch,
            pipeline_run_id: pipelineRunId,
          });
        },
      );
    }

    // =========================================
    // STEP 5: FINALIZE
    // =========================================
    const durationSeconds = Math.round((Date.now() - pipelineStart) / 1000);

    // Count actual published cards
    const { count: publishedCount } = await supabase
      .from("cards")
      .select("id", { count: "exact", head: true })
      .eq("status", "published")
      .gte("published_at", new Date(pipelineStart).toISOString());

    // Sum total cost
    const { data: costData } = await supabase
      .from("agent_logs")
      .select("cost_cents")
      .eq("pipeline_run_id", pipelineRunId);

    const totalCost = costData?.reduce((sum, log) => sum + (log.cost_cents ?? 0), 0) ?? 0;

    // Update pipeline run as completed
    await supabase.from("pipeline_runs").update({
      status: "completed",
      total_cards_generated: publishedCount ?? passedCards.length,
      total_cost_cents: Math.round(totalCost),
      duration_seconds: durationSeconds,
      completed_at: new Date().toISOString(),
    }).eq("id", pipelineRunId);

    const summary = {
      success: true,
      pipeline_run_id: pipelineRunId,
      briefs_generated: allBriefIds.length,
      cards_drafted: allCardIds.length,
      cards_passed: passedCards.length,
      cards_rejected: rejectedCards.length,
      cards_rewritten: rewriteCards.length,
      cards_published: publishedCount ?? passedCards.length,
      duration_seconds: durationSeconds,
      total_cost_cents: Math.round(totalCost),
    };

    console.log("Pipeline completed:", summary);
    return jsonResponse(summary);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Pipeline failed";
    console.error("pipeline-orchestrator error:", message);
    return errorResponse(message, 500);
  }
});

/**
 * Splits an array into chunks of the given size.
 */
function chunkArray<T>(arr: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < arr.length; i += size) {
    chunks.push(arr.slice(i, i + size));
  }
  return chunks;
}
