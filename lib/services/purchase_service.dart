import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  /// Check if user owns a book
  static Future<bool> isBookOwned(String userId, String bookId) async {
    try {
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final data = userDoc.data();
      final purchasedBooks = data?['purchasedBooks'] as List<dynamic>? ?? [];

      // Check if bookId exists in the array (handles both old format [id] and new format [{bookId, ...}])
      for (var item in purchasedBooks) {
        if (item is String) {
          // Old format: just ID string
          if (item == bookId) return true;
        } else if (item is Map) {
          // New format: object with bookId
          if (item['bookId'] == bookId) return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking book ownership: $e');
      return false;
    }
  }

  /// Get stream of user's purchased books (returns book IDs)
  static Stream<List<String>> getPurchasedBooksStream(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return <String>[];

      final data = snapshot.data();
      final purchasedBooks = data?['purchasedBooks'] as List<dynamic>? ?? [];

      // Extract bookId from objects or use string directly (backward compatibility)
      return purchasedBooks.map((item) {
        if (item is String) {
          return item; // Old format
        } else if (item is Map) {
          return item['bookId']?.toString() ?? '';
        }
        return '';
      }).where((id) => id.isNotEmpty).toList();
    });
  }

  /// Get stream of user's purchased books with full details
  static Stream<List<Map<String, dynamic>>> getPurchasedBooksDetailsStream(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return <Map<String, dynamic>>[];

      final data = snapshot.data();
      final purchasedBooks = data?['purchasedBooks'] as List<dynamic>? ?? [];

      // Convert to list of maps with purchase details
      return purchasedBooks.map((item) {
        if (item is String) {
          // Old format: convert to new format
          return {
            'bookId': item,
            'dateOfPurchase': DateTime.now().toIso8601String(),
            'paymentId': 'migrated_${DateTime.now().millisecondsSinceEpoch}',
          };
        } else if (item is Map) {
          // New format: return as is
          return Map<String, dynamic>.from(item);
        }
        return <String, dynamic>{};
      }).where((item) => item.isNotEmpty).toList();
    });
  }

  /// Add book to user's purchased books with payment details
  static Future<void> addPurchasedBook(
    String userId,
    String bookId, {
    String? paymentId,
    String? transactionId,
    double? amount,
    DateTime? purchaseDate,
  }) async {
    try {
      final userRef = _firestore.collection(_usersCollection).doc(userId);
      final userDoc = await userRef.get();

      // Create payment details document
      final paymentData = {
        'bookId': bookId,
        'paymentId': paymentId ?? 'pay_${DateTime.now().millisecondsSinceEpoch}',
        'transactionId': transactionId ?? 'txn_${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount ?? 0.0,
        'purchaseDate': (purchaseDate ?? DateTime.now()).toIso8601String(),
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Store payment in purchases subcollection for security and detailed tracking
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('purchases')
          .doc(bookId)
          .set(paymentData);

      // Create purchase object with all details
      final purchaseObject = {
        'bookId': bookId,
        'dateOfPurchase': (purchaseDate ?? DateTime.now()).toIso8601String(),
        'paymentId': paymentId ?? 'pay_${DateTime.now().millisecondsSinceEpoch}',
        'transactionId': transactionId ?? 'txn_${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount ?? 0.0,
        'status': 'completed',
      };

      // Also add to purchasedBooks array for quick lookup (with full details)
      if (!userDoc.exists) {
        // Create user document with purchased books array
        await userRef.set({
          'purchasedBooks': [purchaseObject],
        });
      } else {
        // Update existing user document
        final data = userDoc.data();
        final purchasedBooks = data?['purchasedBooks'] as List<dynamic>? ?? [];

        // Check if book already exists (handle both old and new format)
        bool bookExists = false;
        for (var item in purchasedBooks) {
          if (item is String && item == bookId) {
            bookExists = true;
            break;
          } else if (item is Map && item['bookId'] == bookId) {
            bookExists = true;
            break;
          }
        }

        if (!bookExists) {
          await userRef.update({
            'purchasedBooks': FieldValue.arrayUnion([purchaseObject]),
          });
        } else {
          // Update existing purchase if it exists (replace old format with new)
          final updatedBooks = purchasedBooks.map((item) {
            if (item is String && item == bookId) {
              return purchaseObject; // Replace old format
            } else if (item is Map && item['bookId'] == bookId) {
              return purchaseObject; // Update existing
            }
            return item;
          }).toList();
          
          await userRef.update({
            'purchasedBooks': updatedBooks,
          });
        }
      }
    } catch (e) {
      print('Error adding purchased book: $e');
      rethrow;
    }
  }

  /// Get payment details for a purchased book
  static Future<Map<String, dynamic>?> getPaymentDetails(
    String userId,
    String bookId,
  ) async {
    try {
      final paymentDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('purchases')
          .doc(bookId)
          .get();

      if (paymentDoc.exists) {
        return paymentDoc.data();
      }
      return null;
    } catch (e) {
      print('Error getting payment details: $e');
      return null;
    }
  }

  /// Check ownership for multiple books at once
  static Future<Map<String, bool>> checkMultipleBooksOwnership(
    String userId,
    List<String> bookIds,
  ) async {
    try {
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return {for (var id in bookIds) id: false};
      }

      final data = userDoc.data();
      final purchasedBooks = data?['purchasedBooks'] as List<dynamic>? ?? [];
      
      // Extract bookIds (handles both old and new format)
      final purchasedSet = purchasedBooks.map((item) {
        if (item is String) {
          return item; // Old format
        } else if (item is Map) {
          return item['bookId']?.toString() ?? '';
        }
        return '';
      }).where((id) => id.isNotEmpty).toSet();

      return {for (var id in bookIds) id: purchasedSet.contains(id)};
    } catch (e) {
      print('Error checking multiple books ownership: $e');
      return {for (var id in bookIds) id: false};
    }
  }

  /// Get purchase details from purchasedBooks array
  static Future<Map<String, dynamic>?> getPurchaseFromArray(
    String userId,
    String bookId,
  ) async {
    try {
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return null;

      final data = userDoc.data();
      final purchasedBooks = data?['purchasedBooks'] as List<dynamic>? ?? [];

      // Find the purchase object for this book
      for (var item in purchasedBooks) {
        if (item is Map) {
          if (item['bookId'] == bookId) {
            return Map<String, dynamic>.from(item);
          }
        } else if (item is String && item == bookId) {
          // Old format: return basic info
          return {
            'bookId': bookId,
            'dateOfPurchase': DateTime.now().toIso8601String(),
            'paymentId': 'legacy_purchase',
          };
        }
      }
      return null;
    } catch (e) {
      print('Error getting purchase from array: $e');
      return null;
    }
  }
}

