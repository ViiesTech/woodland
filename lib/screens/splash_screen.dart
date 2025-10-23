import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/screens/login_screen/login_screen.dart';
import '../components/resource/size_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    // Navigate to sign up screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      AppRouter.clearStack(context, LoginScreen());
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo/Icon placeholder
                    Container(
                      width: SizeCons.getResponsiveWidth(120),
                      height: SizeCons.getResponsiveHeight(120),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(
                          SizeCons.getResponsiveRadius(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.4),
                            blurRadius: 20.r,
                            offset: Offset(0, 8.h),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10.r,
                            offset: Offset(0, 4.h),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.forest,
                        size: SizeCons.getResponsiveFontSize(60),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: SizeCons.getResponsiveHeight(30)),
                    // App Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'GlennVerse',
                        style: TextStyle(
                          fontFamily: 'cursive',
                          fontSize: SizeCons.getResponsiveFontSize(28),
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: SizeCons.getResponsiveHeight(10)),
                    // Subtitle
                    Text(
                      'Your Gateway to Adventure',
                      style: TextStyle(
                        fontSize: SizeCons.getResponsiveFontSize(16),
                        color: Colors.grey[400],
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: SizeCons.getResponsiveHeight(50)),
                    // Loading indicator
                    SizedBox(
                      width: SizeCons.getResponsiveWidth(30),
                      height: SizeCons.getResponsiveHeight(30),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
