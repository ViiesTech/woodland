import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:the_woodlands_series/models/mp3_model.dart';
import 'package:the_woodlands_series/admin_panel/services/firebase_service.dart';

class Mp3Page extends StatefulWidget {
  const Mp3Page({super.key});

  @override
  State<Mp3Page> createState() => Mp3PageState();
}

class Mp3PageState extends State<Mp3Page> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Mp3Model> _allMp3s = [];
  bool _isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl;
  PlayerState _playerState = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    loadMp3s();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> loadMp3s() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final mp3s = await FirebaseService.getMp3s();
      if (mounted) {
        setState(() {
          _allMp3s = mp3s;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleMp3Status(Mp3Model mp3) async {
    try {
      final newStatus = !mp3.isPublished;
      await FirebaseService.updateMp3Status(mp3.id, newStatus);
      if (mounted) {
        CustomToast.showSuccess(
          context,
          'Song ${newStatus ? 'published' : 'unpublished'} successfully!',
        );
        loadMp3s();
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Failed to update status');
      }
    }
  }

  Future<void> _playPause(String url) async {
    try {
      if (_currentlyPlayingUrl == url && _playerState == PlayerState.playing) {
        await _audioPlayer.pause();
      } else if (_currentlyPlayingUrl == url && _playerState == PlayerState.paused) {
        await _audioPlayer.resume();
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(url));
        setState(() {
          _currentlyPlayingUrl = url;
        });
      }
    } catch (e) {
      CustomToast.showError(context, 'Error playing audio: $e');
    }
  }

  List<Mp3Model> get _filteredMp3s {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _allMp3s;
    return _allMp3s.where((m) => m.title.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isAdmin = state is Authenticated && state.user.role == 'admin';

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: PrimaryTextField(
                controller: _searchController,
                hint: 'Search Songs...',
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        final allFiltered = _filteredMp3s;
                        final displayMp3s = isAdmin
                            ? allFiltered
                            : allFiltered.where((m) => m.isPublished).toList();

                        if (displayMp3s.isEmpty) {
                          return Center(
                            child: Text(
                              'No songs found',
                              style: AppTextStyles.regular.copyWith(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14.sp,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: displayMp3s.length,
                          separatorBuilder: (context, index) => 12.verticalSpace,
                          itemBuilder: (context, index) {
                            final mp3 = displayMp3s[index];
                            final isPlaying = _currentlyPlayingUrl == mp3.url &&
                                _playerState == PlayerState.playing;

                            return Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: AppColors.boxClr,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _playPause(mp3.url),
                                    child: Container(
                                      width: 50.w,
                                      height: 50.w,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isPlaying ? Icons.pause : Icons.play_arrow,
                                        color: AppColors.primaryColor,
                                        size: 30.sp,
                                      ),
                                    ),
                                  ),
                                  16.horizontalSpace,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mp3.title,
                                          style: AppTextStyles.medium.copyWith(
                                            color: Colors.white,
                                            fontSize: 16.sp,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (isAdmin) ...[
                                          4.verticalSpace,
                                          Text(
                                            mp3.isPublished ? 'Published' : 'Unpublished',
                                            style: AppTextStyles.regular.copyWith(
                                              color: mp3.isPublished
                                                  ? AppColors.primaryColor
                                                  : Colors.redAccent,
                                              fontSize: 12.sp,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isAdmin)
                                    Switch(
                                      value: mp3.isPublished,
                                      onChanged: (value) => _toggleMp3Status(mp3),
                                      activeColor: AppColors.primaryColor,
                                    ),
                                ],
                              ),
                            );
                          },
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
