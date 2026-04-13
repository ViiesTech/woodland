import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/services/contact_service.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final authState = context.read<AuthBloc>().state;
    String? userId;
    String? userEmail;

    if (authState is Authenticated) {
      userId = authState.user.id;
      userEmail = authState.user.email;
    }

    final success = await ContactService.submitContact(
      name: _nameController.text.trim(),
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim().isEmpty
          ? null
          : _messageController.text.trim(),
      userId: userId,
      userEmail: userEmail,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      if (mounted) {
        CustomToast.showSuccess(context, 'Message sent successfully!');
        _nameController.clear();
        _subjectController.clear();
        _messageController.clear();
      }
    } else {
      if (mounted) {
        CustomToast.showError(
          context,
          'Failed to send message. Please try again.',
        );
      }
    }
  }

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
          'Contact Us',
          style: AppTextStyles.lufgaLarge.copyWith(
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Find Us Section
              Text(
                'Find Us',
                style: AppTextStyles.lufgaLarge.copyWith(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              20.verticalSpace,
              Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    color: AppColors.primaryColor,
                    size: 24.sp,
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: Text(
                      'Email: \ndg@messagesfromthewoodlands.com',
                      style: AppTextStyles.lufgaMedium.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ],
              ),
              40.verticalSpace,

              // Get In Touch Section
              Text(
                'Get In Touch',
                style: AppTextStyles.lufgaLarge.copyWith(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              30.verticalSpace,

              // Name Field
              TextFormField(
                controller: _nameController,
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
                decoration: InputDecoration(
                  labelText: 'Your name',
                  labelStyle: AppTextStyles.lufgaMedium.copyWith(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16.sp,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primaryColor,
                      width: 1,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              30.verticalSpace,

              // Subject Field
              TextFormField(
                controller: _subjectController,
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: AppTextStyles.lufgaMedium.copyWith(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16.sp,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primaryColor,
                      width: 1,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a subject';
                  }
                  return null;
                },
              ),
              30.verticalSpace,

              // Message Field
              TextFormField(
                controller: _messageController,
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Your message (optional)',
                  labelStyle: AppTextStyles.lufgaMedium.copyWith(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16.sp,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primaryColor,
                      width: 1,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              40.verticalSpace,

              // Submit Button
              Center(
                child: PrimaryButton(
                  buttonWidth: double.infinity,
                  title: _isSubmitting ? 'SUBMITTING...' : 'SUBMIT',
                  onTap: _isSubmitting ? null : _submitForm,
                ),
              ),
              40.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
