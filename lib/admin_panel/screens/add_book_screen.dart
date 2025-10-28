import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import '../models/book_model.dart';
import '../services/firebase_service.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _coverImageController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _audioFileController = TextEditingController();
  final TextEditingController _readTimeController = TextEditingController();
  final TextEditingController _listenTimeController = TextEditingController();

  String _selectedCategory = 'Fiction';
  bool _isPublished = false;
  bool _isLoading = false;

  final List<String> _categories = [
    'Fiction',
    'Non-Fiction',
    'Fantasy',
    'Adventure',
    'Mystery',
    'Romance',
    'Science Fiction',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _coverImageController.dispose();
    _contentController.dispose();
    _audioFileController.dispose();
    _readTimeController.dispose();
    _listenTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      appBar: AppBar(
        backgroundColor: AppColors.boxClr,
        title: Text(
          'Add New Book',
          style: AppTextStyles.lufgaMedium.copyWith(
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;
          final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
          final isDesktop = constraints.maxWidth >= 1024;
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16.w : isTablet ? 20.w : 24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              _buildSectionTitle('Basic Information'),
              16.verticalSpace,
              
              PrimaryTextField(
                controller: _titleController,
                hint: 'Book Title',
                validator: (value) => value?.isEmpty == true ? 'Title is required' : null,
              ),
              16.verticalSpace,
              
              PrimaryTextField(
                controller: _authorController,
                hint: 'Author Name',
                validator: (value) => value?.isEmpty == true ? 'Author is required' : null,
              ),
              16.verticalSpace,
              
              PrimaryTextField(
                controller: _descriptionController,
                hint: 'Book Description',
                validator: (value) => value?.isEmpty == true ? 'Description is required' : null,
              ),
              16.verticalSpace,

              // Category Dropdown
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.boxClr,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    style: AppTextStyles.medium.copyWith(color: Colors.white),
                    dropdownColor: AppColors.boxClr,
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                ),
              ),
              24.verticalSpace,

              // Media Files
              _buildSectionTitle('Media Files'),
              16.verticalSpace,
              
              PrimaryTextField(
                controller: _coverImageController,
                hint: 'Cover Image URL',
                validator: (value) => value?.isEmpty == true ? 'Cover image is required' : null,
              ),
              16.verticalSpace,
              
              PrimaryTextField(
                controller: _audioFileController,
                hint: 'Audio File URL (optional)',
              ),
              24.verticalSpace,

              // Content
              _buildSectionTitle('Content'),
              16.verticalSpace,
              
              PrimaryTextField(
                controller: _contentController,
                hint: 'Book Content (Text)',
                validator: (value) => value?.isEmpty == true ? 'Content is required' : null,
              ),
              24.verticalSpace,

              // Timing Information
              _buildSectionTitle('Timing Information'),
              16.verticalSpace,
              
              _buildTimingFields(isMobile),
              24.verticalSpace,

              // Publishing Options
              _buildSectionTitle('Publishing Options'),
              16.verticalSpace,
              
              Row(
                children: [
                  Checkbox(
                    value: _isPublished,
                    onChanged: (value) {
                      setState(() {
                        _isPublished = value!;
                      });
                    },
                    activeColor: AppColors.primaryColor,
                  ),
                  Text(
                    'Publish immediately',
                    style: AppTextStyles.medium.copyWith(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
              30.verticalSpace,

              // Action Buttons
              _buildActionButtons(isMobile),
              20.verticalSpace,
            ],
          ),
          ));
        },
      ),
    );
  }

  Widget _buildTimingFields(bool isMobile) {
    if (isMobile) {
      // Mobile: Stack vertically
      return Column(
        children: [
          PrimaryTextField(
            controller: _readTimeController,
            hint: 'Read Time (minutes)',
            validator: (value) => value?.isEmpty == true ? 'Read time is required' : null,
          ),
          16.verticalSpace,
          PrimaryTextField(
            controller: _listenTimeController,
            hint: 'Listen Time (minutes)',
          ),
        ],
      );
    } else {
      // Desktop/Tablet: Side by side
      return Row(
        children: [
          Expanded(
            child: PrimaryTextField(
              controller: _readTimeController,
              hint: 'Read Time (minutes)',
              validator: (value) => value?.isEmpty == true ? 'Read time is required' : null,
            ),
          ),
          16.horizontalSpace,
          Expanded(
            child: PrimaryTextField(
              controller: _listenTimeController,
              hint: 'Listen Time (minutes)',
            ),
          ),
        ],
      );
    }
  }

  Widget _buildActionButtons(bool isMobile) {
    if (isMobile) {
      // Mobile: Stack vertically
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              title: 'Save as Draft',
              onTap: _saveAsDraft,
            ),
          ),
          12.verticalSpace,
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              title: _isLoading ? 'Saving...' : 'Publish Book',
              onTap: _publishBook,
            ),
          ),
        ],
      );
    } else {
      // Desktop/Tablet: Side by side
      return Row(
        children: [
          Expanded(
            child: PrimaryButton(
              title: 'Save as Draft',
              onTap: _saveAsDraft,
            ),
          ),
          16.horizontalSpace,
          Expanded(
            child: PrimaryButton(
              title: _isLoading ? 'Saving...' : 'Publish Book',
              onTap: _publishBook,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.lufgaMedium.copyWith(
        color: AppColors.primaryColor,
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _saveAsDraft() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final book = BookModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          author: _authorController.text,
          description: _descriptionController.text,
          coverImageUrl: _coverImageController.text,
          content: _contentController.text,
          audioFileUrl: _audioFileController.text,
          category: _selectedCategory,
          readTime: int.tryParse(_readTimeController.text) ?? 0,
          listenTime: int.tryParse(_listenTimeController.text) ?? 0,
          isPublished: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await FirebaseService.addBook(book);
        _showSnackBar('Book saved as draft successfully!');
        Navigator.pop(context);
      } catch (e) {
        _showSnackBar('Error saving book: $e');
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _publishBook() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final book = BookModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          author: _authorController.text,
          description: _descriptionController.text,
          coverImageUrl: _coverImageController.text,
          content: _contentController.text,
          audioFileUrl: _audioFileController.text,
          category: _selectedCategory,
          readTime: int.tryParse(_readTimeController.text) ?? 0,
          listenTime: int.tryParse(_listenTimeController.text) ?? 0,
          isPublished: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await FirebaseService.addBook(book);
        _showSnackBar('Book published successfully!');
        Navigator.pop(context);
      } catch (e) {
        _showSnackBar('Error publishing book: $e');
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }
}
