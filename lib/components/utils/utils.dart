// // ignore_for_file: use_build_context_synchronously

// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:the_woodlands_series/components/resource/app_assets.dart';
// import 'package:the_woodlands_series/components/resource/app_colors.dart';
// import 'package:url_launcher/url_launcher.dart';

// class Utils {
//   /// Logs info-level messages in green color in the console.
//   static logInfo(String msg, {String? name}) {
//     log(
//       '\x1B[32m$msg\x1B[0m',
//       name: name != null ? '\x1B[32m$name\x1B[0m' : "",
//     );
//   }

//   /// Logs error messages in red color in the console.
//   static logError(String msg, {String? name}) {
//     log(
//       '\x1B[31m$msg\x1B[0m',
//       name: name != null ? '\x1B[31m$name\x1B[0m' : "",
//     );
//   }

//   /// Logs general information in white color in the console (used for debug or info).
//   static logErrorInfo(String msg, {String? name}) {
//     log(
//       '\x1B[37m$msg\x1B[0m',
//       name: name != null ? '\x1B[37m$name\x1B[0m' : "",
//     );
//   }

//   /// Shows a success toast message with custom UI using FToast.
//   static successtoastMessage(String message, BuildContext context) {
//     FToast toast = FToast();
//     toast.init(context);
//     toast.removeCustomToast();
//     toast.showToast(
//       toastDuration: const Duration(seconds: 3),
//       gravity: ToastGravity.TOP,
//       child: Container(
//         constraints: BoxConstraints(maxWidth: double.infinity * 0.8),
//         padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
//         decoration: BoxDecoration(
//           color: AppColors.whiteColor,
//           borderRadius: BorderRadius.circular(24),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Image.asset(
//               AppAssets.toastImg,
//               fit: BoxFit.scaleDown,
//               height: 30.h,
//             ),
//             10.horizontalSpace,
//             Flexible(
//               child: Text(
//                 message,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: AppTextStyles.regular.copyWith(
//                   color: AppColors.blackColor,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Shows a error toast message with custom UI using FToast.
//   static errortoastMessage(String message, BuildContext context) {
//     FToast toast = FToast();
//     toast.init(context);
//     toast.removeCustomToast();
//     toast.showToast(
//       toastDuration: const Duration(seconds: 5),
//       gravity: ToastGravity.TOP,
//       child: Container(
//         constraints: BoxConstraints(maxWidth: double.infinity * 0.8),
//         padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
//         decoration: BoxDecoration(
//           color: AppColors.blackColor,
//           borderRadius: BorderRadius.circular(24),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Image.asset(
//               AppAssets.toastImg,
//               fit: BoxFit.scaleDown,
//               height: 30.h,
//             ),
//             10.horizontalSpace,
//             Flexible(
//               child: Text(
//                 message,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: AppTextStyles.regular.copyWith(
//                   color: AppColors.whiteColor,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Validates username format. Must start with a letter, Accepts only letters, spaces, and underscores, Length between 1 and 30 characters.
//   static bool isUsernameValid(String username) {
//     String r = r'^[a-zA-Z\s]+$';
//     return RegExp(r).hasMatch(username);
//   }

//   /// Validates email using standard regex pattern.
//   static bool isEmail(String email) {
//     final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
//     return regex.hasMatch(email);
//   }

//   /// Validates general phone number format (international or local).
//   static bool isPhone(String phone) {
//     String r = r'^(\+)?[0-9]{6,15}$';
//     return RegExp(r).hasMatch(phone);
//   }

//   /// Validates password format (international or local).
//   static bool isPassword(String password) {
//     // Requires at least 1 letter and 1 digit, special characters are optional
//     final regex = RegExp(
//       r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]{6,}$',
//     );
//     return regex.hasMatch(password);
//   }

//   /// Validates email field and shows error toast if invalid or empty.
//   static bool validateEmail(TextEditingController value, BuildContext context) {
//     if (value.text.isEmpty) {
//       Utils.errortoastMessage("Please enter your email address", context);
//       return false;
//     } else if (Utils.isEmail(value.text)) {
//       Utils.errortoastMessage("Please enter a valid email address", context);
//       return false;
//     } else {
//       return true;
//     }
//   }

//   /// Validates phone number with optional type label (e.g., mobile, home).
//   static bool validatePhone(
//     TextEditingController value,
//     String type,
//     BuildContext context,
//   ) {
//     if (value.text.isEmpty) {
//       Utils.errortoastMessage("Please enter your $type number", context);
//       return false;
//     } else if (Utils.isPhone(value.text)) {
//       Utils.errortoastMessage("Please enter a valid $type Number", context);
//       return false;
//     } else if (value.text.length < 8 || value.text.length > 15) {
//       Utils.errortoastMessage("Enter 10 digit $type Number", context);
//       return false;
//     } else {
//       return true;
//     }
//   }

//   /// Validates general password with length limits (8–16 characters).
//   static bool validatePassword(
//     TextEditingController value,
//     BuildContext context,
//   ) {
//     final text = value.text.trim();
//     final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$');

//     if (text.isEmpty) {
//       Utils.errortoastMessage("Please enter your password", context);
//       return false;
//     } else if (!regex.hasMatch(text)) {
//       Utils.errortoastMessage(
//         "Password must be at least 6 characters with at least 1 letter and 1 number",
//         context,
//       );
//       return false;
//     } else if (text.length > 16) {
//       Utils.errortoastMessage(
//         "Password should not exceed 16 characters",
//         context,
//       );
//       return false;
//     } else {
//       return true;
//     }
//   }

//   /// Validates new password field (same as validatePassword but with a different message).
//   static bool validateNewPassword(
//     TextEditingController value,
//     BuildContext context,
//   ) {
//     final text = value.text.trim();
//     final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$');

//     if (text.isEmpty) {
//       Utils.errortoastMessage("Please enter your password", context);
//       return false;
//     } else if (!regex.hasMatch(text)) {
//       Utils.errortoastMessage(
//         "Password must be at least 6 characters with at least 1 letter and 1 number",
//         context,
//       );
//       return false;
//     } else if (text.length > 16) {
//       Utils.errortoastMessage(
//         "Password should not exceed 16 characters",
//         context,
//       );
//       return false;
//     } else {
//       return true;
//     }
//   }

//   /// Validates the current/existing password (for reset/update scenarios).
//   static bool validateExistingPassword(
//     TextEditingController value,
//     BuildContext context,
//   ) {
//     if (value.text.isEmpty) {
//       Utils.errortoastMessage("Please enter your password", context);
//       return false;
//     } else if (value.text.length < 8 || value.text.length > 16) {
//       Utils.errortoastMessage("Current password is incorrect", context);
//       return false;
//     } else {
//       return true;
//     }
//   }

//   /// Validates that confirm password matches the original password.
//   static bool validateConfirmPassword(
//     TextEditingController value1,
//     TextEditingController value2,
//     BuildContext context,
//   ) {
//     if (value2.text.isEmpty) {
//       Utils.errortoastMessage("Please enter Confirm Password", context);
//       return false;
//     } else if (value1.text != value2.text) {
//       Utils.errortoastMessage("Password does not match", context);
//       return false;
//     } else {
//       return true;
//     }
//   }

//   /// Launches a URL in the default browser or external app
//   /// Returns true if successful, false otherwise
//   static Future<bool> launchWebUrl(String url, {BuildContext? context}) async {
//     try {
//       Utils.logInfo(name: "Utils", "Attempting to launch URL: $url");

//       final uri = Uri.parse(url);

//       if (await canLaunchUrl(uri)) {
//         final launched = await launchUrl(
//           uri,
//           mode: LaunchMode.externalApplication,
//         );

//         if (launched) {
//           Utils.logInfo(name: "Utils", "Successfully launched URL: $url");
//           return true;
//         } else {
//           Utils.logError(name: "Utils", "Failed to launch URL: $url");
//           if (context != null) {
//             Utils.errortoastMessage("Could not open the link", context);
//           }
//           return false;
//         }
//       } else {
//         Utils.logError(name: "Utils", "Cannot launch URL: $url");
//         if (context != null) {
//           Utils.errortoastMessage("Cannot open this type of link", context);
//         }
//         return false;
//       }
//     } catch (e) {
//       Utils.logError(name: "Utils", "Error launching URL: $url, Error: $e");
//       if (context != null) {
//         Utils.errortoastMessage("Error opening link: ${e.toString()}", context);
//       }
//       return false;
//     }
//   }

//   /// Launches a document download URL
//   /// Specifically designed for document downloads with proper error handling
//   static Future<bool> launchDocumentUrl(
//     String documentUrl, {
//     BuildContext? context,
//   }) async {
//     try {
//       Utils.logInfo(
//         name: "Utils",
//         "Attempting to download document: $documentUrl",
//       );

//       final uri = Uri.parse(documentUrl);

//       if (await canLaunchUrl(uri)) {
//         final launched = await launchUrl(
//           uri,
//           mode: LaunchMode.inAppBrowserView,
//         );

//         if (launched) {
//           Utils.logInfo(
//             name: "Utils",
//             "Successfully initiated document download: $documentUrl",
//           );
//           if (context != null) {
//             Utils.successtoastMessage("Document download started", context);
//           }
//           return true;
//         } else {
//           Utils.logError(
//             name: "Utils",
//             "Failed to launch document URL: $documentUrl",
//           );
//           if (context != null) {
//             Utils.errortoastMessage(
//               "Could not start document download",
//               context,
//             );
//           }
//           return false;
//         }
//       } else {
//         Utils.logError(
//           name: "Utils",
//           "Cannot launch document URL: $documentUrl",
//         );
//         if (context != null) {
//           Utils.errortoastMessage("Cannot download this document", context);
//         }
//         return false;
//       }
//     } catch (e) {
//       Utils.logError(
//         name: "Utils",
//         "Error launching document URL: $documentUrl, Error: $e",
//       );
//       if (context != null) {
//         Utils.errortoastMessage(
//           "Error downloading document: ${e.toString()}",
//           context,
//         );
//       }
//       return false;
//     }
//   }
// }
