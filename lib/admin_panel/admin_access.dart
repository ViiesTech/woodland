// import 'package:flutter/material.dart';
// import 'admin_main.dart';

// class AdminAccess {
//   /// Add this method to your main app to access admin panel
//   /// You can call this from a hidden gesture, settings menu, or debug menu
//   static void showAdminPanel(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const AdminMain(),
//       ),
//     );
//   }

//   /// Add this widget to your main app for easy admin access
//   /// You can hide this in production or show it only in debug mode
//   static Widget buildAdminButton(BuildContext context) {
//     return Positioned(
//       top: 50,
//       right: 20,
//       child: GestureDetector(
//         onTap: () => showAdminPanel(context),
//         child: Container(
//           padding: EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.green.withOpacity(0.8),
//             borderRadius: BorderRadius.circular(25),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.3),
//                 blurRadius: 8,
//                 offset: Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Icon(
//             Icons.admin_panel_settings,
//             color: Colors.white,
//             size: 24,
//           ),
//         ),
//       ),
//     );
//   }
// }
