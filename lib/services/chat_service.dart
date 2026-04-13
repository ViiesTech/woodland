import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_woodlands_series/models/chat_model.dart';
import 'package:the_woodlands_series/models/message_model.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get or create chat between two users
  static Future<String> getOrCreateChat(String userId1, String userId2) async {
    final chatId = ChatModel.getChatId(userId1, userId2);
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      // Create new chat with isFriend set to false by default
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [userId1, userId2],
        'lastMessage': null,
        'lastMessageTime': null,
        'lastMessageSenderId': null,
        'unreadCount': {userId1: 0, userId2: 0},
        'isTyping': {userId1: false, userId2: false},
        'isFriend': false, // Default to false - user needs to accept
        'isBlocked': false, // Default to false
        'blockedBy': null, // Default to null
      });
    }

    return chatId;
  }

  // Update friend status
  static Future<void> updateFriendStatus({
    required String chatId,
    required bool isFriend,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isFriend': isFriend,
      });
      print('Friend status updated: $isFriend for chat: $chatId');
    } catch (e) {
      print('Error updating friend status: $e');
      rethrow;
    }
  }

  // Block user
  static Future<void> blockUser({
    required String chatId,
    required String blockedBy,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isBlocked': true,
        'blockedBy': blockedBy,
      });
      print('User blocked in chat: $chatId by: $blockedBy');
    } catch (e) {
      print('Error blocking user: $e');
      rethrow;
    }
  }

  // Unblock user
  static Future<void> unblockUser({required String chatId}) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isBlocked': false,
        'blockedBy': null,
      });
      print('User unblocked in chat: $chatId');
    } catch (e) {
      print('Error unblocking user: $e');
      rethrow;
    }
  }

  // Send a message
  static Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    try {
      // Add message to messages subcollection
      final messageRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'receiverId': receiverId,
            'message': message,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });

      // Update chat metadata
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'unreadCount.$receiverId': FieldValue.increment(1),
      });

      print('Message sent successfully: ${messageRef.id}');
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Stream of messages for a chat
  static Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return MessageModel.fromFirestore(doc.id, doc.data());
                } catch (e) {
                  print('Error parsing message ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<MessageModel>() // Filter out null values
              .toList();
        });
  }

  // Stream of all chats for a user (only chats with messages)
  static Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatModel.fromFirestore(doc.id, doc.data()))
              .where(
                (chat) => chat.lastMessage != null,
              ) // Only show chats with messages
              .toList();
        });
  }

  // Stream of all users who have chat with current user and are friends
  static Stream<List<String>> getFriendUserIds(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .where('isFriend', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                final participants = List<String>.from(
                  data['participants'] as List,
                );
                return participants.firstWhere(
                  (id) => id != userId,
                  orElse: () => '',
                );
              })
              .where((id) => id.isNotEmpty)
              .toList();
        });
  }

  // Update typing status
  static Future<void> updateTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isTyping.$userId': isTyping,
      });
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      final batch = _firestore.batch();

      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      batch.update(_firestore.collection('chats').doc(chatId), {
        'unreadCount.$userId': 0,
      });

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Update user online status
  static Future<void> updateOnlineStatus({
    required String userId,
    required bool isOnline,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  // Stream of user online status
  static Stream<bool> getUserOnlineStatus(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return false;
      return snapshot.data()?['isOnline'] as bool? ?? false;
    });
  }
}
