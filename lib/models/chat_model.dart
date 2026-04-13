import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount;
  final Map<String, bool> isTyping;
  final bool isFriend; // New field: false by default, true when accepted
  final bool isBlocked; // True if chat is blocked
  final String? blockedBy; // User ID who blocked the chat

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    Map<String, int>? unreadCount,
    Map<String, bool>? isTyping,
    this.isFriend = false, // Default to false
    this.isBlocked = false, // Default to false
    this.blockedBy, // Nullable
  }) : unreadCount = unreadCount ?? {},
       isTyping = isTyping ?? {};

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'isTyping': isTyping,
      'isFriend': isFriend,
      'isBlocked': isBlocked,
      'blockedBy': blockedBy,
    };
  }

  // Create from Firestore
  factory ChatModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ChatModel(
      id: id,
      participants: List<String>.from(data['participants'] as List),
      lastMessage: data['lastMessage'] as String?,
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      isTyping: Map<String, bool>.from(data['isTyping'] ?? {}),
      isFriend: data['isFriend'] as bool? ?? false,
      isBlocked: data['isBlocked'] as bool? ?? false,
      blockedBy: data['blockedBy'] as String?,
    );
  }

  // Get chat ID from two user IDs
  static String getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}
