import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:the_woodlands_series/bloc/auth/auth_event.dart';
import 'package:the_woodlands_series/models/user_model.dart';
import 'package:the_woodlands_series/services/cloudinary_service.dart';
import 'package:the_woodlands_series/repositories/auth_repository.dart';
import 'package:the_woodlands_series/config/cloudinary_config.dart';
import 'package:the_woodlands_series/screens/profile/change_password_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  UserModel? currentUser;
  bool _isLoading = false;
  bool _removeImage = false; // Flag to track if user wants to remove image

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      setState(() {
        currentUser = authState.user;
        _nameController.text = currentUser?.name ?? '';
        _emailController.text = currentUser?.email ?? '';
        _phoneController.text = currentUser?.phoneNumber ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: CloudinaryConfig.maxImageWidth.toDouble(),
        maxHeight: CloudinaryConfig.maxImageHeight.toDouble(),
        imageQuality: CloudinaryConfig.imageQuality,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _removeImage = false; // User picked a new image, so not removing
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (e.toString().contains('camera_not_available')) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Camera Not Available'),
              content: const Text(
                'The iOS Simulator does not support the camera. Would you like to use the Gallery instead?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                  child: const Text('Open Gallery'),
                ),
              ],
            ),
          );
        }
        return;
      }

      String errorMessage = 'Failed to pick image';
      if (e.toString().contains('access_denied')) {
        errorMessage = 'Camera permission denied via settings';
      }
      CustomToast.showError(context, errorMessage);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.boxClr,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose Profile Picture',
                  style: AppTextStyles.lufgaLarge.copyWith(
                    color: Colors.white,
                    fontSize: 18.sp,
                  ),
                ),
                20.verticalSpace,
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: AppColors.primaryColor,
                  ),
                  title: Text('Camera', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: AppColors.primaryColor,
                  ),
                  title: Text('Gallery', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    // Validate input
    if (_nameController.text.trim().isEmpty) {
      CustomToast.showError(context, 'Please enter your name');
      return;
    }

    if (_nameController.text.trim().length < 3) {
      CustomToast.showError(context, 'Name must be at least 3 characters');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = currentUser?.profileImageUrl;
      String? imageDeleteToken = currentUser?.profileImageDeleteToken;

      // Handle image removal
      if (_removeImage) {
        // Delete old image from Cloudinary if it exists
        if (currentUser?.profileImageDeleteToken != null &&
            currentUser!.profileImageDeleteToken!.isNotEmpty) {
          CustomToast.showInfo(context, 'Removing image...');
          final deleteSuccess = await CloudinaryService.deleteImageWithToken(
            currentUser!.profileImageDeleteToken!,
          );
          if (deleteSuccess) {
            print('Image deleted successfully');
          }
        }
        imageUrl = null;
        imageDeleteToken = null;
      }
      // Upload new image to Cloudinary if a new image is selected
      else if (_selectedImage != null) {
        // Delete old image first if it exists (silently)
        if (currentUser?.profileImageDeleteToken != null &&
            currentUser!.profileImageDeleteToken!.isNotEmpty) {
          final deleteSuccess = await CloudinaryService.deleteImageWithToken(
            currentUser!.profileImageDeleteToken!,
          );
          if (deleteSuccess) {
            print('Old image deleted successfully');
          } else {
            print('Failed to delete old image, continuing with upload...');
          }
        }

        // Upload new image
        CustomToast.showInfo(context, 'Uploading new image...');
        final uploadResult = await CloudinaryService.uploadImage(
          _selectedImage!,
        );

        if (uploadResult == null) {
          CustomToast.showError(context, 'Failed to upload image');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        imageUrl = uploadResult.url;
        imageDeleteToken = uploadResult.deleteToken;
      }

      // Update user model
      final updatedUser = currentUser!.copyWith(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        profileImageUrl: imageUrl,
        profileImageDeleteToken: imageDeleteToken,
      );

      print('═══════════════════════════════════════════════════');
      print('💾 SAVING USER DATA');
      print('═══════════════════════════════════════════════════');
      print('👤 User ID: ${updatedUser.id}');
      print('👤 Name: ${updatedUser.name}');
      print('📧 Email: ${updatedUser.email}');
      print('📞 Phone: ${updatedUser.phoneNumber}');
      print('🔗 Image URL: ${updatedUser.profileImageUrl}');
      print(
        '🔑 Delete Token Length: ${updatedUser.profileImageDeleteToken?.length ?? 0} characters',
      );
      print('═══════════════════════════════════════════════════');

      // Update in repository (cache and Firestore)
      // Create repository instance directly
      final authRepository = AuthRepository();
      print('📤 Calling authRepository.updateUser...');

      final success = await authRepository.updateUser(
        updatedUser,
        updateInFirestore: true,
      );

      print('📥 Update result: $success');

      if (success) {
        print('✅ Update successful! Updating BLoC state...');
        // Update BLoC state with new user data
        if (mounted) {
          context.read<AuthBloc>().add(UpdateUser(updatedUser));
          print('✅ BLoC state updated');
          CustomToast.showSuccess(context, 'Profile updated successfully!');
          Navigator.pop(context, true);
        }
      } else {
        print('❌ Update failed!');
        CustomToast.showError(context, 'Failed to update profile');
      }
    } catch (e, stackTrace) {
      print('❌ EXCEPTION during profile update!');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      // Show only first 100 characters to avoid lengthy toast
      final shortError = e.toString().length > 100
          ? '${e.toString().substring(0, 100)}...'
          : e.toString();
      CustomToast.showError(context, 'Error: $shortError');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      appBar: AppBar(
        backgroundColor: AppColors.bgClr,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        centerTitle: true,
        title: Text(
          'Edit Profile',
          style: AppTextStyles.lufgaLarge.copyWith(
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              40.verticalSpace,

              // Profile Image
              Stack(
                children: [
                  _buildProfileImage(),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryColor,
                          border: Border.all(color: AppColors.bgClr, width: 3),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              40.verticalSpace,

              // Name Field
              PrimaryTextField(
                controller: _nameController,
                hint: 'Full Name',
                shadow: true,
              ),
              20.verticalSpace,

              // Email Field (Read-only)
              PrimaryTextField(
                controller: _emailController,
                hint: 'Email',
                isEnabled: false,
                readOnly: true,
                shadow: true,
              ),
              20.verticalSpace,

              // Phone Field
              PrimaryTextField(
                controller: _phoneController,
                hint: 'Phone Number (Optional)',
                shadow: true,
                keyboard: TextInputType.number,
              ),

              40.verticalSpace,

              // Save Button
              PrimaryButton(
                title: _isLoading ? 'Saving...' : 'Save Changes',
                onTap: _isLoading ? () {} : _saveProfile,
                shadow: true,
              ),

              20.verticalSpace,

              // Change Password Button
              GestureDetector(
                onTap: _navigateToChangePassword,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: AppColors.boxClr,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: AppColors.primaryColor,
                        size: 20.sp,
                      ),
                      10.horizontalSpace,
                      Text(
                        'Change Password',
                        style: AppTextStyles.lufgaMedium.copyWith(
                          color: AppColors.primaryColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              40.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 140.w,
      height: 140.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryColor, width: 3),
      ),
      child: ClipOval(child: _getImageWidget()),
    );
  }

  Widget _getImageWidget() {
    if (_selectedImage != null) {
      // Show selected image from file
      return Image.file(_selectedImage!, fit: BoxFit.cover);
    } else if (!_removeImage &&
        currentUser?.profileImageUrl != null &&
        currentUser!.profileImageUrl!.isNotEmpty) {
      // Show current profile image from network (only if not marked for removal)
      return Image.network(
        currentUser!.profileImageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildAvatarWithInitials();
        },
      );
    } else {
      // Show avatar with initials
      return _buildAvatarWithInitials();
    }
  }

  Widget _buildAvatarWithInitials() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(currentUser?.name ?? 'User'),
          style: AppTextStyles.lufgaLarge.copyWith(
            color: Colors.white,
            fontSize: 48.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'U';
  }

  void _navigateToChangePassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
    );
  }
}
