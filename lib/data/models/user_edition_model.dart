class UserEditionModel {
  final String id;
  final String userId;
  final String editionId;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int lastCardPosition;
  final int cardsViewed;
  final int totalTimeSeconds;
  final DateTime createdAt;

  const UserEditionModel({
    required this.id,
    required this.userId,
    required this.editionId,
    this.startedAt,
    this.completedAt,
    this.lastCardPosition = 0,
    this.cardsViewed = 0,
    this.totalTimeSeconds = 0,
    required this.createdAt,
  });

  factory UserEditionModel.fromJson(Map<String, dynamic> json) {
    return UserEditionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      editionId: json['edition_id'] as String,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      lastCardPosition: json['last_card_position'] as int? ?? 0,
      cardsViewed: json['cards_viewed'] as int? ?? 0,
      totalTimeSeconds: json['total_time_seconds'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'edition_id': editionId,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'last_card_position': lastCardPosition,
      'cards_viewed': cardsViewed,
      'total_time_seconds': totalTimeSeconds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserEditionModel copyWith({
    String? id,
    String? userId,
    String? editionId,
    DateTime? startedAt,
    DateTime? completedAt,
    int? lastCardPosition,
    int? cardsViewed,
    int? totalTimeSeconds,
    DateTime? createdAt,
  }) {
    return UserEditionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      editionId: editionId ?? this.editionId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      lastCardPosition: lastCardPosition ?? this.lastCardPosition,
      cardsViewed: cardsViewed ?? this.cardsViewed,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
