import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/services/contact_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminContactListScreen extends StatelessWidget {
  const AdminContactListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      appBar: AppBar(
        backgroundColor: AppColors.boxClr,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Contact Messages',
          style: AppTextStyles.lufgaLarge.copyWith(
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ContactService.getAllContacts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryColor,
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading contacts',
                style: AppTextStyles.medium.copyWith(
                  color: Colors.white,
                ),
              ),
            );
          }

          final contacts = snapshot.data ?? [];

          if (contacts.isEmpty) {
            return Center(
              child: Text(
                'No contact messages yet',
                style: AppTextStyles.medium.copyWith(
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(20.w),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              final isRead = contact['read'] == true;
              final timestamp = contact['createdAt'] as Timestamp?;
              final date = timestamp != null
                  ? DateFormat('MMM dd, yyyy • hh:mm a')
                      .format(timestamp.toDate())
                  : 'Unknown date';

              return Container(
                margin: EdgeInsets.only(bottom: 16.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: isRead ? AppColors.boxClr : AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: isRead
                      ? null
                      : Border.all(
                          color: AppColors.primaryColor,
                          width: 1,
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact['name'] ?? 'Unknown',
                                style: AppTextStyles.lufgaLarge.copyWith(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (contact['userEmail'] != null) ...[
                                4.verticalSpace,
                                Text(
                                  contact['userEmail'],
                                  style: AppTextStyles.medium.copyWith(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 12.w,
                            height: 12.h,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    12.verticalSpace,
                    Text(
                      contact['subject'] ?? 'No subject',
                      style: AppTextStyles.lufgaMedium.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (contact['message'] != null &&
                        contact['message'].toString().isNotEmpty) ...[
                      12.verticalSpace,
                      Text(
                        contact['message'],
                        style: AppTextStyles.medium.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                    12.verticalSpace,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          date,
                          style: AppTextStyles.medium.copyWith(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12.sp,
                          ),
                        ),
                        Row(
                          children: [
                            if (!isRead)
                              TextButton(
                                onPressed: () {
                                  ContactService.markAsRead(contact['id']);
                                },
                                child: Text(
                                  'Mark as Read',
                                  style: TextStyle(
                                    color: AppColors.primaryColor,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red.withOpacity(0.7),
                                size: 20.sp,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    backgroundColor: AppColors.boxClr,
                                    title: Text(
                                      'Delete Message',
                                      style: AppTextStyles.lufgaLarge.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    content: Text(
                                      'Are you sure you want to delete this message?',
                                      style: AppTextStyles.medium.copyWith(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          ContactService.deleteContact(contact['id']);
                                          Navigator.pop(dialogContext);
                                        },
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

