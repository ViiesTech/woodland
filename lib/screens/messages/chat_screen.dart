import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/utils/three_dot_loader.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:the_woodlands_series/models/user_model.dart';
import 'package:the_woodlands_series/models/message_model.dart';
import 'package:the_woodlands_series/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.user});
  final UserModel user;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  UserModel? currentUser;
  String? chatId;
  Timer? _typingTimer;
  bool _isTyping = false;
  bool isFriend = false; // Track friend status
  int myMessageCount = 0; // Track messages sent by current user
  bool _isInitialLoad = true; // Track if this is the first load
  bool isBlocked = false; // Track if chat is blocked
  String? blockedBy; // Track who blocked the chat

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _initChat();
    _initAudioPlayer();
    _messageController.addListener(_onTyping);
  }

  void _loadCurrentUser() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      setState(() {
        currentUser = authState.user;
      });
    }
  }

  Future<void> _initChat() async {
    if (currentUser != null) {
      // Get or create chat
      final id = await ChatService.getOrCreateChat(
        currentUser!.id,
        widget.user.id,
      );
      setState(() {
        chatId = id;
      });

      // Listen to chat document for isFriend, isBlocked, and blockedBy updates
      FirebaseFirestore.instance.collection('chats').doc(id).snapshots().listen(
        (snapshot) {
          if (snapshot.exists && mounted) {
            final data = snapshot.data();
            setState(() {
              isFriend = data?['isFriend'] ?? false;
              isBlocked = data?['isBlocked'] ?? false;
              blockedBy = data?['blockedBy'] as String?;
            });
          }
        },
      );

      // Count existing messages from current user (only if not friend)
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(id)
          .collection('messages')
          .where('senderId', isEqualTo: currentUser!.id)
          .get();

      setState(() {
        myMessageCount = messagesSnapshot.docs.length;
      });

      // Mark messages as read
      await ChatService.markMessagesAsRead(chatId: id, userId: currentUser!.id);

      // Set user as online
      await ChatService.updateOnlineStatus(
        userId: currentUser!.id,
        isOnline: true,
      );
    }
  }

  void _onTyping() {
    if (chatId == null) return;

    // Cancel previous timer
    _typingTimer?.cancel();

    // Update typing status to true if not already
    if (!_isTyping && _messageController.text.isNotEmpty) {
      _isTyping = true;
      ChatService.updateTypingStatus(
        chatId: chatId!,
        userId: currentUser!.id,
        isTyping: true,
      );
    }

    // Set timer to stop typing indicator after 2 seconds of inactivity
    _typingTimer = Timer(Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        ChatService.updateTypingStatus(
          chatId: chatId!,
          userId: currentUser!.id,
          isTyping: false,
        );
      }
    });
  }

  void _initAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
  }

  Future<void> _playAudio() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(AssetSource('audio/test.mp3'));
      }
    } catch (e) {
      print('Audio playback error: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || chatId == null) return;

    // Check if chat is blocked
    if (isBlocked) {
      return;
    }

    // Check if user can send messages (if not friend, limit to 3 messages)
    if (!isFriend && myMessageCount >= 3) {
      return;
    }

    final message = _messageController.text.trim();
    _messageController.clear();

    // Stop typing indicator
    if (_isTyping) {
      _isTyping = false;
      await ChatService.updateTypingStatus(
        chatId: chatId!,
        userId: currentUser!.id,
        isTyping: false,
      );
    }

    try {
      await ChatService.sendMessage(
        chatId: chatId!,
        senderId: currentUser!.id,
        receiverId: widget.user.id,
        message: message,
      );

      // Increment message count if not friend
      if (!isFriend) {
        setState(() {
          myMessageCount++;
        });
      }

      // Check if this is a reply (other user sent first message)
      // If so, mark as friends
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId!)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      // Check if other user has sent any message
      final hasOtherUserReplied = messagesSnapshot.docs.any(
        (doc) => doc.data()['senderId'] == widget.user.id,
      );

      // If both users have sent messages and not yet friends, become friends
      if (hasOtherUserReplied && !isFriend) {
        await ChatService.updateFriendStatus(chatId: chatId!, isFriend: true);
      }

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Handle OK button press (accept friend request)
  Future<void> _handleOkPress() async {
    if (chatId == null) return;
    try {
      await ChatService.updateFriendStatus(chatId: chatId!, isFriend: true);
    } catch (e) {
      print('Error accepting friend request: $e');
    }
  }

  // Handle Block button press
  Future<void> _handleBlockPress() async {
    if (chatId == null || currentUser == null) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.boxClr,
        title: Text(
          'Block ${widget.user.name}?',
          style: AppTextStyles.lufgaMedium.copyWith(
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        content: Text(
          'You won\'t be able to send or receive messages from this user.',
          style: AppTextStyles.regular.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'No',
              style: AppTextStyles.medium.copyWith(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14.sp,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Yes',
              style: AppTextStyles.medium.copyWith(
                color: Colors.red,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ChatService.blockUser(
          chatId: chatId!,
          blockedBy: currentUser!.id,
        );
      } catch (e) {
        print('Error blocking user: $e');
      }
    }
  }

  // Handle Unblock press
  Future<void> _handleUnblockPress() async {
    if (chatId == null) return;
    try {
      await ChatService.unblockUser(chatId: chatId!);
    } catch (e) {
      print('Error unblocking user: $e');
    }
  }

  // Show menu with block option
  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.boxClr,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.block, color: Colors.red, size: 24.sp),
              title: Text(
                'Block ${widget.user.name}',
                style: AppTextStyles.medium.copyWith(
                  color: Colors.red,
                  fontSize: 16.sp,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleBlockPress();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _typingTimer?.cancel();

    // Set user as offline when leaving chat
    if (currentUser != null) {
      ChatService.updateOnlineStatus(userId: currentUser!.id, isOnline: false);
    }

    // Stop typing indicator
    if (chatId != null && currentUser != null && _isTyping) {
      ChatService.updateTypingStatus(
        chatId: chatId!,
        userId: currentUser!.id,
        isTyping: false,
      );
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.bgClr,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[800]!, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  // Profile picture
                  Row(
                    children: [
                      _buildUserAvatar(widget.user, radius: 18.r),
                      12.horizontalSpace,
                      // Name and status with real-time online indicator
                      StreamBuilder<bool>(
                        stream: ChatService.getUserOnlineStatus(widget.user.id),
                        builder: (context, onlineSnapshot) {
                          final isOnline = onlineSnapshot.data ?? false;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user.name,
                                style: AppTextStyles.medium.copyWith(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                ),
                              ),
                              if (chatId != null)
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('chats')
                                      .doc(chatId)
                                      .snapshots(),
                                  builder: (context, chatSnapshot) {
                                    // Safely check isTyping status
                                    bool isTyping = false;
                                    try {
                                      if (chatSnapshot.hasData &&
                                          chatSnapshot.data!.exists) {
                                        final data =
                                            chatSnapshot.data!.data()
                                                as Map<String, dynamic>?;
                                        if (data != null &&
                                            data['isTyping'] != null) {
                                          final typingMap =
                                              data['isTyping']
                                                  as Map<String, dynamic>?;
                                          isTyping =
                                              typingMap?[widget.user.id] ==
                                              true;
                                        }
                                      }
                                    } catch (e) {
                                      // Silently handle any errors
                                      isTyping = false;
                                    }

                                    return Row(
                                      children: [
                                        if (isOnline)
                                          Container(
                                            width: 6.w,
                                            height: 6.h,
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        4.horizontalSpace,
                                        Text(
                                          isTyping
                                              ? 'Typing...'
                                              : (isOnline
                                                    ? 'Online'
                                                    : 'Offline'),
                                          style: AppTextStyles.small.copyWith(
                                            color: isTyping
                                                ? AppColors.primaryColor
                                                : Colors.grey[400],
                                            fontSize: 10.sp,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  // Menu button
                  if (isFriend && !isBlocked)
                    GestureDetector(
                      onTap: _showMenu,
                      child: Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    )
                  else
                    SizedBox(width: 24.sp), // Placeholder for alignment
                ],
              ),
            ),

            // OK/Block buttons (shown when not friend and not blocked)
            if (!isFriend && !isBlocked && myMessageCount == 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.boxClr.withOpacity(0.5),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[800]!, width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'Do you want to chat with ${widget.user.name}?',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    16.horizontalSpace,
                    ElevatedButton(
                      onPressed: _handleOkPress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 8.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                      child: Text(
                        'OK',
                        style: AppTextStyles.medium.copyWith(
                          color: Colors.black,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    8.horizontalSpace,
                    TextButton(
                      onPressed: _handleBlockPress,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                      ),
                      child: Text(
                        'Block',
                        style: AppTextStyles.medium.copyWith(
                          color: Colors.red,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Chat Messages with StreamBuilder
            Expanded(
              child: chatId == null
                  ? Center(
                      child: ThreeDotLoader(
                        color: AppColors.primaryColor,
                        size: 12.w,
                        spacing: 8.w,
                      ),
                    )
                  : StreamBuilder<List<MessageModel>>(
                      stream: ChatService.getMessages(chatId!),
                      builder: (context, snapshot) {
                        // Only show loader on initial load
                        if (_isInitialLoad &&
                            snapshot.connectionState ==
                                ConnectionState.waiting) {
                          return Center(
                            child: ThreeDotLoader(
                              color: AppColors.primaryColor,
                              size: 12.w,
                              spacing: 8.w,
                            ),
                          );
                        }

                        // Mark as not initial load once we have data
                        if (snapshot.hasData && _isInitialLoad) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _isInitialLoad = false;
                              });
                            }
                          });
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading messages',
                              style: AppTextStyles.regular.copyWith(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14.sp,
                              ),
                            ),
                          );
                        }

                        final messages = snapshot.data ?? [];

                        if (messages.isEmpty) {
                          return Center(
                            child: Text(
                              'No messages yet\nSay hi to ${widget.user.name}!',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.regular.copyWith(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14.sp,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true, // Start from bottom
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe = message.senderId == currentUser!.id;

                            return Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: isMe
                                  ? _buildYourMessage(
                                      message.message,
                                      _formatMessageTime(message.timestamp),
                                      isRead: message.isRead,
                                    )
                                  : _buildReceiverMessage(
                                      message.message,
                                      _formatMessageTime(message.timestamp),
                                    ),
                            );
                          },
                        );
                      },
                    ),
            ),

            // Message Input
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(color: AppColors.bgClr),
              child: isBlocked
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.boxClr,
                        borderRadius: BorderRadius.circular(50.r),
                        border: Border.all(color: Color(0xff6C6C6C), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.block,
                            color: Colors.red.withOpacity(0.8),
                            size: 18.sp,
                          ),
                          8.horizontalSpace,
                          Expanded(
                            child: Text(
                              blockedBy == currentUser?.id
                                  ? 'You blocked this user.'
                                  : 'You can\'t send messages to this user.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.regular.copyWith(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          if (blockedBy == currentUser?.id) ...[
                            8.horizontalSpace,
                            GestureDetector(
                              onTap: _handleUnblockPress,
                              child: Text(
                                'Unblock',
                                style: AppTextStyles.medium.copyWith(
                                  color: AppColors.primaryColor,
                                  fontSize: 14.sp,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : !isFriend && myMessageCount >= 3
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.boxClr,
                        borderRadius: BorderRadius.circular(50.r),
                        border: Border.all(color: Color(0xff6C6C6C), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            color: Colors.white.withOpacity(0.6),
                            size: 18.sp,
                          ),
                          8.horizontalSpace,
                          Expanded(
                            child: Text(
                              'Waiting for ${widget.user.name} to reply...',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.regular.copyWith(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : PrimaryTextField(
                      controller: _messageController,
                      hint: 'Type a message',
                      suffixIcon: GestureDetector(
                        onTap: _sendMessage,
                        child: Padding(
                          padding: EdgeInsets.all(5.r),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.send,
                              color: AppColors.bgClr,
                              size: 14.sp,
                            ),
                          ),
                        ),
                      ),
                      minlines: 1,
                      maxlines: 10,
                      textInputAction: TextInputAction.newline,
                      borderRadius: 50.r,
                      bordercolor: Color(0xff6C6C6C),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYourMessage(String message, String time, {bool isRead = false}) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: 280.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message,
              style: AppTextStyles.regular.copyWith(
                color: Colors.black,
                fontSize: 14.sp,
              ),
            ),
            4.verticalSpace,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: AppTextStyles.small.copyWith(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 10.sp,
                  ),
                ),
                4.horizontalSpace,
                Icon(
                  isRead ? Icons.done_all : Icons.done,
                  color: isRead ? Colors.blue : Colors.black.withOpacity(0.6),
                  size: 12.sp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiverMessage(String message, String time) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 280.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.boxClr,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: AppTextStyles.regular.copyWith(
                color: Colors.white,
                fontSize: 14.sp,
              ),
            ),
            4.verticalSpace,
            Text(
              time,
              style: AppTextStyles.small.copyWith(
                color: Colors.grey[400],
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserModel user, {required double radius}) {
    // If user has a profile image, show it
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(user.profileImageUrl!),
        backgroundColor: AppColors.boxClr,
      );
    }

    // Show avatar with initials
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.7),
            ],
          ),
        ),
        child: Center(
          child: Text(
            _getInitials(user.name),
            style: AppTextStyles.lufgaMedium.copyWith(
              color: Colors.white,
              fontSize: (radius * 0.6).sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'U';
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    // Under 24 hours - show 12-hour time with AM/PM
    if (difference.inHours < 24) {
      final hour = time.hour;
      final minute = time.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour12:${minute.toString().padLeft(2, '0')} $period';
    }

    // Yesterday
    if (difference.inHours < 48 && difference.inDays == 1) {
      return 'Yesterday';
    }

    // Within 7 days - show day name
    if (difference.inDays < 7) {
      final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return days[time.weekday % 7];
    }

    // After 7 days - show dd/mm/yyyy
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';
  }
}
