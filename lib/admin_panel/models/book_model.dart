import 'package:cloud_firestore/cloud_firestore.dart';

enum BookType { ebook, audiobook }

class BookModel {
  final String id;
  final String title;
  final String author;
  final String description;
  final String coverImageUrl;
  final String? content; // For ebook text content (optional if using PDF)
  final String? pdfUrl; // PDF file URL for ebook reading
  final String?
  audioFileUrl; // Audio file URL for audiobook (legacy - kept for backward compatibility)
  final List<Map<String, String>>?
  chapters; // For audiobook: [{chapterName: String, audioUrl: String}]
  final String category;
  final BookType type; // ebook or audiobook
  final int readTime; // in minutes
  final int listenTime; // in minutes
  final int
  listenCount; // Number of times users have listened to this audiobook
  final int viewCount; // Total number of unique users who viewed this book
  final int
  readCount; // Total number of unique users who read this book (ebooks)
  final int
  listenedUserCount; // Total number of unique users who listened to this book (audiobooks)
  final bool isPublished;
  final bool
  hasEverBeenPublished; // Track if book has ever been published (for "Coming Soon" logic)
  final double price; // Price of the book in USD
  final DateTime createdAt;
  final DateTime updatedAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.coverImageUrl,
    this.content,
    this.pdfUrl,
    this.audioFileUrl,
    this.chapters,
    required this.category,
    required this.type,
    required this.readTime,
    required this.listenTime,
    this.listenCount = 0,
    this.viewCount = 0,
    this.readCount = 0,
    this.listenedUserCount = 0,
    required this.isPublished,
    this.hasEverBeenPublished = false,
    this.price = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'content': content,
      'pdfUrl': pdfUrl,
      'audioFileUrl': audioFileUrl,
      'chapters': chapters,
      'category': category,
      'type': type == BookType.ebook ? 'ebook' : 'audiobook',
      'readTime': readTime,
      'listenTime': listenTime,
      'listenCount': listenCount,
      'viewCount': viewCount,
      'readCount': readCount,
      'listenedUserCount': listenedUserCount,
      'isPublished': isPublished,
      'hasEverBeenPublished': hasEverBeenPublished,
      'price': price,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory BookModel.fromFirestore(String id, Map<String, dynamic> data) {
    return BookModel(
      id: id,
      title: data['title'] as String? ?? '',
      author: data['author'] as String? ?? '',
      description: data['description'] as String? ?? '',
      coverImageUrl: data['coverImageUrl'] as String? ?? '',
      content: data['content'] as String?,
      pdfUrl: data['pdfUrl'] as String?,
      audioFileUrl: data['audioFileUrl'] as String?,
      chapters: data['chapters'] != null
          ? List<Map<String, String>>.from(
              (data['chapters'] as List).map(
                (item) => Map<String, String>.from(item as Map),
              ),
            )
          : null,
      category: data['category'] as String? ?? '',
      type: (data['type'] as String? ?? 'ebook') == 'ebook'
          ? BookType.ebook
          : BookType.audiobook,
      readTime: data['readTime'] as int? ?? 0,
      listenTime: data['listenTime'] as int? ?? 0,
      listenCount: data['listenCount'] as int? ?? 0,
      viewCount: data['viewCount'] as int? ?? 0,
      readCount: data['readCount'] as int? ?? 0,
      listenedUserCount: data['listenedUserCount'] as int? ?? 0,
      isPublished: data['isPublished'] as bool? ?? false,
      hasEverBeenPublished: data['hasEverBeenPublished'] as bool? ?? false,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Legacy methods for backward compatibility
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'content': content,
      'pdfUrl': pdfUrl,
      'audioFileUrl': audioFileUrl,
      'chapters': chapters,
      'category': category,
      'type': type == BookType.ebook ? 'ebook' : 'audiobook',
      'readTime': readTime,
      'listenTime': listenTime,
      'listenCount': listenCount,
      'viewCount': viewCount,
      'readCount': readCount,
      'listenedUserCount': listenedUserCount,
      'isPublished': isPublished,
      'hasEverBeenPublished': hasEverBeenPublished,
      'price': price,
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
      content: map['content'],
      pdfUrl: map['pdfUrl'],
      audioFileUrl: map['audioFileUrl'],
      chapters: map['chapters'] != null
          ? List<Map<String, String>>.from(
              (map['chapters'] as List).map(
                (item) => Map<String, String>.from(item as Map),
              ),
            )
          : null,
      category: map['category'] ?? '',
      type: (map['type'] ?? 'ebook') == 'ebook'
          ? BookType.ebook
          : BookType.audiobook,
      readTime: map['readTime'] ?? 0,
      listenTime: map['listenTime'] ?? 0,
      listenCount: map['listenCount'] ?? 0,
      viewCount: map['viewCount'] ?? 0,
      readCount: map['readCount'] ?? 0,
      listenedUserCount: map['listenedUserCount'] ?? 0,
      isPublished: map['isPublished'] ?? false,
      hasEverBeenPublished: map['hasEverBeenPublished'] ?? false,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }
}
