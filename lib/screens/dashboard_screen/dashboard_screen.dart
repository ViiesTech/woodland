import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../components/resource/size_constants.dart';
import '../../components/resource/app_assets.dart';
import '../../components/resource/app_colors.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../home/home_screen.dart';
import '../admin_home/admin_home_screen.dart';
import '../library/library_screen.dart';
import '../messages/messages_screen.dart';
// import '../games/games_screen.dart';
import '../blog/blog_list_screen.dart';
import '../../services/global_audio_service.dart';
import '../reading/listen_screen.dart';
import '../../components/resource/app_routers.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final GlobalAudioService _audioService = GlobalAudioService();

  List<Widget> _getScreens(bool isAdmin) {
    if (isAdmin) {
      return [
        const AdminHomeScreen(),
        const LibraryScreen(),
        const MessagesScreen(),
        // const GamesScreen(),
        const BlogListScreen(),
      ];
    } else {
      return [
        const HomeScreen(),
        const LibraryScreen(),
        const MessagesScreen(),
        // const GamesScreen(),
        const BlogListScreen(),
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _audioService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isAdmin = state is Authenticated && state.user.role == 'admin';
        final screens = _getScreens(isAdmin);

        return Scaffold(
          backgroundColor: Colors.black,
          body: screens[_currentIndex],
          floatingActionButton: ListenableBuilder(
            listenable: _audioService,
            builder: (context, _) {
              if (!_audioService.isVisible ||
                  _audioService.currentBook == null) {
                return const SizedBox.shrink();
              }

              return _buildAudioPlayerOverlay();
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: Container(
            height: 75.h,
            decoration: BoxDecoration(
              color: AppColors.bottomNavBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10.r,
                  offset: Offset(0, -2.h),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF2A2A2A).withOpacity(0.5),
                  blurRadius: 5.r,
                  offset: Offset(0, -1.h),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _buildNavItem(0, AppAssets.homeIcon, 'Home')),
                Expanded(
                  child: _buildNavItem(1, AppAssets.libraryIcon, 'Library'),
                ),
                Expanded(
                  child: _buildNavItem(2, AppAssets.messagesIcon, 'Messages'),
                ),
                // Expanded(child: _buildNavItem(3, AppAssets.gamesIcon, 'Games')),
                Expanded(child: _buildNavItem(3, AppAssets.blogIcon, 'Blog')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, String iconPath, String label) {
    final bool isSelected = _currentIndex == index;
    final Color color = isSelected
        ? AppColors.primaryColor
        : Colors.white.withOpacity(0.5);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xff203029), Color(0xff181919)],
                  stops: [0.0, 0.6],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SVG Icon with color filter
            SvgPicture.asset(
              iconPath,

              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            SizedBox(height: SizeCons.getResponsiveHeight(4)),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: SizeCons.getResponsiveFontSize(12),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayerOverlay() {
    final book = _audioService.currentBook!;

    return GestureDetector(
      onTap: () {
        // Navigate to ListenScreen when overlay is tapped
        AppRouter.routeTo(context, ListenScreen(book: book));
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        width: 100.w,
        height: 100.h,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: book.coverImageUrl.startsWith('http')
                ? NetworkImage(book.coverImageUrl) as ImageProvider
                : AssetImage(book.coverImageUrl),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Play/Pause Button Overlay (center)
            Positioned.fill(
              child: Center(
                child: GestureDetector(
                  onTap: () => _audioService.playPause(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 35.w,
                    height: 35.h,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.black,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ),
            // Close Button Overlay (top right)
            Positioned(
              top: 0.h,
              right: 0.w,
              child: GestureDetector(
                onTap: () {
                  _audioService.stopAndClear();
                },
                child: Container(
                  width: 20.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 16.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
