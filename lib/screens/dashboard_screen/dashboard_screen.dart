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
import '../games/games_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  List<Widget> _getScreens(bool isAdmin) {
    if (isAdmin) {
      return [
        const AdminHomeScreen(),
        const LibraryScreen(),
        const MessagesScreen(),
        const GamesScreen(),
      ];
    } else {
      return [
        const HomeScreen(),
        const LibraryScreen(),
        const MessagesScreen(),
        const GamesScreen(),
      ];
    }
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
                Expanded(child: _buildNavItem(1, AppAssets.libraryIcon, 'Library')),
                Expanded(
                  child: _buildNavItem(2, AppAssets.messagesIcon, 'Messages'),
                ),
                Expanded(child: _buildNavItem(3, AppAssets.gamesIcon, 'Games')),
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
}
