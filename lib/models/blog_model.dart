class BlogModel {
  final String id;
  final String title;
  final String content;
  final String author;
  final String? imageUrl;
  final DateTime createdAt;
  final int commentCount;

  BlogModel({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    this.imageUrl,
    required this.createdAt,
    this.commentCount = 0,
  });

  // Convert to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'author': author,
      'imageUrl': imageUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'commentCount': commentCount,
    };
  }

  // Create from Firestore
  factory BlogModel.fromFirestore(String id, Map<String, dynamic> data) {
    return BlogModel(
      id: id,
      title: data['title'] as String,
      content: data['content'] as String,
      author: data['author'] as String? ?? 'Admin',
      imageUrl: data['imageUrl'] as String?,
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : DateTime.now(),
      commentCount: data['commentCount'] as int? ?? 0,
    );
  }
}

