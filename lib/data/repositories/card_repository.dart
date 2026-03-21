import 'package:glintup/core/network/supabase_client.dart';
import 'package:glintup/data/models/card_model.dart';
import 'package:glintup/data/models/saved_card_model.dart';
import 'package:glintup/data/models/topic_model.dart';

class CardRepository {
  /// Saves a card to the user's library by inserting into `saved_cards`.
  /// Uses upsert to avoid duplicate entries.
  Future<void> saveCard(String userId, String cardId) async {
    await SupabaseConfig.client.from('saved_cards').upsert(
      {
        'user_id': userId,
        'card_id': cardId,
      },
      onConflict: 'user_id,card_id',
    );
  }

  /// Removes a saved card from the user's library.
  Future<void> unsaveCard(String userId, String cardId) async {
    await SupabaseConfig.client
        .from('saved_cards')
        .delete()
        .eq('user_id', userId)
        .eq('card_id', cardId);
  }

  /// Fetches saved cards for the given [userId] with joined card data.
  /// Supports pagination via [limit] and [offset].
  Future<List<SavedCardModel>> getSavedCards(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await SupabaseConfig.client
        .from('saved_cards')
        .select('*, cards(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List<dynamic>)
        .map((e) => SavedCardModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches published cards for a given [topic] for the explore feed.
  /// Supports pagination via [limit] and [offset].
  Future<List<CardModel>> getExploreCards(
    String topic, {
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await SupabaseConfig.client
        .from('cards')
        .select()
        .eq('topic', topic)
        .eq('status', 'published')
        .order('published_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List<dynamic>)
        .map((e) => CardModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches all active topics, ordered by [sortOrder].
  Future<List<TopicModel>> getTopics() async {
    final data = await SupabaseConfig.client
        .from('topics')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (data as List<dynamic>)
        .map((e) => TopicModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
