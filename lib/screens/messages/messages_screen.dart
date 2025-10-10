import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:the_woodlands_series/Components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import '../../components/resource/app_assets.dart';
import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Messages',
                    style: AppTextStyles.lufgaLarge.copyWith(
                      color: Colors.white,
                      fontSize: 24.sp,
                    ),
                  ),
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 20.r,
                        backgroundImage: AssetImage(AppAssets.profileImg),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 10.w,
                          height: 10.h,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.bgClr,
                              width: 1.5.w,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            16.verticalSpace,

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: PrimaryTextField(
                hint: 'Search Chat',
                prefixIcon: Icon(Icons.search, size: 20.sp),
              ),
            ),
            20.verticalSpace,

            // Chat List
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMessageItem(
                    profileAsset: AppAssets.temp1,
                    profileBgColor: Colors.yellow[700]!,
                    name: 'Killan James',
                    status: 'Typing...',
                    statusColor: AppColors.primaryColor,
                    time: '4:30 PM',
                    unreadCount: 2,
                    isOnline: true,
                    context: context,
                  ),
                  _buildMessageItem(
                    profileAsset: AppAssets.temp2,
                    profileBgColor: Colors.brown[300]!,
                    name: 'Design Team',
                    lastMessage: 'Hello! Everyone',
                    time: '9:36 AM',
                    isRead: true,
                    context: context,
                  ),
                  _buildMessageItem(
                    profileAsset: AppAssets.temp3,
                    profileBgColor: Colors.orange[300]!,
                    name: 'Ahmed Medi',
                    lastMessage: 'Wow really Cool 🔥',
                    time: '1:15 AM',
                    isSent: true,
                    context: context,
                  ),
                  20.verticalSpace,
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          AppAssets.messagesIcon,
                          height: 16.h,
                          width: 16.w,
                          colorFilter: ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        8.horizontalSpace,
                        Text(
                          'All Message',
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  10.verticalSpace,
                  _buildMessageItem(
                    profileAsset: AppAssets.temp4,
                    profileBgColor: Colors.pink[300]!,
                    name: 'Claudia Maudi',
                    status: 'Typing...',
                    statusColor: AppColors.primaryColor,
                    time: '4:30 PM',
                    isOnline: false,
                    context: context,
                  ),
                  _buildMessageItem(
                    profileAsset: AppAssets.temp5,
                    profileBgColor: Colors.purple[300]!,
                    name: 'Novita',
                    lastMessage: 'yah, nice design',
                    time: '4:30 PM',
                    unreadCount: 2,
                    isOnline: true,
                    context: context,
                  ),
                  _buildMessageItem(
                    profileAsset: AppAssets.temp6,
                    profileBgColor: Colors.blue[300]!,
                    name: 'Milie Nose',
                    lastMessage: 'Awesome 🔥',
                    time: '8:20 PM',
                    unreadCount: 1,
                    isOnline: true,
                    context: context,
                  ),
                  _buildMessageItem(
                    profileAsset: AppAssets.temp7,
                    profileBgColor: Colors.green[700]!,
                    name: 'Ikhsan SD',
                    isVoiceMessage: true,
                    time: 'yesterday',
                    isOnline: false,
                    context: context,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem({
    required String profileAsset,
    required Color profileBgColor,
    required String name,
    String? lastMessage,
    String? status,
    Color? statusColor,
    required String time,
    int? unreadCount,
    bool isRead = false,
    bool isSent = false,
    bool isVoiceMessage = false,
    bool isOnline = false,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () {
        AppRouter.routeTo(
          context,
          ChatScreen(profileAsset: profileAsset, name: name),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 25.r,
                  backgroundColor: profileBgColor,
                  backgroundImage: AssetImage(profileAsset),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10.w,
                      height: 10.h,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.bgClr,
                          width: 1.5.w,
                        ),
                      ),
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
                    name,
                    style: AppTextStyles.medium.copyWith(
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                  ),
                  4.verticalSpace,
                  if (status != null)
                    Text(
                      status,
                      style: AppTextStyles.regular.copyWith(
                        color: statusColor ?? Colors.grey[400],
                        fontSize: 12.sp,
                      ),
                    )
                  else if (isVoiceMessage)
                    Row(
                      children: [
                        Icon(Icons.mic, color: Colors.grey[400], size: 16.sp),
                        4.horizontalSpace,
                        Text(
                          'Voice message',
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.grey[400],
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    )
                  else if (lastMessage != null)
                    Text(
                      lastMessage,
                      style: AppTextStyles.regular.copyWith(
                        color: Colors.white,
                        fontSize: 12.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            12.horizontalSpace,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: AppTextStyles.small.copyWith(
                    color: Colors.grey[400],
                    fontSize: 10.sp,
                  ),
                ),
                4.verticalSpace,
                if (unreadCount != null && unreadCount > 0)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Text(
                        unreadCount.toString(),
                        style: AppTextStyles.small.copyWith(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else if (isRead)
                  Icon(
                    Icons.done_all,
                    color: AppColors.primaryColor,
                    size: 15.sp,
                  )
                else if (isSent)
                  Icon(Icons.done, color: Colors.grey[400], size: 15.sp),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
