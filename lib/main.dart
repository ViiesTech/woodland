import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/repositories/auth_repository.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/deep_link_handler.dart';

// Global navigator key for deep link handling
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up deep link method channel listener
  const MethodChannel channel = MethodChannel('com.woodlandseries.app/deep_link');
  channel.setMethodCallHandler((call) async {
    if (call.method == 'onDeepLink') {
      final url = call.arguments as String?;
      if (url != null) {
        DeepLinkHandler.handleStripeDeepLink(url);
      }
    }
  });

  // Check for initial deep link (if app was opened via deep link)
  try {
    final initialLink = await channel.invokeMethod<String>('getInitialLink');
    if (initialLink != null) {
      // Delay to ensure app is fully initialized
      Future.delayed(const Duration(milliseconds: 500), () {
        DeepLinkHandler.handleStripeDeepLink(initialLink);
      });
    }
  } catch (e) {
    print('Error getting initial link: $e');
  }

  runApp(DevicePreview(enabled: false, builder: (context) => const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(authRepository: AuthRepository()),
      child: ScreenUtilInit(
        designSize: const Size(375, 812), // iPhone X design size
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'The Woodlands Series',
            debugShowCheckedModeBanner: false,
            useInheritedMediaQuery: true,
            locale: DevicePreview.locale(context),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: child!,
              );
            },
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: AppColors.bgClr,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
            home: const SplashScreenWithAdmin(),
          );
        },
      ),
    );
  }
}

class SplashScreenWithAdmin extends StatelessWidget {
  const SplashScreenWithAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
