// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:the_woodlands_series/components/resource/app_colors.dart';
// import 'admin_dashboard_screen.dart';

// class AdminLoginScreen extends StatefulWidget {
//   const AdminLoginScreen({super.key});

//   @override
//   State<AdminLoginScreen> createState() => _AdminLoginScreenState();
// }

// class _AdminLoginScreenState extends State<AdminLoginScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool _isLoading = false;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: EdgeInsets.all(24.w),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Admin Panel Title
//                 Text(
//                   'Admin Panel',
//                   style: TextStyle(
//                     color: Colors.green,
//                     fontSize: 32.sp,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 20.verticalSpace,
//                 Text(
//                   'The Woodlands Series Content Management',
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.7),
//                     fontSize: 16.sp,
//                   ),
//                 ),
//                 60.verticalSpace,
          
//                 // Simple Login Form
//                 TextField(
//                   controller: _emailController,
//                   style: TextStyle(color: Colors.white),
//                   decoration: InputDecoration(
//                     hintText: 'Admin Email',
//                     hintStyle: TextStyle(color: Colors.grey),
//                     prefixIcon: Icon(Icons.admin_panel_settings, color: Colors.green),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12.r),
//                     ),
//                     filled: true,
//                     fillColor: Colors.grey[800],
//                   ),
//                 ),
//                 20.verticalSpace,
//                 TextField(
//                   controller: _passwordController,
//                   obscureText: true,
//                   style: TextStyle(color: Colors.white),
//                   decoration: InputDecoration(
//                     hintText: 'Password',
//                     hintStyle: TextStyle(color: Colors.grey),
//                     prefixIcon: Icon(Icons.lock, color: Colors.green),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12.r),
//                     ),
//                     filled: true,
//                     fillColor: Colors.grey[800],
//                   ),
//                 ),
//                 30.verticalSpace,
          
//                 // Login Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _handleLogin,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       padding: EdgeInsets.symmetric(vertical: 16.h),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12.r),
//                       ),
//                     ),
//                     child: Text(
//                       _isLoading ? 'Signing In...' : 'Sign In',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//                 20.verticalSpace,
          
//                 // Demo Credentials
//                 Container(
//                   padding: EdgeInsets.all(16.w),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[800],
//                     borderRadius: BorderRadius.circular(12.r),
//                   ),
//                   child: Column(
//                     children: [
//                       Text(
//                         'Demo Credentials',
//                         style: TextStyle(
//                           color: Colors.green,
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       8.verticalSpace,
//                       Text(
//                         'Email: admin@thewoodlands.com\nPassword: admin123',
//                         style: TextStyle(
//                           color: Colors.white.withOpacity(0.7),
//                           fontSize: 12.sp,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _handleLogin() async {
//     if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
//       _showSnackBar('Please fill in all fields');
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     // Simulate login delay
//     await Future.delayed(const Duration(seconds: 1));

//     // Basic validation (in real app, use proper authentication)
//     if (_emailController.text == 'admin@thewoodlands.com' && 
//         _passwordController.text == 'admin123') {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
//       );
//     } else {
//       _showSnackBar('Invalid credentials');
//     }

//     setState(() {
//       _isLoading = false;
//     });
//   }

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: AppColors.primaryColor,
//       ),
//     );
//   }
// }
