import 'package:glintup/core/network/supabase_client.dart';
import 'package:glintup/data/models/user_stats_model.dart';

class StatsRepository {
  /// Fetches the [UserStatsModel] for the given [userId] from the
  /// `user_stats` table.
  ///
  /// Returns `null` if no stats record exists yet.
  Future<UserStatsModel?> getUserStats(String userId) async {
    final data = await SupabaseConfig.client
        .from('user_stats')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) return null;

    return UserStatsModel.fromJson(data);
  }

  /// Marks an edition as completed by invoking the `complete-edition`
  /// Supabase Edge Function, which handles streak updates, XP awards,
  /// and stat aggregation server-side.
  Future<Map<String, dynamic>> completeEdition(
    String editionId,
    int totalTimeSeconds,
  ) async {
    final userId = SupabaseConfig.userId;

    final response = await SupabaseConfig.invokeFunction(
      'complete-edition',
      body: {
        'user_id': userId,
        'edition_id': editionId,
        'total_time_seconds': totalTimeSeconds,
      },
    );

    return response;
  }

  /// Tracks a card interaction (view, save, share, etc.) by invoking
  /// the `track-interaction` Supabase Edge Function.
  Future<Map<String, dynamic>> trackInteraction({
    required String cardId,
    String? editionId,
    required String interactionType,
    required int timeSpentSeconds,
  }) async {
    final userId = SupabaseConfig.userId;

    final response = await SupabaseConfig.invokeFunction(
      'track-interaction',
      body: {
        'user_id': userId,
        'card_id': cardId,
        'edition_id': ?editionId,
        'interaction_type': interactionType,
        'time_spent_seconds': timeSpentSeconds,
      },
    );

    return response;
  }
}
