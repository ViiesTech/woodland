import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';
import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../models/user_model.dart';

class ListenScreen extends StatefulWidget {
  final BookModel book;

  const ListenScreen({
    super.key,
    required this.book,
  });

  @override
  State<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends State<ListenScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  double _progress = 0.7; // 16:00 / 23:00 ≈ 0.7

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgClr,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20.sp),
        ),
        title: Text(
          'Now Listening',
          style: AppTextStyles.lufgaLarge.copyWith(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Icon(Icons.bookmark_outline, color: Colors.white, size: 24.sp),
          SizedBox(width: 12.w),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final user = state is Authenticated ? state.user : null;
              return Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: _buildUserAvatar(user),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            15.verticalSpace,
            // Headphone Icon and Listener Count
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  AppAssets.headphoneIcon,
                  colorFilter: ColorFilter.mode(
                    AppColors.primaryColor,
                    BlendMode.srcIn,
                  ),
                ),
                8.horizontalSpace,
                Text(
                  '5,22,100 Listened',
                  style: AppTextStyles.regular.copyWith(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),

            20.verticalSpace,

            // Large Audiobook Cover Card
            Center(
              child: Container(
                height: 280.h,
                width: 200.w,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: widget.book.coverImageUrl.startsWith('http')
                        ? NetworkImage(widget.book.coverImageUrl) as ImageProvider
                        : AssetImage(widget.book.coverImageUrl),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            24.verticalSpace,

            // Audiobook Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                widget.book.title,
                style: AppTextStyles.lufgaLarge.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            8.verticalSpace,
            // Author
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                widget.book.author,
                style: AppTextStyles.regular.copyWith(
                  color: Colors.grey[400],
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            30.verticalSpace,

            // Progress Bar and Time
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '16:00',
                    style: AppTextStyles.regular.copyWith(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primaryColor,
                        inactiveTrackColor: Colors.grey[600],
                        thumbColor: Colors.white,
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 8.r,
                        ),
                        trackHeight: 4.h,
                      ),
                      child: Slider(
                        value: _progress,
                        onChanged: (value) {
                          setState(() {
                            _progress = value;
                          });
                        },
                      ),
                    ),
                  ),
                  Text(
                    '23:00',
                    style: AppTextStyles.regular.copyWith(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),

            15.verticalSpace,

            // Playback Controls
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Shuffle
                  Icon(Icons.shuffle, color: Colors.grey[400], size: 24.sp),
                  // Previous
                  Icon(Icons.skip_previous, color: Colors.white, size: 28.sp),
                  // Play/Pause Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isPlaying = !_isPlaying;
                      });
                    },
                    child: Container(
                      width: 60.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                        size: 30.sp,
                      ),
                    ),
                  ),
                  // Next
                  Icon(Icons.skip_next, color: Colors.white, size: 28.sp),
                  // Repeat
                  Icon(Icons.repeat, color: Colors.grey[400], size: 24.sp),
                ],
              ),
            ),

            20.verticalSpace,

            // Readings Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.boxClr,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Readings Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Readings',
                        style: AppTextStyles.lufgaLarge.copyWith(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SvgPicture.asset(AppAssets.fullIcon),
                    ],
                  ),
                  16.verticalSpace,

                  // Text Content
                  Text(
                    widget.book.description,
                    style: AppTextStyles.regular.copyWith(
                      color: Colors.white,
                      fontSize: 14.sp,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  20.verticalSpace,

                  // Share Button
                  Align(
                    alignment: Alignment.bottomRight,
                    child: PrimaryButton(
                      buttonWidth: 100.w,
                      verPadding: 6.h,
                      title: 'Share',
                      icon: Icon(Icons.share_outlined, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),

            40.verticalSpace,
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserModel? user) {
    // If user has a profile image, show it
    if (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty) {
      return Container(
        width: 32.h,
        height: 32.h,
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

    // If user has no image, show avatar with initials
    if (user != null) {
      return Container(
        width: 32.h,
        height: 32.h,
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
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Fallback to default image
    return Container(
      width: 32.h,
      height: 32.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AssetImage(AppAssets.profileImg),
          fit: BoxFit.cover,
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
