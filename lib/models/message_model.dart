import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }

  // Create from Firestore
  factory MessageModel.fromFirestore(String id, Map<String, dynamic> data) {
    // Handle null timestamp (when using FieldValue.serverTimestamp())
    final timestampData = data['timestamp'];
    final timestamp = timestampData != null
        ? (timestampData as Timestamp).toDate()
        : DateTime.now(); // Fallback to current time if null

    return MessageModel(
      id: id,
      senderId: data['senderId'] as String,
      receiverId: data['receiverId'] as String,
      message: data['message'] as String,
      timestamp: timestamp,
      isRead: data['isRead'] as bool? ?? false,
    );
  }
}
