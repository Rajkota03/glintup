import 'package:glintup/core/network/supabase_client.dart';
import 'package:glintup/data/models/edition_model.dart';
import 'package:glintup/data/models/user_edition_model.dart';

class EditionRepository {
  /// Fetches today's edition for the given [tier], including its
  /// edition cards joined with full card data, ordered by position.
  ///
  /// Returns `null` if no edition exists for today.
  Future<EditionModel?> getTodayEdition(String tier) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    final response = await SupabaseConfig.client
        .from('editions')
        .select()
        .eq('edition_date', today)
        .eq('tier', tier)
        .maybeSingle();

    if (response == null) return null;

    return EditionModel.fromJson(response);
  }

  /// Fetches the edition cards for [editionId] with joined card data,
  /// ordered by position.
  Future<List<EditionCardModel>> getEditionCards(String editionId) async {
    final data = await SupabaseConfig.client
        .from('edition_cards')
        .select('*, cards(*)')
        .eq('edition_id', editionId)
        .order('position', ascending: true);

    return (data as List<dynamic>)
        .map((e) => EditionCardModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Gets the existing [UserEditionModel] for this user and edition,
  /// or creates a new record if none exists.
  Future<UserEditionModel> getUserEdition(
    String userId,
    String editionId,
  ) async {
    // Try to find an existing record.
    final existing = await SupabaseConfig.client
        .from('user_editions')
        .select()
        .eq('user_id', userId)
        .eq('edition_id', editionId)
        .maybeSingle();

    if (existing != null) {
      return UserEditionModel.fromJson(existing);
    }

    // Create a new record.
    final inserted = await SupabaseConfig.client
        .from('user_editions')
        .insert({
          'user_id': userId,
          'edition_id': editionId,
          'started_at': DateTime.now().toIso8601String(),
          'last_card_position': 0,
          'cards_viewed': 0,
          'total_time_seconds': 0,
        })
        .select()
        .single();

    return UserEditionModel.fromJson(inserted);
  }

  /// Updates progress on an existing user edition record.
  Future<void> updateProgress(
    String userEditionId, {
    required int lastPosition,
    required int cardsViewed,
    required int timeSeconds,
  }) async {
    await SupabaseConfig.client
        .from('user_editions')
        .update({
          'last_card_position': lastPosition,
          'cards_viewed': cardsViewed,
          'total_time_seconds': timeSeconds,
        })
        .eq('id', userEditionId);
  }
}
