import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';

import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.profileAsset, required this.name});
  final String profileAsset;
  final String name;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
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
      // Handle audio file not found or other errors
      print('Audio playback error: $e');
      // You can show a toast or snackbar here
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _audioPlayer.dispose();
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
                      CircleAvatar(
                        radius: 18.r,
                        backgroundImage: AssetImage(widget.profileAsset),
                      ),
                      12.horizontalSpace,
                      // Name and status
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: AppTextStyles.medium.copyWith(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                          Row(
                            children: [
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
                                'Online',
                                style: AppTextStyles.small.copyWith(
                                  color: Colors.grey[400],
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Menu button
                  Icon(Icons.more_vert, color: Colors.white, size: 24.sp),
                ],
              ),
            ),

            // Chat Messages
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                children: [
                  // Alice's message 1 (left side - green bubble)
                  _buildReceiverMessage(
                    'Well, there\'s a lot of talk about incorporating more sustainability into designs. Also, minimalism is making a comeback.',
                    '11:12',
                  ),
                  16.verticalSpace,

                  // Your message 1 (right side with ticks)
                  _buildYourMessage(
                    'That\'s interesting. Do you think these trends will stick around?',
                    '11:12',
                    isRead: true,
                  ),
                  16.verticalSpace,

                  // Alice's message 2 (left side - green bubble)
                  _buildReceiverMessage(
                    'I definitely think so. With the growing concern for the environment, more designers are looking for ways to integrate eco-friendly materials and practices into their work. And minimalism has always been a classic and timeless approach to design.',
                    '11:14',
                  ),
                  16.verticalSpace,

                  // Your message 2 (right side with ticks)
                  _buildYourMessage(
                    'I agree. It\'s always important to keep up with the latest trends, but it\'s also important to stay true to your own style and values.',
                    '11:15',
                    isRead: true,
                  ),
                  16.verticalSpace,

                  // Alice's audio message (left side)
                  _buildReceiverAudioMessage(),
                ],
              ),
            ),

            // Message Input
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(color: AppColors.bgClr),
              child: PrimaryTextField(
                controller: _messageController,
                hint: 'Type a message',
                suffixIcon: Padding(
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
                minlines: 1,
                maxlines: 10, // More than 4 to enable scrolling
                textInputAction: TextInputAction.newline,
                onTap: () {
                  _messageController.clear();
                },
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
                    color: Colors.grey[400],
                    fontSize: 10.sp,
                  ),
                ),
                4.horizontalSpace,
                Icon(
                  isRead ? Icons.done_all : Icons.done,
                  color: Colors.black,
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

  Widget _buildReceiverAudioMessage() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.boxClr,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Play button
                GestureDetector(
                  onTap: _playAudio,
                  child: Container(
                    width: 32.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                      color: AppColors.boxClr,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ),
                12.horizontalSpace,
                // Audio waveform
                Row(
                  children: List.generate(20, (index) {
                    return Container(
                      width: 2.w,
                      height: (8 + (index % 5) * 4).h,
                      margin: EdgeInsets.only(right: 2.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1.r),
                      ),
                    );
                  }),
                ),
              ],
            ),
            4.verticalSpace,
            // Duration
            Text(
              '0:09',
              style: AppTextStyles.regular.copyWith(
                color: Colors.white,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
