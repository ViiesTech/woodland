// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:the_woodlands_series/components/resource/app_colors.dart';
// import 'screens/admin_login_screen.dart';

// class AdminMain extends StatelessWidget {
//   const AdminMain({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ScreenUtilInit(
//       designSize: const Size(375, 812),
//       minTextAdapt: true,
//       splitScreenMode: true,
//       builder: (context, child) {
//         return MaterialApp(
//           title: 'The Woodlands Series Admin Panel',
//           debugShowCheckedModeBanner: false,
//           theme: ThemeData(
//             colorScheme: ColorScheme.fromSeed(
//               seedColor: Colors.green,
//               brightness: Brightness.dark,
//             ),
//             scaffoldBackgroundColor: AppColors.bgClr,
//             appBarTheme: const AppBarTheme(
//               backgroundColor: Colors.black,
//               foregroundColor: Colors.white,
//             ),
//           ),
//           home: const AdminLoginScreen(),
//         );
//       },
//     );
//   }
// }
