import 'package:cloud_firestore/cloud_firestore.dart';

enum BookType {
  ebook,
  audiobook,
}

class BookModel {
  final String id;
  final String title;
  final String author;
  final String description;
  final String coverImageUrl;
  final String? content; // For ebook text content (optional if using PDF)
  final String? pdfUrl; // PDF file URL for ebook reading
  final String? audioFileUrl; // Audio file URL for audiobook
  final String category;
  final BookType type; // ebook or audiobook
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
    this.content,
    this.pdfUrl,
    this.audioFileUrl,
    required this.category,
    required this.type,
    required this.readTime,
    required this.listenTime,
    required this.isPublished,
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
      'category': category,
      'type': type == BookType.ebook ? 'ebook' : 'audiobook',
      'readTime': readTime,
      'listenTime': listenTime,
      'isPublished': isPublished,
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
      category: data['category'] as String? ?? '',
      type: (data['type'] as String? ?? 'ebook') == 'ebook'
          ? BookType.ebook
          : BookType.audiobook,
      readTime: data['readTime'] as int? ?? 0,
      listenTime: data['listenTime'] as int? ?? 0,
      isPublished: data['isPublished'] as bool? ?? false,
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
      'category': category,
      'type': type == BookType.ebook ? 'ebook' : 'audiobook',
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
      content: map['content'],
      pdfUrl: map['pdfUrl'],
      audioFileUrl: map['audioFileUrl'],
      category: map['category'] ?? '',
      type: (map['type'] ?? 'ebook') == 'ebook'
          ? BookType.ebook
          : BookType.audiobook,
      readTime: map['readTime'] ?? 0,
      listenTime: map['listenTime'] ?? 0,
      isPublished: map['isPublished'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }
}
