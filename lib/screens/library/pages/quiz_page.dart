import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:the_woodlands_series/models/quiz_model.dart';
import 'package:the_woodlands_series/services/quiz_service.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'add_quiz_screen.dart';
import 'play_quiz_screen.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => QuizPageState();
}

class QuizPageState extends State<QuizPage> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<QuizModel> _allQuizzes = [];
  bool _isLoading = true;
  Stream<List<QuizModel>>? _quizStream;

  @override
  void initState() {
    super.initState();
    loadQuizzes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void loadQuizzes() {
    if (!mounted) return;
    setState(() {
      _quizStream = QuizService.getAllQuizzes();
      _isLoading = false;
    });
  }

  Future<void> _toggleQuizStatus(QuizModel quiz) async {
    try {
      final newStatus = !quiz.isPublished;
      await QuizService.updateQuizStatus(quiz.id, newStatus);
      if (mounted) {
        CustomToast.showSuccess(
          context,
          'Quiz ${newStatus ? 'published' : 'unpublished'} successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Failed to update status');
      }
    }
  }

  Future<void> _deleteQuiz(QuizModel quiz) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.boxClr,
        title: Text(
          'Delete Quiz',
          style: AppTextStyles.lufgaMedium.copyWith(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${quiz.title}"?',
          style: AppTextStyles.regular.copyWith(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red, fontSize: 14.sp)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await QuizService.deleteQuiz(quiz.id);
        if (mounted) {
          CustomToast.showSuccess(context, 'Quiz deleted successfully!');
        }
      } catch (e) {
        if (mounted) {
          CustomToast.showError(context, 'Failed to delete quiz');
        }
      }
    }
  }

  List<QuizModel> _filterQuizzes(List<QuizModel> quizzes) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return quizzes;
    return quizzes
        .where((q) =>
            q.title.toLowerCase().contains(query) ||
            q.description.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isAdmin = state is Authenticated && state.user.role == 'admin';

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: PrimaryTextField(
                controller: _searchController,
                hint: 'Search Quizzes...',
                prefixIcon: Icon(Icons.search, size: 20.sp),
                height: 55.h,
                verticalPad: 10.h,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            16.verticalSpace,
            Expanded(
              child: _quizStream == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    )
                  : StreamBuilder<List<QuizModel>>(
                      stream: _quizStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading quizzes',
                              style: AppTextStyles.regular.copyWith(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14.sp,
                              ),
                            ),
                          );
                        }

                        final allFiltered = _filterQuizzes(snapshot.data ?? []);
                        final displayQuizzes = isAdmin
                            ? allFiltered
                            : allFiltered.where((q) => q.isPublished).toList();

                        if (displayQuizzes.isEmpty) {
                          return Center(
                            child: Text(
                              'No quizzes found',
                              style: AppTextStyles.regular.copyWith(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14.sp,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          itemCount: displayQuizzes.length,
                          separatorBuilder: (context, index) => 16.verticalSpace,
                          itemBuilder: (context, index) {
                            final quiz = displayQuizzes[index];

                            return Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: AppColors.boxClr,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: AppColors.primaryColor.withOpacity(0.1),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10.r,
                                    offset: Offset(0, 4.h),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(10.w),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.quiz,
                                          color: AppColors.primaryColor,
                                          size: 24.sp,
                                        ),
                                      ),
                                      16.horizontalSpace,
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              quiz.title,
                                              style: AppTextStyles.lufgaMedium.copyWith(
                                                color: Colors.white,
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            4.verticalSpace,
                                            Text(
                                              quiz.description,
                                              style: AppTextStyles.regular.copyWith(
                                                color: Colors.white.withOpacity(0.7),
                                                fontSize: 13.sp,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  16.verticalSpace,
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${quiz.questions.length} Questions',
                                        style: AppTextStyles.medium.copyWith(
                                          color: AppColors.primaryColor,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (isAdmin)
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                AppRouter.routeTo(
                                                  context,
                                                  AddQuizScreen(quizToEdit: quiz),
                                                );
                                              },
                                              icon: Icon(Icons.edit, color: Colors.amber[300], size: 20.sp),
                                            ),
                                            IconButton(
                                              onPressed: () => _deleteQuiz(quiz),
                                              icon: Icon(Icons.delete, color: Colors.redAccent, size: 20.sp),
                                            ),
                                            10.horizontalSpace,
                                            Row(
                                              children: [
                                                Text(
                                                  quiz.isPublished ? 'Live' : 'Draft',
                                                  style: AppTextStyles.small.copyWith(
                                                    color: quiz.isPublished
                                                        ? AppColors.primaryColor
                                                        : Colors.grey,
                                                    fontSize: 12.sp,
                                                  ),
                                                ),
                                                4.horizontalSpace,
                                                Switch(
                                                  value: quiz.isPublished,
                                                  onChanged: (value) => _toggleQuizStatus(quiz),
                                                  activeColor: AppColors.primaryColor,
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                      else
                                        ElevatedButton(
                                          onPressed: () {
                                            if (quiz.questions.isEmpty) {
                                              CustomToast.showError(context, 'This quiz has no questions yet!');
                                              return;
                                            }
                                            AppRouter.routeTo(
                                              context,
                                              PlayQuizScreen(quiz: quiz),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primaryColor,
                                            foregroundColor: AppColors.blackColor,
                                            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12.r),
                                            ),
                                          ),
                                          child: Text(
                                            'Start Quiz',
                                            style: AppTextStyles.lufgaRegular.copyWith(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
            ),
          ],
        );
      },
    );
  }
}
