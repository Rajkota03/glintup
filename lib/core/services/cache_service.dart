import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String _editionBox = 'editions';
  static const String _cardsBox = 'cards';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(_editionBox);
    await Hive.openBox(_cardsBox);
  }

  /// Cache today's edition data as JSON
  Future<void> cacheEdition(String dateKey, Map<String, dynamic> editionData,
      List<Map<String, dynamic>> cardsData) async {
    final box = Hive.box(_editionBox);
    await box.put(dateKey, jsonEncode({
      'edition': editionData,
      'cards': cardsData,
      'cached_at': DateTime.now().toIso8601String(),
    }));
    await _clearOldCache();
  }

  /// Get cached edition for a date
  Map<String, dynamic>? getCachedEdition(String dateKey) {
    final box = Hive.box(_editionBox);
    final data = box.get(dateKey);
    if (data == null) return null;
    return jsonDecode(data as String) as Map<String, dynamic>;
  }

  /// Clear cache older than 3 days
  Future<void> _clearOldCache() async {
    final box = Hive.box(_editionBox);
    final cutoff = DateTime.now().subtract(const Duration(days: 3));
    final keysToDelete = <dynamic>[];

    for (final key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        try {
          final parsed = jsonDecode(data as String) as Map<String, dynamic>;
          final cachedAt = DateTime.parse(parsed['cached_at'] as String);
          if (cachedAt.isBefore(cutoff)) {
            keysToDelete.add(key);
          }
        } catch (_) {
          keysToDelete.add(key);
        }
      }
    }
    await box.deleteAll(keysToDelete);
  }

  /// Clear all cached data
  Future<void> clearAll() async {
    await Hive.box(_editionBox).clear();
    await Hive.box(_cardsBox).clear();
  }
}
