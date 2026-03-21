import 'card_model.dart';

class EditionModel {
  final String id;
  final DateTime editionDate;
  final int? editionNumber;
  final String? theme;
  final int totalCards;
  final int totalReadSeconds;
  final String tier;
  final String status;
  final DateTime createdAt;
  final DateTime? assembledAt;

  const EditionModel({
    required this.id,
    required this.editionDate,
    this.editionNumber,
    this.theme,
    required this.totalCards,
    required this.totalReadSeconds,
    required this.tier,
    required this.status,
    required this.createdAt,
    this.assembledAt,
  });

  factory EditionModel.fromJson(Map<String, dynamic> json) {
    return EditionModel(
      id: json['id'] as String,
      editionDate: DateTime.parse(json['edition_date'] as String),
      editionNumber: json['edition_number'] as int?,
      theme: json['theme'] as String?,
      totalCards: json['total_cards'] as int? ?? 0,
      totalReadSeconds: json['total_read_seconds'] as int? ?? 0,
      tier: json['tier'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      assembledAt: json['assembled_at'] != null
          ? DateTime.parse(json['assembled_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'edition_date': editionDate.toIso8601String().split('T').first,
      'edition_number': editionNumber,
      'theme': theme,
      'total_cards': totalCards,
      'total_read_seconds': totalReadSeconds,
      'tier': tier,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'assembled_at': assembledAt?.toIso8601String(),
    };
  }

  EditionModel copyWith({
    String? id,
    DateTime? editionDate,
    int? editionNumber,
    String? theme,
    int? totalCards,
    int? totalReadSeconds,
    String? tier,
    String? status,
    DateTime? createdAt,
    DateTime? assembledAt,
  }) {
    return EditionModel(
      id: id ?? this.id,
      editionDate: editionDate ?? this.editionDate,
      editionNumber: editionNumber ?? this.editionNumber,
      theme: theme ?? this.theme,
      totalCards: totalCards ?? this.totalCards,
      totalReadSeconds: totalReadSeconds ?? this.totalReadSeconds,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      assembledAt: assembledAt ?? this.assembledAt,
    );
  }
}

class EditionCardModel {
  final String id;
  final String editionId;
  final String cardId;
  final int position;
  final String pacingRole;
  final CardModel? card;

  const EditionCardModel({
    required this.id,
    required this.editionId,
    required this.cardId,
    required this.position,
    required this.pacingRole,
    this.card,
  });

  factory EditionCardModel.fromJson(Map<String, dynamic> json) {
    return EditionCardModel(
      id: json['id'] as String,
      editionId: json['edition_id'] as String,
      cardId: json['card_id'] as String,
      position: json['position'] as int,
      pacingRole: json['pacing_role'] as String,
      card: json['cards'] != null
          ? CardModel.fromJson(json['cards'] as Map<String, dynamic>)
          : json['card'] != null
              ? CardModel.fromJson(json['card'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'edition_id': editionId,
      'card_id': cardId,
      'position': position,
      'pacing_role': pacingRole,
    };
  }

  EditionCardModel copyWith({
    String? id,
    String? editionId,
    String? cardId,
    int? position,
    String? pacingRole,
    CardModel? card,
  }) {
    return EditionCardModel(
      id: id ?? this.id,
      editionId: editionId ?? this.editionId,
      cardId: cardId ?? this.cardId,
      position: position ?? this.position,
      pacingRole: pacingRole ?? this.pacingRole,
      card: card ?? this.card,
    );
  }
}
