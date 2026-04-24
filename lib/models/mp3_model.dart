class Mp3Model {
  final String id;
  final String title;
  final String url;
  final bool isPublished;
  final DateTime createdAt;

  const Mp3Model({
    required this.id,
    required this.title,
    required this.url,
    this.isPublished = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'url': url,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Mp3Model.fromMap(Map<String, dynamic> map, String id) {
    return Mp3Model(
      id: id,
      title: map['title'] ?? '',
      url: map['url'] ?? '',
      isPublished: map['isPublished'] ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Mp3Model copyWith({
    String? id,
    String? title,
    String? url,
    bool? isPublished,
    DateTime? createdAt,
  }) {
    return Mp3Model(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
