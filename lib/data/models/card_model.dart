enum CardType {
  quickFact,
  insight,
  visual,
  story,
  deepRead,
  question,
  quote;

  /// Converts a snake_case database value (e.g. 'quick_fact') to [CardType].
  static CardType fromDbValue(String value) {
    switch (value) {
      case 'quick_fact':
        return CardType.quickFact;
      case 'insight':
        return CardType.insight;
      case 'visual':
        return CardType.visual;
      case 'story':
        return CardType.story;
      case 'deep_read':
        return CardType.deepRead;
      case 'question':
        return CardType.question;
      case 'quote':
        return CardType.quote;
      default:
        throw ArgumentError('Unknown CardType db value: $value');
    }
  }

  /// Converts a [CardType] back to its snake_case database value.
  String toDbValue() {
    switch (this) {
      case CardType.quickFact:
        return 'quick_fact';
      case CardType.insight:
        return 'insight';
      case CardType.visual:
        return 'visual';
      case CardType.story:
        return 'story';
      case CardType.deepRead:
        return 'deep_read';
      case CardType.question:
        return 'question';
      case CardType.quote:
        return 'quote';
    }
  }
}

enum CardStatus {
  draft,
  review,
  approved,
  published,
  archived;

  static CardStatus fromDbValue(String value) {
    return CardStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Unknown CardStatus db value: $value'),
    );
  }

  String toDbValue() => name;
}

class CardModel {
  final String id;
  final CardType cardType;
  final CardStatus status;
  final String title;
  final String? subtitle;
  final String body;
  final String? summary;
  final String? imageUrl;
  final String? sourceUrl;
  final String? sourceName;
  final String topic;
  final String? subtopic;
  final List<String> tags;
  final int difficultyLevel;
  final int estimatedReadSeconds;
  final String? questionText;
  final List<Map<String, dynamic>>? answerOptions;
  final String? correctAnswerExplanation;
  final DateTime createdAt;
  final DateTime? publishedAt;

  const CardModel({
    required this.id,
    required this.cardType,
    required this.status,
    required this.title,
    this.subtitle,
    required this.body,
    this.summary,
    this.imageUrl,
    this.sourceUrl,
    this.sourceName,
    required this.topic,
    this.subtopic,
    this.tags = const [],
    required this.difficultyLevel,
    required this.estimatedReadSeconds,
    this.questionText,
    this.answerOptions,
    this.correctAnswerExplanation,
    required this.createdAt,
    this.publishedAt,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String,
      cardType: CardType.fromDbValue(json['card_type'] as String),
      status: CardStatus.fromDbValue(json['status'] as String),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      body: json['body'] as String,
      summary: json['summary'] as String?,
      imageUrl: json['image_url'] as String?,
      sourceUrl: json['source_url'] as String?,
      sourceName: json['source_name'] as String?,
      topic: json['topic'] as String,
      subtopic: json['subtopic'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      difficultyLevel: json['difficulty_level'] as int? ?? 1,
      estimatedReadSeconds: json['estimated_read_seconds'] as int? ?? 30,
      questionText: json['question_text'] as String?,
      answerOptions: (json['answer_options'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      correctAnswerExplanation:
          json['correct_answer_explanation'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'card_type': cardType.toDbValue(),
      'status': status.toDbValue(),
      'title': title,
      'subtitle': subtitle,
      'body': body,
      'summary': summary,
      'image_url': imageUrl,
      'source_url': sourceUrl,
      'source_name': sourceName,
      'topic': topic,
      'subtopic': subtopic,
      'tags': tags,
      'difficulty_level': difficultyLevel,
      'estimated_read_seconds': estimatedReadSeconds,
      'question_text': questionText,
      'answer_options': answerOptions,
      'correct_answer_explanation': correctAnswerExplanation,
      'created_at': createdAt.toIso8601String(),
      'published_at': publishedAt?.toIso8601String(),
    };
  }

  CardModel copyWith({
    String? id,
    CardType? cardType,
    CardStatus? status,
    String? title,
    String? subtitle,
    String? body,
    String? summary,
    String? imageUrl,
    String? sourceUrl,
    String? sourceName,
    String? topic,
    String? subtopic,
    List<String>? tags,
    int? difficultyLevel,
    int? estimatedReadSeconds,
    String? questionText,
    List<Map<String, dynamic>>? answerOptions,
    String? correctAnswerExplanation,
    DateTime? createdAt,
    DateTime? publishedAt,
  }) {
    return CardModel(
      id: id ?? this.id,
      cardType: cardType ?? this.cardType,
      status: status ?? this.status,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      body: body ?? this.body,
      summary: summary ?? this.summary,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceName: sourceName ?? this.sourceName,
      topic: topic ?? this.topic,
      subtopic: subtopic ?? this.subtopic,
      tags: tags ?? this.tags,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      estimatedReadSeconds: estimatedReadSeconds ?? this.estimatedReadSeconds,
      questionText: questionText ?? this.questionText,
      answerOptions: answerOptions ?? this.answerOptions,
      correctAnswerExplanation:
          correctAnswerExplanation ?? this.correctAnswerExplanation,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}
