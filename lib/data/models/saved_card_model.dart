import 'card_model.dart';

class SavedCardModel {
  final String id;
  final String userId;
  final String cardId;
  final String? folder;
  final String? note;
  final DateTime createdAt;
  final CardModel? card;

  const SavedCardModel({
    required this.id,
    required this.userId,
    required this.cardId,
    this.folder,
    this.note,
    required this.createdAt,
    this.card,
  });

  factory SavedCardModel.fromJson(Map<String, dynamic> json) {
    return SavedCardModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cardId: json['card_id'] as String,
      folder: json['folder'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
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
      'user_id': userId,
      'card_id': cardId,
      'folder': folder,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SavedCardModel copyWith({
    String? id,
    String? userId,
    String? cardId,
    String? folder,
    String? note,
    DateTime? createdAt,
    CardModel? card,
  }) {
    return SavedCardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cardId: cardId ?? this.cardId,
      folder: folder ?? this.folder,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      card: card ?? this.card,
    );
  }
}
