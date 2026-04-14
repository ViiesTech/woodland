import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/admin_panel/services/firebase_service.dart';
import 'package:the_woodlands_series/models/library_youtube_video.dart';

import 'package:the_woodlands_series/services/youtube_service.dart';

class AddVideoScreen extends StatefulWidget {
  const AddVideoScreen({super.key});

  @override
  State<AddVideoScreen> createState() => _AddVideoScreenState();
}

class _AddVideoScreenState extends State<AddVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _isFetching = false;
  String? _thumbnailUrl;

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _extractVideoId(String url) {
    url = url.trim();
    if (url.isEmpty) return null;
    
    // Try standard URL patterns first
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/|v\/|embed\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    
    final match = regExp.firstMatch(url);
    if (match != null) return match.group(1);

    // If no URL match, check if it's a raw video ID (11 chars) or ID with params
    final rawIdRegExp = RegExp(r'^([a-zA-Z0-9_-]{11})(?:\?|&|$)');
    final rawMatch = rawIdRegExp.firstMatch(url);
    if (rawMatch != null) return rawMatch.group(1);

    // Last resort: extract any 11-char sequence that looks like an ID
    final generalRegExp = RegExp(r'([a-zA-Z0-9_-]{11})');
    final generalMatch = generalRegExp.firstMatch(url);
    if (generalMatch != null) return generalMatch.group(1);

    return null;
  }

  Future<void> _fetchVideoData() async {
    final url = _urlController.text.trim();
    final videoId = _extractVideoId(url);

    if (videoId == null) {
      CustomToast.showError(context, 'Please enter a valid YouTube URL or 11-character Video ID');
      return;
    }

    setState(() {
      _isFetching = true;
    });

    try {
      final result = await YoutubeService.getVideoDetails(videoId);
      if (result['success'] == true) {
        final details = result['data'];
        setState(() {
          _titleController.text = details['title'] ?? '';
          _descriptionController.text = details['description'] ?? '';
          _thumbnailUrl = details['thumbnailUrl'];
        });
        CustomToast.showSuccess(context, 'Video data fetched!');
      } else {
        CustomToast.showError(context, result['error'] ?? 'Could not fetch details.');
      }
    } catch (e) {
      CustomToast.showError(context, 'Error fetching data: $e');
    } finally {
      setState(() {
        _isFetching = false;
      });
    }
  }

  Future<void> _saveVideo() async {
    if (!_formKey.currentState!.validate()) return;

    final url = _urlController.text.trim();
    final videoId = _extractVideoId(url);

    if (videoId == null) {
      CustomToast.showError(context, 'Invalid YouTube URL or Video ID not found');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final video = LibraryYoutubeVideo(
        id: '', // Will be set by Firestore
        videoId: videoId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        thumbnailUrl: _thumbnailUrl ?? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
        isPublished: true,
      );

      await FirebaseService.addLibraryVideo(video);
      CustomToast.showSuccess(context, 'Video added successfully!');
      AppRouter.routeBack(context);
    } catch (e) {
      CustomToast.showError(context, 'Error adding video: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      appBar: AppBar(
        backgroundColor: AppColors.boxClr,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => AppRouter.routeBack(context),
        ),
        title: Text(
          'Add Your YouTube Video Link',
          style: AppTextStyles.lufgaMedium.copyWith(
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Video Information',
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 16.sp,
                ),
              ),
              24.verticalSpace,

              // YouTube URL
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: PrimaryTextField(
                      controller: _urlController,
                      hint: 'YouTube Video Link *',
                      prefixIcon: const Icon(Icons.link, color: AppColors.primaryColor),
                      validator: (value) =>
                          value?.isEmpty == true ? 'YouTube link is required' : null,
                    ),
                  ),
                  12.horizontalSpace,
                  _isFetching
                      ? const Padding(
                          padding: EdgeInsets.only(top: 15),
                          child: CircularProgressIndicator(color: AppColors.primaryColor),
                        )
                      : GestureDetector(
                          onTap: _fetchVideoData,
                          child: Container(
                            height: 55.h,
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                              child: Text(
                                'Fetch',
                                style: AppTextStyles.medium.copyWith(
                                  color: Colors.black,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
              16.verticalSpace,

              if (_thumbnailUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.network(
                    _thumbnailUrl!,
                    height: 180.h,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                16.verticalSpace,
              ],

              // Title
              PrimaryTextField(
                controller: _titleController,
                hint: 'Video Title *',
                validator: (value) =>
                    value?.isEmpty == true ? 'Title is required' : null,
              ),
              16.verticalSpace,

              // Description
              PrimaryTextField(
                controller: _descriptionController,
                hint: 'Description *',
                minlines: 3,
                maxlines: 5,
                validator: (value) =>
                    value?.isEmpty == true ? 'Description is required' : null,
              ),
              32.verticalSpace,

              // Add Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
                  : PrimaryButton(
                      onTap: _saveVideo,
                      title: 'Publish',
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
