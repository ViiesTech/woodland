import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? profileImageUrl;
  final int gamePoints;
  final DateTime updatedAt;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.profileImageUrl,
    required this.gamePoints,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userName': userName,
      'profileImageUrl': profileImageUrl,
      'gamePoints': gamePoints,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory LeaderboardEntry.fromFirestore(String id, Map<String, dynamic> data) {
    return LeaderboardEntry(
      userId: id,
      userName: data['userName'] ?? 'Anonymous',
      profileImageUrl: data['profileImageUrl'],
      gamePoints: data['gamePoints'] ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class LeaderboardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'leaderboard';

  /// Add score to user's combined game points in Firestore
  static Future<void> addScore(
    String userId,
    String userName,
    String? profileImageUrl,
    int scoreGained,
  ) async {
    final docRef = _firestore.collection(_collection).doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(docRef);
      
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final currentPoints = docSnapshot.data()!['gamePoints'] as int? ?? 0;
        transaction.update(docRef, {
          'userName': userName,
          'profileImageUrl': profileImageUrl,
          'gamePoints': currentPoints + scoreGained,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(docRef, {
          'userName': userName,
          'profileImageUrl': profileImageUrl,
          'gamePoints': scoreGained,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Get top players stream
  static Stream<List<LeaderboardEntry>> getTopPlayers({int limit = 50}) {
    return _firestore
        .collection(_collection)
        .orderBy('gamePoints', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LeaderboardEntry.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }
}
