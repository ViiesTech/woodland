import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseUpdateService {
  /// One-time utility to update all book prices to $3.39
  /// This can be called from a temporary button or during app startup
  static Future<void> updateAllBookPricesToStandard() async {
    try {
      final collection = FirebaseFirestore.instance.collection('books');
      final snapshot = await collection.get();

      print('🚀 Starting bulk update for ${snapshot.docs.length} books...');

      // Use a WriteBatch for efficiency and atomicity
      final batch = FirebaseFirestore.instance.batch();

      int count = 0;
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'price': 3.99});
        count++;

        // Firestore batches are limited to 500 operations
        if (count >= 500) {
          await batch.commit();
          print('✅ Committed batch of 500...');
          count = 0;
        }
      }

      // Commit remaining
      if (count > 0) {
        await batch.commit();
      }

      print('🎉 Successfully updated all book prices to \$3.99');
    } catch (e) {
      print('❌ Error updating prices: $e');
    }
  }
}
