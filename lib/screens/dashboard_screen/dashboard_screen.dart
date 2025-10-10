import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../components/resource/size_constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 1; // Library is selected by default

  final List<Widget> _screens = [
    const HomeScreen(),
    const LibraryScreen(),
    const MessagesScreen(),
    const GamesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: SizeCons.getResponsiveHeight(80),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(SizeCons.getResponsiveRadius(20)),
            topRight: Radius.circular(SizeCons.getResponsiveRadius(20)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_outlined, 'Home'),
            _buildNavItem(1, Icons.library_books_outlined, 'Library'),
            _buildNavItem(2, Icons.message_outlined, 'Messages'),
            _buildNavItem(3, Icons.sports_esports_outlined, 'Games'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    final Color color = isSelected ? Colors.green : Colors.grey[400]!;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: SizeCons.getResponsiveHeight(8),
          horizontal: SizeCons.getResponsiveWidth(12),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(SizeCons.getResponsiveRadius(12)),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.green.withOpacity(0.2),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
              spreadRadius: 0,
            ),
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: SizeCons.getResponsiveFontSize(24)),
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

// Placeholder screens for each tab
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Text(
          'Home Screen',
          style: TextStyle(
            color: Colors.white,
            fontSize: SizeCons.getResponsiveFontSize(24),
          ),
        ),
      ),
    );
  }
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Text(
          'Library Screen',
          style: TextStyle(
            color: Colors.white,
            fontSize: SizeCons.getResponsiveFontSize(24),
          ),
        ),
      ),
    );
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Text(
          'Messages Screen',
          style: TextStyle(
            color: Colors.white,
            fontSize: SizeCons.getResponsiveFontSize(24),
          ),
        ),
      ),
    );
  }
}

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Text(
          'Games Screen',
          style: TextStyle(
            color: Colors.white,
            fontSize: SizeCons.getResponsiveFontSize(24),
          ),
        ),
      ),
    );
  }
}
