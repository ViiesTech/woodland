import 'package:cloud_firestore/cloud_firestore.dart';

class GameModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl; // URL to game cover image
  final String gameUrl; // URL to the hosted Unity game
  final String description;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;

  GameModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.gameUrl,
    required this.description,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.isPublished = false,
  });

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'gameUrl': gameUrl,
      'description': description,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPublished': isPublished,
    };
  }

  // Create from Firestore
  factory GameModel.fromFirestore(String id, Map<String, dynamic> data) {
    return GameModel(
      id: id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      gameUrl: data['gameUrl'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Trending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublished: data['isPublished'] ?? false,
    );
  }

  // Create a copy with updated fields
  GameModel copyWith({
    String? title,
    String? subtitle,
    String? imageUrl,
    String? gameUrl,
    String? description,
    String? category,
    DateTime? updatedAt,
    bool? isPublished,
  }) {
    return GameModel(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      gameUrl: gameUrl ?? this.gameUrl,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isPublished: isPublished ?? this.isPublished,
    );
  }
}

