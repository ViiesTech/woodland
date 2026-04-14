import 'dart:math' show min;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:the_woodlands_series/models/library_youtube_video.dart';
import 'package:the_woodlands_series/services/library_video_recent_service.dart';

import 'package:the_woodlands_series/admin_panel/services/firebase_service.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/screens/library/pages/library_youtube_player_screen.dart';

class LibraryVideosPage extends StatefulWidget {
  const LibraryVideosPage({super.key});

  @override
  State<LibraryVideosPage> createState() => LibraryVideosPageState();
}

class LibraryVideosPageState extends State<LibraryVideosPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<LibraryYoutubeVideo> _firestoreVideos = [];
  bool _isVideosLoading = true;

  @override
  void initState() {
    super.initState();
    loadVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> loadVideos() async {
    if (!mounted) return;
    setState(() {
      _isVideosLoading = true;
    });

    try {
      final videos = await FirebaseService.getLibraryVideos();
      if (mounted) {
        setState(() {
          _firestoreVideos = videos;
          _isVideosLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVideosLoading = false;
        });
      }
    }
  }

  Future<void> _toggleVideoStatus(LibraryYoutubeVideo video) async {
    try {
      final newStatus = !video.isPublished;
      await FirebaseService.updateVideoStatus(video.id, newStatus);
      if (mounted) {
        CustomToast.showSuccess(
          context, 
          'Video ${newStatus ? 'published' : 'unpublished'} successfully!'
        );
        loadVideos();
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Failed to update status');
      }
    }
  }

  List<LibraryYoutubeVideo> get _filteredVideos {
    final q = _searchQuery.trim().toLowerCase();
    final all = _firestoreVideos;
    if (q.isEmpty) return List<LibraryYoutubeVideo>.from(all);
    return all
        .where(
          (v) =>
              v.title.toLowerCase().contains(q) ||
              v.description.toLowerCase().contains(q),
        )
        .toList();
  }

  SliverGridDelegateWithFixedCrossAxisCount _videoGridDelegate() {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 16.w,
      mainAxisSpacing: 16.h,
      childAspectRatio: 0.48,
    );
  }

  Future<void> _openYoutube(LibraryYoutubeVideo video) async {
    try {
      final ok = await launchUrl(
        video.watchUri,
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        CustomToast.showError(context, 'Could not open YouTube');
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Could not open YouTube');
      }
    }
  }

  void _showRedirectionDialog(LibraryYoutubeVideo video, bool isAdmin) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.boxClr,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Watch Video',
                style: AppTextStyles.lufgaLarge.copyWith(
                  color: Colors.white,
                  fontSize: 22.sp,
                ),
              ),
              20.verticalSpace,
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  height: 140.h,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
              20.verticalSpace,
              Text(
                video.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.medium.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              12.verticalSpace,
              Text(
                'Choose how you would like to watch this video.',
                textAlign: TextAlign.center,
                style: AppTextStyles.regular.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14.sp,
                ),
              ),
              28.verticalSpace,
              Column(
                children: [
                  PrimaryButton(
                    title: 'Play',
                    icon: Icon(
                      Icons.play_circle_outline,
                      color: AppColors.bgClr,
                      size: 20.sp,
                    ),
                    shadow: true,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LibraryYoutubePlayerScreen(video: video),
                        ),
                      );
                    },
                    verPadding: 16.h,
                    fontSize: 15.sp,
                    buttonWidth: double.infinity,
                  ),
                  12.verticalSpace,
                  // GestureDetector(
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //     _openYoutube(video);
                  //   },
                  //   child: Container(
                  //     height: 52.h,
                  //     width: double.infinity,
                  //     decoration: BoxDecoration(
                  //       color: Colors.transparent,
                  //       border: Border.all(
                  //         color: Colors.white.withOpacity(0.2),
                  //       ),
                  //       borderRadius: BorderRadius.circular(10.r),
                  //     ),
                  //     child: Center(
                  //       child: Row(
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //         children: [
                  //           Icon(
                  //             Icons.open_in_new,
                  //             color: Colors.white70,
                  //             size: 18.sp,
                  //           ),
                  //           8.horizontalSpace,
                  //           Text(
                  //             'Watch on YouTube',
                  //             style: AppTextStyles.medium.copyWith(
                  //               color: Colors.white70,
                  //               fontSize: 15.sp,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  if (isAdmin) ...[
                    16.verticalSpace,
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _toggleVideoStatus(video);
                      },
                      child: Container(
                        height: 52.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: video.isPublished 
                                ? Colors.redAccent.withOpacity(0.5) 
                                : AppColors.primaryColor.withOpacity(0.5)
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Center(
                          child: Text(
                            video.isPublished ? 'Unpublish' : 'Publish',
                            style: AppTextStyles.medium.copyWith(
                              color: video.isPublished 
                                  ? Colors.redAccent 
                                  : AppColors.primaryColor,
                              fontSize: 15.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  16.verticalSpace,
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.medium.copyWith(
                        color: Colors.white38,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isAdmin =
            state is Authenticated && state.user.role == 'admin';

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: PrimaryTextField(
                controller: _searchController,
                hint: 'Search videos...',
                prefixIcon: Icon(Icons.search, size: 20.sp),
                height: 55.h,
                verticalPad: 10.h,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            16.verticalSpace,
            Expanded(
              child: _isVideosLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        final allFiltered = _filteredVideos;
                        
                        if (isAdmin) {
                          final published = allFiltered.where((v) => v.isPublished).toList();
                          final unpublished = allFiltered.where((v) => !v.isPublished).toList();

                          if (allFiltered.isEmpty) {
                            return Center(
                              child: Text(
                                'No videos found',
                                style: AppTextStyles.regular.copyWith(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14.sp,
                                ),
                              ),
                            );
                          }

                          return ListView(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            children: [
                              if (published.isNotEmpty) ...[
                                Text(
                                  'Published Videos',
                                  style: AppTextStyles.lufgaLarge.copyWith(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                  ),
                                ),
                                16.verticalSpace,
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: _videoGridDelegate(),
                                  itemCount: published.length,
                                  itemBuilder: (context, index) {
                                    final video = published[index];
                                    return _LibraryVideoTile(
                                      video: video,
                                      onTap: () => _showRedirectionDialog(video, true),
                                    );
                                  },
                                ),
                                26.verticalSpace,
                              ],
                              if (unpublished.isNotEmpty) ...[
                                Text(
                                  'Unpublished Videos',
                                  style: AppTextStyles.lufgaLarge.copyWith(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                  ),
                                ),
                                16.verticalSpace,
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: _videoGridDelegate(),
                                  itemCount: unpublished.length,
                                  itemBuilder: (context, index) {
                                    final video = unpublished[index];
                                    return _LibraryVideoTile(
                                      video: video,
                                      onTap: () => _showRedirectionDialog(video, true),
                                    );
                                  },
                                ),
                                26.verticalSpace,
                              ],
                            ],
                          );
                        } else {
                          // Regular User - Only published
                          final published = allFiltered.where((v) => v.isPublished).toList();
                          
                          if (published.isEmpty) {
                            return Center(
                              child: Text(
                                'No videos available',
                                style: AppTextStyles.regular.copyWith(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14.sp,
                                ),
                              ),
                            );
                          }

                          return GridView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            gridDelegate: _videoGridDelegate(),
                            itemCount: published.length,
                            itemBuilder: (context, index) {
                              final video = published[index];
                              return _LibraryVideoTile(
                                video: video,
                                onTap: () => _showRedirectionDialog(video, false),
                              );
                            },
                          );
                        }
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _LibraryVideoTile extends StatelessWidget {
  const _LibraryVideoTile({
    required this.video,
    required this.onTap,
  });

  final LibraryYoutubeVideo video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 122.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              height: 119.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: const Color.fromARGB(31, 141, 141, 141),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  ColoredBox(
                    color: Colors.grey.shade900,
                    child: CachedNetworkImage(
                      imageUrl: video.thumbnailUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: 119.h,
                      memCacheWidth: 244,
                      memCacheHeight: 238,
                      progressIndicatorBuilder: (context, url, progress) =>
                          Center(
                        child: SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: CircularProgressIndicator(
                            value: progress.progress,
                            color: AppColors.primaryColor,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        return Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade600,
                            size: 40.sp,
                          ),
                        );
                      },
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white.withOpacity(0.95),
                      size: 44.sp,
                      shadows: const [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black87,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            8.verticalSpace,
            Text(
              video.title,
              style: AppTextStyles.medium.copyWith(
                color: Colors.white,
                fontSize: 10.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            4.verticalSpace,
            Text(
              video.description,
              style: AppTextStyles.regular.copyWith(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            8.verticalSpace,
          ],
        ),
      ),
    );
  }
}
