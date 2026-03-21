import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glintup/core/constants/app_constants.dart';
import 'package:glintup/core/network/supabase_client.dart';
import 'package:glintup/data/models/card_model.dart';
import 'package:glintup/data/models/topic_model.dart';

// ──────────────────────────────────────────────────────────────
// Topics — real Supabase query
// ──────────────────────────────────────────────────────────────
final topicsProvider = FutureProvider<List<TopicModel>>((ref) async {
  final response = await SupabaseConfig.client
      .from('topics')
      .select()
      .eq('is_active', true)
      .order('sort_order', ascending: true);

  return (response as List<dynamic>)
      .map((e) => TopicModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ──────────────────────────────────────────────────────────────
// Selected topic — tracks which topic chip the user tapped
// ──────────────────────────────────────────────────────────────
final selectedTopicProvider = StateProvider<String?>((ref) => null);

// ──────────────────────────────────────────────────────────────
// Explore cards — real Supabase query (published, by topic, paginated)
// ──────────────────────────────────────────────────────────────
final exploreCardsProvider =
    FutureProvider.family<List<CardModel>, String>((ref, topic) async {
  final response = await SupabaseConfig.client
      .from('cards')
      .select()
      .eq('status', 'published')
      .eq('topic', topic)
      .order('published_at', ascending: false)
      .limit(AppConstants.explorePageSize);

  return (response as List<dynamic>)
      .map((e) => CardModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ──────────────────────────────────────────────────────────────
// Rabbit holes — real Supabase query
// ──────────────────────────────────────────────────────────────
class RabbitHoleModel {
  final String id;
  final String topic;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final int totalCards;
  final int estimatedTimeMinutes;
  final int difficultyLevel;
  final bool isPremium;

  const RabbitHoleModel({
    required this.id,
    required this.topic,
    required this.title,
    this.description,
    this.coverImageUrl,
    this.totalCards = 0,
    this.estimatedTimeMinutes = 0,
    this.difficultyLevel = 2,
    this.isPremium = false,
  });

  factory RabbitHoleModel.fromJson(Map<String, dynamic> json) {
    return RabbitHoleModel(
      id: json['id'] as String,
      topic: json['topic'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      totalCards: json['total_cards'] as int? ?? 0,
      estimatedTimeMinutes: json['estimated_time_minutes'] as int? ?? 0,
      difficultyLevel: json['difficulty_level'] as int? ?? 2,
      isPremium: json['is_premium'] as bool? ?? false,
    );
  }
}

final rabbitHolesProvider =
    FutureProvider<List<RabbitHoleModel>>((ref) async {
  final response = await SupabaseConfig.client
      .from('rabbit_holes')
      .select()
      .order('created_at', ascending: false);

  return (response as List<dynamic>)
      .map((e) => RabbitHoleModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ──────────────────────────────────────────────────────────────
// Search — debounced search across cards
// ──────────────────────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<CardModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];

  final pattern = '%${query.trim()}%';

  final response = await SupabaseConfig.client
      .from('cards')
      .select()
      .eq('status', 'published')
      .or('title.ilike.$pattern,body.ilike.$pattern')
      .order('published_at', ascending: false)
      .limit(AppConstants.explorePageSize);

  return (response as List<dynamic>)
      .map((e) => CardModel.fromJson(e as Map<String, dynamic>))
      .toList();
});
