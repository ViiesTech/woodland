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

class LibraryVideosPage extends StatefulWidget {
  const LibraryVideosPage({super.key});

  @override
  State<LibraryVideosPage> createState() => _LibraryVideosPageState();
}

class _LibraryVideosPageState extends State<LibraryVideosPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<LibraryYoutubeVideo> _recentWatchVideos = [];

  @override
  void initState() {
    super.initState();
    _loadRecentVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadRecentVideos() async {
    final ids = await LibraryVideoRecentService.getRecentVideoIds();
    if (!mounted) return;
    final resolved = <LibraryYoutubeVideo>[];
    for (final id in ids) {
      for (final v in kLibraryYoutubeVideos) {
        if (v.videoId == id) {
          resolved.add(v);
          break;
        }
      }
    }
    setState(() {
      _recentWatchVideos = resolved;
    });
  }

  Future<void> _clearRecentVideos() async {
    await LibraryVideoRecentService.clearRecent();
    if (mounted) {
      setState(() {
        _recentWatchVideos = [];
      });
    }
  }

  List<LibraryYoutubeVideo> get _filteredVideos {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return List<LibraryYoutubeVideo>.from(kLibraryYoutubeVideos);
    return kLibraryYoutubeVideos
        .where(
          (v) =>
              v.title.toLowerCase().contains(q) ||
              v.description.toLowerCase().contains(q),
        )
        .toList();
  }

  SliverGridDelegateWithFixedCrossAxisCount _videoGridDelegate(bool isAdmin) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 16.w,
      mainAxisSpacing: 16.h,
      childAspectRatio: isAdmin ? 0.48 : 0.52,
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

  Future<void> _onVideoTap(LibraryYoutubeVideo video) async {
    await LibraryVideoRecentService.addRecentVideoId(video.videoId);
    await _loadRecentVideos();
    await _openYoutube(video);
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
                hint: 'Title, author or keyword',
                prefixIcon: Icon(Icons.search, size: 20.sp),
                height: 55.h,
                verticalPad: 10.h,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  if (value.trim().isEmpty) {
                    _loadRecentVideos();
                  }
                },
              ),
            ),
            16.verticalSpace,
            Expanded(
              child: Builder(
                builder: (context) {
                  final videos = _filteredVideos;
                  if (videos.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No videos available'
                            : 'No videos found',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14.sp,
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_searchQuery.isEmpty) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recent Searches',
                                  style: AppTextStyles.lufgaLarge.copyWith(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                  ),
                                ),
                                if (_recentWatchVideos.isNotEmpty)
                                  GestureDetector(
                                    onTap: _clearRecentVideos,
                                    child: Text(
                                      'Clear',
                                      style: AppTextStyles.regular.copyWith(
                                        color: AppColors.primaryColor,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          16.verticalSpace,
                          if (_recentWatchVideos.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Text(
                                'No recent searches',
                                style: AppTextStyles.regular.copyWith(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 14.sp,
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 200.h,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _recentWatchVideos.length,
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                itemBuilder: (context, index) {
                                  final video = _recentWatchVideos[index];
                                  return Container(
                                    margin: EdgeInsets.only(right: 16.w),
                                    child: _LibraryVideoTile(
                                      video: video,
                                      onTap: () => _onVideoTap(video),
                                    ),
                                  );
                                },
                              ),
                            ),
                          26.verticalSpace,
                          if (kLibraryYoutubeVideos.isNotEmpty) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Text(
                                'Featured',
                                style: AppTextStyles.lufgaLarge.copyWith(
                                  color: Colors.white,
                                  fontSize: 20.sp,
                                ),
                              ),
                            ),
                            16.verticalSpace,
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: _videoGridDelegate(isAdmin),
                                itemCount: min(6, kLibraryYoutubeVideos.length),
                                itemBuilder: (context, index) {
                                  final video = kLibraryYoutubeVideos[index];
                                  return _LibraryVideoTile(
                                    video: video,
                                    onTap: () => _onVideoTap(video),
                                  );
                                },
                              ),
                            ),
                            26.verticalSpace,
                          ],
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Text(
                              'New Release',
                              style: AppTextStyles.lufgaLarge.copyWith(
                                color: Colors.white,
                                fontSize: 20.sp,
                              ),
                            ),
                          ),
                          16.verticalSpace,
                        ],
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: _videoGridDelegate(isAdmin),
                            itemCount: videos.length,
                            itemBuilder: (context, index) {
                              final video = videos[index];
                              return _LibraryVideoTile(
                                video: video,
                                onTap: () => _onVideoTap(video),
                              );
                            },
                          ),
                        ),
                        26.verticalSpace,
                      ],
                    ),
                  );
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
                      fit: BoxFit.cover,
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
                      color: Colors.white.withValues(alpha: 0.95),
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
                color: Colors.white,
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
