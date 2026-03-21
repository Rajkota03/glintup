class UserStatsModel {
  final String id;
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;
  final int totalEditionsCompleted;
  final int totalCardsRead;
  final int totalTimeSeconds;
  final int totalCardsSaved;
  final int cardsThisWeek;
  final int cardsThisMonth;
  final int xpPoints;
  final int level;
  final DateTime updatedAt;

  const UserStatsModel({
    required this.id,
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
    this.totalEditionsCompleted = 0,
    this.totalCardsRead = 0,
    this.totalTimeSeconds = 0,
    this.totalCardsSaved = 0,
    this.cardsThisWeek = 0,
    this.cardsThisMonth = 0,
    this.xpPoints = 0,
    this.level = 1,
    required this.updatedAt,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastCompletedDate: json['last_completed_date'] != null
          ? DateTime.parse(json['last_completed_date'] as String)
          : null,
      totalEditionsCompleted:
          json['total_editions_completed'] as int? ?? 0,
      totalCardsRead: json['total_cards_read'] as int? ?? 0,
      totalTimeSeconds: json['total_time_seconds'] as int? ?? 0,
      totalCardsSaved: json['total_cards_saved'] as int? ?? 0,
      cardsThisWeek: json['cards_this_week'] as int? ?? 0,
      cardsThisMonth: json['cards_this_month'] as int? ?? 0,
      xpPoints: json['xp_points'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_completed_date':
          lastCompletedDate?.toIso8601String().split('T').first,
      'total_editions_completed': totalEditionsCompleted,
      'total_cards_read': totalCardsRead,
      'total_time_seconds': totalTimeSeconds,
      'total_cards_saved': totalCardsSaved,
      'cards_this_week': cardsThisWeek,
      'cards_this_month': cardsThisMonth,
      'xp_points': xpPoints,
      'level': level,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserStatsModel copyWith({
    String? id,
    String? userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletedDate,
    int? totalEditionsCompleted,
    int? totalCardsRead,
    int? totalTimeSeconds,
    int? totalCardsSaved,
    int? cardsThisWeek,
    int? cardsThisMonth,
    int? xpPoints,
    int? level,
    DateTime? updatedAt,
  }) {
    return UserStatsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      totalEditionsCompleted:
          totalEditionsCompleted ?? this.totalEditionsCompleted,
      totalCardsRead: totalCardsRead ?? this.totalCardsRead,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      totalCardsSaved: totalCardsSaved ?? this.totalCardsSaved,
      cardsThisWeek: cardsThisWeek ?? this.cardsThisWeek,
      cardsThisMonth: cardsThisMonth ?? this.cardsThisMonth,
      xpPoints: xpPoints ?? this.xpPoints,
      level: level ?? this.level,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
