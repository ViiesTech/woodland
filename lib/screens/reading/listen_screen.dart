import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';

class ListenScreen extends StatefulWidget {
  final String title;
  final String author;
  final String imageAsset;

  const ListenScreen({
    super.key,
    required this.title,
    required this.author,
    required this.imageAsset,
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
          SizedBox(width: 20.w),
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
                    image: AssetImage(widget.imageAsset),
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
                'A Love Story Beneath The Rain That Healed Us',
                style: AppTextStyles.lufgaLarge.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
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
                    'Far far away, behind the word mountains, far from the countries Vokalia and Consonantia, there live the blind texts. Separated they live in Bookmarksgrove right at the coast of the Semantics, a large language ocean. A small river named Duden flows by their place and supplies it with the necessary regelialia. It is a paradisematic country, in which roasted parts of sentences fly into your mouth.',
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
}
