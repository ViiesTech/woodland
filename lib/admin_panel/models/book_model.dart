class BookModel {
  final String id;
  final String title;
  final String author;
  final String description;
  final String coverImageUrl;
  final String content;
  final String audioFileUrl;
  final String category;
  final int readTime; // in minutes
  final int listenTime; // in minutes
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.coverImageUrl,
    required this.content,
    required this.audioFileUrl,
    required this.category,
    required this.readTime,
    required this.listenTime,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'content': content,
      'audioFileUrl': audioFileUrl,
      'category': category,
      'readTime': readTime,
      'listenTime': listenTime,
      'isPublished': isPublished,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      description: map['description'] ?? '',
      coverImageUrl: map['coverImageUrl'] ?? '',
      content: map['content'] ?? '',
      audioFileUrl: map['audioFileUrl'] ?? '',
      category: map['category'] ?? '',
      readTime: map['readTime'] ?? 0,
      listenTime: map['listenTime'] ?? 0,
      isPublished: map['isPublished'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }
}
