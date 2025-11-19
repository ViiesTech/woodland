import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_model.dart';

class GameService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _gamesCollection = 'games';

  // Add a new game
  static Future<String> addGame(GameModel game) async {
    try {
      final docRef = await _firestore
          .collection(_gamesCollection)
          .add(game.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add game: $e');
    }
  }

  // Get all games (stream)
  static Stream<List<GameModel>> getAllGames() {
    return _firestore
        .collection(_gamesCollection)
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GameModel.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  // Get games by category (stream)
  static Stream<List<GameModel>> getGamesByCategory(String category) {
    return _firestore
        .collection(_gamesCollection)
        .where('isPublished', isEqualTo: true)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GameModel.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  // Get game by ID
  static Future<GameModel?> getGameById(String gameId) async {
    try {
      final doc = await _firestore
          .collection(_gamesCollection)
          .doc(gameId)
          .get();
      if (doc.exists && doc.data() != null) {
        return GameModel.fromFirestore(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting game: $e');
      return null;
    }
  }

  // Update a game
  static Future<void> updateGame(GameModel game) async {
    try {
      await _firestore
          .collection(_gamesCollection)
          .doc(game.id)
          .update(game.toFirestore());
    } catch (e) {
      throw Exception('Failed to update game: $e');
    }
  }

  // Delete a game
  static Future<void> deleteGame(String gameId) async {
    try {
      await _firestore.collection(_gamesCollection).doc(gameId).delete();
    } catch (e) {
      throw Exception('Failed to delete game: $e');
    }
  }

  // Search games (case-insensitive)
  static Stream<List<GameModel>> searchGames(String query) {
    final queryLower = query.trim().toLowerCase();
    
    // If query is empty, return empty list
    if (queryLower.isEmpty) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection(_gamesCollection)
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GameModel.fromFirestore(doc.id, doc.data()))
          .where((game) {
            final titleLower = game.title.toLowerCase().trim();
            final subtitleLower = game.subtitle.toLowerCase().trim();
            return titleLower.contains(queryLower) ||
                subtitleLower.contains(queryLower);
          })
          .toList();
    });
  }
}

