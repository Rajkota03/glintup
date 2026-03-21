class TopicModel {
  final String id;
  final String slug;
  final String displayName;
  final String? iconName;
  final String? colorHex;
  final String? parentTopicId;
  final int sortOrder;
  final bool isActive;

  const TopicModel({
    required this.id,
    required this.slug,
    required this.displayName,
    this.iconName,
    this.colorHex,
    this.parentTopicId,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      displayName: json['display_name'] as String,
      iconName: json['icon_name'] as String?,
      colorHex: json['color_hex'] as String?,
      parentTopicId: json['parent_topic_id'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'display_name': displayName,
      'icon_name': iconName,
      'color_hex': colorHex,
      'parent_topic_id': parentTopicId,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  TopicModel copyWith({
    String? id,
    String? slug,
    String? displayName,
    String? iconName,
    String? colorHex,
    String? parentTopicId,
    int? sortOrder,
    bool? isActive,
  }) {
    return TopicModel(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      displayName: displayName ?? this.displayName,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      parentTopicId: parentTopicId ?? this.parentTopicId,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}
