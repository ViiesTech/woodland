import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/utils/three_dot_loader.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:the_woodlands_series/models/user_model.dart';
import 'package:the_woodlands_series/models/chat_model.dart';
import 'package:the_woodlands_series/screens/messages/chat_screen.dart';
import 'package:the_woodlands_series/screens/messages/add_user_bottom_sheet.dart';
import 'package:the_woodlands_series/services/chat_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? currentUser;
  Map<String, UserModel> cachedUsers =
      {}; // Cache users to avoid repeated fetches

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      setState(() {
        currentUser = authState.user;
      });
    }
  }

  // Fetch users efficiently in batch
  Future<Map<String, UserModel>> _fetchUsersForChats(
    List<ChatModel> chats,
  ) async {
    if (chats.isEmpty) return {};

    // Get all unique user IDs from chats
    final userIds = <String>{};
    for (var chat in chats) {
      final otherUserId = chat.participants.firstWhere(
        (id) => id != currentUser?.id,
        orElse: () => '',
      );
      if (otherUserId.isNotEmpty) {
        userIds.add(otherUserId);
      }
    }

    if (userIds.isEmpty) return {};

    // Return cached users if we already have them
    final uncachedIds = userIds
        .where((id) => !cachedUsers.containsKey(id))
        .toList();
    if (uncachedIds.isEmpty) return cachedUsers;

    try {
      // Firestore 'in' query limit is 10, so batch the requests
      for (int i = 0; i < uncachedIds.length; i += 10) {
        final batch = uncachedIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get(GetOptions(source: Source.serverAndCache));

        for (var doc in snapshot.docs) {
          final user = UserModel.fromFirestore(doc.id, doc.data());
          cachedUsers[doc.id] = user; // Add to cache
        }
      }

      return {...cachedUsers}; // Return all cached users
    } catch (e) {
      print('Error fetching users: $e');
      return cachedUsers;
    }
  }

  void _showAddUserBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgClr,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return AddUserBottomSheet(
              scrollController: scrollController,
              currentUser: currentUser!,
            );
          },
        );
      },
    );
  }

  Widget _buildUserAvatar(UserModel user) {
    // If user has a profile image, show it
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      return Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.3),
            width: 2,
          ),
          image: DecorationImage(
            image: NetworkImage(user.profileImageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Show avatar with initials
    return Container(
      width: 50.w,
      height: 50.w,
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
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.bgClr,
        body: Center(
          child: ThreeDotLoader(
            color: AppColors.primaryColor,
            size: 12.w,
            spacing: 8.w,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgClr,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Messages',
                      style: AppTextStyles.lufgaLarge.copyWith(
                        color: Colors.white,
                        fontSize: 24.sp,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _showAddUserBottomSheet,
                    icon: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add, color: Colors.white, size: 20.sp),
                    ),
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: PrimaryTextField(
                hint: 'Search messages...',
                prefixIcon: Icon(Icons.search, size: 20.sp),
                shadow: true,
              ),
            ),

            20.verticalSpace,

            // Messages list with StreamBuilder + batch user fetching
            Expanded(
              child: StreamBuilder<List<ChatModel>>(
                stream: ChatService.getUserChats(currentUser!.id),
                builder: (context, chatSnapshot) {
                  if (chatSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: ThreeDotLoader(
                        color: AppColors.primaryColor,
                        size: 12.w,
                        spacing: 8.w,
                      ),
                    );
                  }

                  if (chatSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading chats',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                      ),
                    );
                  }

                  final chats = chatSnapshot.data ?? [];

                  if (chats.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet\nTap + to start chatting!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                      ),
                    );
                  }

                  // Use FutureBuilder to batch fetch all users at once
                  return FutureBuilder<Map<String, UserModel>>(
                    future: _fetchUsersForChats(chats),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                          child: ThreeDotLoader(
                            color: AppColors.primaryColor,
                            size: 12.w,
                            spacing: 8.w,
                          ),
                        );
                      }

                      final users = userSnapshot.data ?? {};

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          final otherUserId = chat.participants.firstWhere(
                            (id) => id != currentUser!.id,
                            orElse: () => '',
                          );

                          final otherUser = users[otherUserId];
                          if (otherUser == null) {
                            return SizedBox.shrink();
                          }

                          return _buildChatItem(chat, otherUser);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(ChatModel chat, UserModel otherUser) {
    final otherUserId = otherUser.id;
    final isTyping = chat.isTyping[otherUserId] ?? false;
    final unreadCount = chat.unreadCount[currentUser!.id] ?? 0;
    final isMyMessage = chat.lastMessageSenderId == currentUser!.id;

    return GestureDetector(
      onTap: () async {
        // Mark messages as read when opening chat
        await ChatService.markMessagesAsRead(
          chatId: chat.id,
          userId: currentUser!.id,
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(user: otherUser)),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.boxClr,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                _buildUserAvatar(otherUser),
                // Online indicator
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: StreamBuilder<bool>(
                    stream: ChatService.getUserOnlineStatus(otherUserId),
                    builder: (context, onlineSnapshot) {
                      final isOnline = onlineSnapshot.data ?? false;
                      if (!isOnline) return SizedBox.shrink();

                      return Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.boxClr, width: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUser.name,
                    style: AppTextStyles.medium.copyWith(
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    isTyping
                        ? 'Typing...'
                        : (chat.lastMessage ?? 'No messages yet'),
                    style: AppTextStyles.regular.copyWith(
                      color: isTyping
                          ? AppColors.primaryColor
                          : Colors.grey[400],
                      fontSize: 14.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (chat.lastMessageTime != null)
                  Text(
                    _formatTime(chat.lastMessageTime!),
                    style: AppTextStyles.small.copyWith(
                      color: Colors.grey[400],
                      fontSize: 12.sp,
                    ),
                  ),
                8.verticalSpace,
                if (unreadCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: AppTextStyles.small.copyWith(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isMyMessage)
                  Icon(
                    Icons.done_all,
                    color: AppColors.primaryColor,
                    size: 16.sp,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      return '${time.day}/${time.month}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
