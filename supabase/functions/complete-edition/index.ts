import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { createAdminClient, getUserId } from "../_shared/supabase.ts";

const XP_PER_CARD = 10;
const XP_STREAK_BONUS = 25;
const XP_PER_LEVEL = 500;

/**
 * Returns the date string (YYYY-MM-DD) for a given Date object.
 */
function toDateString(date: Date): string {
  return date.toISOString().split("T")[0];
}

/**
 * Returns yesterday's date string (YYYY-MM-DD).
 */
function getYesterday(): string {
  const d = new Date();
  d.setDate(d.getDate() - 1);
  return toDateString(d);
}

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
    const { edition_id, total_time_seconds } = body;

    if (!edition_id || typeof edition_id !== "string") {
      return errorResponse("edition_id is required");
    }

    if (
      total_time_seconds == null ||
      typeof total_time_seconds !== "number" ||
      total_time_seconds < 0
    ) {
      return errorResponse("total_time_seconds must be a non-negative number");
    }

    const supabase = createAdminClient();

    // 1. Get the edition to find total_cards
    const { data: edition, error: editionError } = await supabase
      .from("editions")
      .select("id, total_cards")
      .eq("id", edition_id)
      .single();

    if (editionError || !edition) {
      return errorResponse("Edition not found", 404);
    }

    const totalCards: number = edition.total_cards;

    // 2. Mark the user_edition as completed
    const { error: updateEditionError } = await supabase
      .from("user_editions")
      .update({ completed_at: new Date().toISOString() })
      .eq("user_id", userId)
      .eq("edition_id", edition_id);

    if (updateEditionError) {
      console.error("Update user_edition error:", updateEditionError);
      return errorResponse("Failed to update edition progress", 500);
    }

    // 3. Fetch current user_stats
    const { data: currentStats, error: statsError } = await supabase
      .from("user_stats")
      .select("*")
      .eq("user_id", userId)
      .maybeSingle();

    if (statsError) {
      console.error("Fetch stats error:", statsError);
      return errorResponse("Failed to fetch user stats", 500);
    }

    // If no stats record exists, create defaults
    const stats = currentStats ?? {
      user_id: userId,
      current_streak: 0,
      longest_streak: 0,
      last_completed_date: null,
      total_editions_completed: 0,
      total_cards_read: 0,
      total_time_seconds: 0,
      total_cards_saved: 0,
      cards_this_week: 0,
      cards_this_month: 0,
      xp_points: 0,
      level: 1,
    };

    // 4. Calculate streak
    const today = toDateString(new Date());
    const yesterday = getYesterday();
    let newStreak = stats.current_streak;

    if (stats.last_completed_date === today) {
      // Already completed today -- no streak change
    } else if (stats.last_completed_date === yesterday) {
      // Consecutive day -- increment streak
      newStreak += 1;
    } else {
      // Streak broken or first completion
      newStreak = 1;
    }

    const longestStreak = Math.max(newStreak, stats.longest_streak);

    // 5. Calculate XP
    const streakActive = newStreak > 1;
    const earnedXp =
      totalCards * XP_PER_CARD + (streakActive ? XP_STREAK_BONUS : 0);
    const newXp = stats.xp_points + earnedXp;
    const newLevel = Math.floor(newXp / XP_PER_LEVEL) + 1;

    // 6. Build updated stats
    const updatedStats = {
      user_id: userId,
      current_streak: newStreak,
      longest_streak: longestStreak,
      last_completed_date: today,
      total_editions_completed: stats.total_editions_completed + 1,
      total_cards_read: stats.total_cards_read + totalCards,
      total_time_seconds: stats.total_time_seconds + total_time_seconds,
      total_cards_saved: stats.total_cards_saved,
      cards_this_week: stats.cards_this_week + totalCards,
      cards_this_month: stats.cards_this_month + totalCards,
      xp_points: newXp,
      level: newLevel,
      updated_at: new Date().toISOString(),
    };

    // 7. Upsert user_stats
    const { data: savedStats, error: saveError } = await supabase
      .from("user_stats")
      .upsert(updatedStats, { onConflict: "user_id" })
      .select()
      .single();

    if (saveError) {
      console.error("Save stats error:", saveError);
      return errorResponse("Failed to update stats", 500);
    }

    return jsonResponse({
      success: true,
      stats: savedStats,
      xp_earned: earnedXp,
      streak_bonus: streakActive,
    });
  } catch (err) {
    console.error("complete-edition error:", err);
    return errorResponse("Internal server error", 500);
  }
});
