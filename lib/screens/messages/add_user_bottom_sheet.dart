import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/utils/three_dot_loader.dart';
import 'package:the_woodlands_series/models/user_model.dart';
import 'package:the_woodlands_series/screens/messages/chat_screen.dart';

class AddUserBottomSheet extends StatefulWidget {
  final ScrollController scrollController;
  final UserModel currentUser;

  const AddUserBottomSheet({
    super.key,
    required this.scrollController,
    required this.currentUser,
  });

  @override
  State<AddUserBottomSheet> createState() => _AddUserBottomSheetState();
}

class _AddUserBottomSheetState extends State<AddUserBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserModel> allUsers = []; // Friend users (when no search)
  List<UserModel> filteredUsers = []; // Displayed users
  bool isLoadingUsers = false;
  bool isSearching = false; // Track if actively searching

  @override
  void initState() {
    super.initState();
    _fetchFriendUsers(); // Load friend users initially
    _searchController.addListener(_onSearchChanged);
  }

  // Called when search text changes
  void _onSearchChanged() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      // Show friend users when search is empty
      setState(() {
        isSearching = false;
        filteredUsers = allUsers;
      });
    } else {
      // Search in users collection when typing
      _searchUsers(query);
    }
  }

  // Fetch friend users (for initial display)
  Future<void> _fetchFriendUsers() async {
    setState(() {
      isLoadingUsers = true;
    });

    try {
      final startTime = DateTime.now();
      print('🔍 Fetching friend users from chats...');

      // Get all chats where current user is a participant and isFriend is true
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: widget.currentUser.id)
          .where('isFriend', isEqualTo: true)
          .get(GetOptions(source: Source.serverAndCache));

      print('📊 Found ${chatsSnapshot.docs.length} friend chats');

      // Extract friend user IDs from chats
      final friendUserIds = <String>{};
      for (var chatDoc in chatsSnapshot.docs) {
        final chatData = chatDoc.data();
        final participants = List<String>.from(
          chatData['participants'] as List,
        );

        final otherUserId = participants.firstWhere(
          (id) => id != widget.currentUser.id,
          orElse: () => '',
        );

        if (otherUserId.isNotEmpty) {
          friendUserIds.add(otherUserId);
        }
      }

      print('👥 Found ${friendUserIds.length} friend user IDs');

      // Fetch user data for all friend IDs
      final List<UserModel> friendUsers = [];

      if (friendUserIds.isNotEmpty) {
        final friendIdsList = friendUserIds.toList();

        for (int i = 0; i < friendIdsList.length; i += 10) {
          final batch = friendIdsList.skip(i).take(10).toList();
          final usersSnapshot = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get(GetOptions(source: Source.serverAndCache));

          friendUsers.addAll(
            usersSnapshot.docs
                .map((doc) => UserModel.fromFirestore(doc.id, doc.data()))
                .toList(),
          );
        }
      }

      friendUsers.sort((a, b) => a.name.compareTo(b.name));

      final fetchTime = DateTime.now().difference(startTime).inMilliseconds;
      print('⏱️  Friend users loaded in ${fetchTime}ms');
      print('✅ Loaded ${friendUsers.length} friend users');

      if (mounted) {
        setState(() {
          allUsers = friendUsers;
          filteredUsers = friendUsers;
          isLoadingUsers = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching friend users: $e');
      if (mounted) {
        setState(() {
          isLoadingUsers = false;
        });
      }
    }
  }

  // Search users in real-time from users collection
  Future<void> _searchUsers(String query) async {
    setState(() {
      isSearching = true;
      isLoadingUsers = true;
    });

    try {
      final startTime = DateTime.now();
      print('🔍 Searching users: "$query"');

      final queryLower = query.toLowerCase();

      // Search by name and email
      // Note: Firestore doesn't support OR queries easily, so we do two queries
      final nameQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'user')
          .orderBy('name')
          .startAt([queryLower])
          .endAt(['$queryLower\uf8ff'])
          .limit(20)
          .get(GetOptions(source: Source.serverAndCache));

      final emailQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'user')
          .orderBy('email')
          .startAt([queryLower])
          .endAt(['$queryLower\uf8ff'])
          .limit(20)
          .get(GetOptions(source: Source.serverAndCache));

      // Combine results and remove duplicates
      final Map<String, UserModel> usersMap = {};

      for (var doc in nameQuery.docs) {
        final user = UserModel.fromFirestore(doc.id, doc.data());
        if (user.id != widget.currentUser.id) {
          usersMap[user.id] = user;
        }
      }

      for (var doc in emailQuery.docs) {
        final user = UserModel.fromFirestore(doc.id, doc.data());
        if (user.id != widget.currentUser.id) {
          usersMap[user.id] = user;
        }
      }

      final searchResults = usersMap.values.toList();
      searchResults.sort((a, b) => a.name.compareTo(b.name));

      final fetchTime = DateTime.now().difference(startTime).inMilliseconds;
      print('⏱️  Search completed in ${fetchTime}ms');
      print('✅ Found ${searchResults.length} users matching "$query"');

      if (mounted) {
        setState(() {
          filteredUsers = searchResults;
          isLoadingUsers = false;
        });
      }
    } catch (e) {
      print('❌ Error searching users: $e');
      if (mounted) {
        setState(() {
          isLoadingUsers = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: EdgeInsets.only(top: 8.h),
          width: 40.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        16.verticalSpace,

        // Title and close button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start New Chat',
                style: AppTextStyles.lufgaLarge.copyWith(
                  color: Colors.white,
                  fontSize: 20.sp,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
              ),
            ],
          ),
        ),

        16.verticalSpace,

        // Search field
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: PrimaryTextField(
            controller: _searchController,
            hint: 'Search by name or email...',
            prefixIcon: Icon(Icons.search, size: 20.sp),
            shadow: true,
          ),
        ),

        20.verticalSpace,

        // Users list
        Expanded(
          child: isLoadingUsers
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ThreeDotLoader(
                        color: AppColors.primaryColor,
                        size: 12.w,
                        spacing: 8.w,
                      ),
                      16.verticalSpace,
                      Text(
                        'Loading users...',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                )
              : filteredUsers.isEmpty
              ? Center(
                  child: Text(
                    isSearching
                        ? 'No users found matching "${_searchController.text}"\nTry searching by name or email'
                        : 'No friends available\nSearch to find users to chat with!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.regular.copyWith(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14.sp,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 8.h,
                  ),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserTile(user);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUserTile(UserModel user) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.boxClr,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        onTap: () {
          // Close bottom sheet and navigate to chat
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatScreen(user: user)),
          );
        },
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: _buildUserAvatar(user),
        title: Text(
          user.name,
          style: AppTextStyles.medium.copyWith(
            color: Colors.white,
            fontSize: 14.sp,
          ),
        ),
        subtitle: Text(
          user.email,
          style: AppTextStyles.small.copyWith(
            color: Colors.grey[400],
            fontSize: 12.sp,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.chat_bubble_outline,
          color: AppColors.primaryColor,
          size: 20.sp,
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserModel user) {
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
}
