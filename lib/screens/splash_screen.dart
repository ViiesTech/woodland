import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_event.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/screens/dashboard_screen/dashboard_screen.dart';
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

    // Check authentication status
    Future.delayed(const Duration(seconds: 2), () {
      context.read<AuthBloc>().add(const CheckAuthStatus());
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // User is logged in, navigate to dashboard after delay
          // DashboardScreen will automatically show AdminHomeScreen for admins
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              AppRouter.clearStack(context, const DashboardScreen());
            }
          });
        } else if (state is Unauthenticated) {
          // User is not logged in, navigate to login screen after delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              AppRouter.clearStack(context, const LoginScreen());
            }
          });
        } else if (state is AuthError) {
          // Error occurred, navigate to login screen after delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              AppRouter.clearStack(context, const LoginScreen());
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgClr,
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
                      // App Logo
                      Image.asset(
                        AppAssets.logo,
                        width: SizeCons.getResponsiveWidth(220),
                        height: SizeCons.getResponsiveHeight(220),
                        fit: BoxFit.contain,
                      ),
                      10.verticalSpace,
                      // Loading indicator
                      SizedBox(
                        width: SizeCons.getResponsiveWidth(30),
                        height: SizeCons.getResponsiveHeight(30),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
