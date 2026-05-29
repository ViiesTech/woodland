import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:the_woodlands_series/models/quiz_model.dart';
import 'package:the_woodlands_series/models/user_model.dart';

class PlayQuizScreen extends StatefulWidget {
  final QuizModel quiz;

  const PlayQuizScreen({super.key, required this.quiz});

  @override
  State<PlayQuizScreen> createState() => _PlayQuizScreenState();
}

class _PlayQuizScreenState extends State<PlayQuizScreen> {
  int _currentIndex = 0;
  
  // Track selected option index for each question (-1 means unanswered)
  late List<int> _selectedAnswers;
  
  int _score = 0;
  bool _quizFinished = false;

  @override
  void initState() {
    super.initState();
    _selectedAnswers = List<int>.filled(widget.quiz.questions.length, -1);
  }

  void _selectOption(int index) {
    setState(() {
      _selectedAnswers[_currentIndex] = index;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _handleSubmitQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _handleSubmitQuiz() {
    // Check if there are unanswered questions
    final unansweredCount = _selectedAnswers.where((ans) => ans == -1).length;
    if (unansweredCount > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.boxClr,
          title: Text(
            'Unfinished Quiz',
            style: AppTextStyles.lufgaMedium.copyWith(color: Colors.white),
          ),
          content: Text(
            'You have $unansweredCount unanswered questions. Are you sure you want to finish and submit the quiz?',
            style: AppTextStyles.regular.copyWith(color: Colors.white.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Go Back',
                style: TextStyle(color: AppColors.primaryColor, fontSize: 14.sp),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _calculateScoreAndFinish();
              },
              child: Text(
                'Submit anyway',
                style: TextStyle(color: Colors.redAccent, fontSize: 14.sp),
              ),
            ),
          ],
        ),
      );
    } else {
      _calculateScoreAndFinish();
    }
  }

  void _calculateScoreAndFinish() {
    int score = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      if (_selectedAnswers[i] == widget.quiz.questions[i].correctOptionIndex) {
        score++;
      }
    }
    setState(() {
      _score = score;
      _quizFinished = true;
    });
  }

  void _resetQuiz() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _quizFinished = false;
      _selectedAnswers = List<int>.filled(widget.quiz.questions.length, -1);
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final user = state is Authenticated ? state.user : null;
            final userName = user?.name ?? 'Explorer';
            
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: _quizFinished 
                  ? _buildResultsView() 
                  : _buildQuizView(user, userName),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuizView(UserModel? user, String userName) {
    final question = widget.quiz.questions[_currentIndex];
    final selectedIdx = _selectedAnswers[_currentIndex];

    // Greeting time calculation
    final hour = DateTime.now().hour;
    String greeting = "Good Morning";
    if (hour >= 12 && hour < 17) {
      greeting = "Good Afternoon";
    } else if (hour >= 17) {
      greeting = "Good Evening";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Greeting + Avatar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppTextStyles.regular.copyWith(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16.sp,
                  ),
                ),
                4.verticalSpace,
                Text(
                  'Hi, $userName!',
                  style: AppTextStyles.lufgaLarge.copyWith(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            _buildUserAvatar(user),
          ],
        ),
        24.verticalSpace,

        // Progress Text and Star Rewards
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_currentIndex + 1} of ${widget.quiz.questions.length}',
              style: AppTextStyles.medium.copyWith(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20.sp),
                2.horizontalSpace,
                Icon(Icons.star, color: Colors.amber, size: 20.sp),
                2.horizontalSpace,
                Icon(Icons.star, color: Colors.amber, size: 24.sp),
              ],
            ),
          ],
        ),
        10.verticalSpace,

        // Orange Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.quiz.questions.length,
            backgroundColor: const Color(0xff123524), // dark green track
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange), // orange fill
            minHeight: 14.h,
          ),
        ),
        24.verticalSpace,

        // Question Container (Rounded Forest Green Box)
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          decoration: BoxDecoration(
            color: const Color(0xff1A3B2B), // Forest Green Container
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Text(
            question.questionText,
            style: AppTextStyles.lufgaMedium.copyWith(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        ),
        24.verticalSpace,

        // MCQ Options
        Expanded(
          child: ListView.separated(
            itemCount: question.options.length,
            separatorBuilder: (context, index) => 12.verticalSpace,
            itemBuilder: (context, optIdx) {
              final optionText = question.options[optIdx];
              final isSelected = optIdx == selectedIdx;
              
              // Determine visual state of this option (No immediate correct/incorrect)
              Color borderColor = const Color(0xff67FFBB).withOpacity(0.4);
              Color bgClr = const Color(0xff1A3B2B).withOpacity(0.4); // soft teal background
              Widget iconWidget = Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              );

              if (isSelected) {
                borderColor = const Color(0xff67FFBB); // Highlighted lime green
                bgClr = const Color(0xff1A3B2B).withOpacity(0.9);
                iconWidget = Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: const BoxDecoration(
                    color: Color(0xff67FFBB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.circle, color: Colors.black, size: 10),
                );
              }

              return GestureDetector(
                onTap: () => _selectOption(optIdx),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    color: bgClr,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: borderColor,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      iconWidget,
                      16.horizontalSpace,
                      Expanded(
                        child: Text(
                          optionText,
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Arrow Navigation Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: _currentIndex > 0 ? Colors.white : Colors.white.withOpacity(0.2), size: 28.sp),
              onPressed: _currentIndex > 0 ? _previousQuestion : null,
            ),
            40.horizontalSpace,
            IconButton(
              icon: Icon(Icons.arrow_forward, color: _currentIndex < widget.quiz.questions.length - 1 ? Colors.white : Colors.white.withOpacity(0.2), size: 28.sp),
              onPressed: _currentIndex < widget.quiz.questions.length - 1 ? _nextQuestion : null,
            ),
          ],
        ),
        16.verticalSpace,

        // Next / Finish Button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff12402A), // Dark Green/Teal
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                _currentIndex == widget.quiz.questions.length - 1 ? 'Finish' : 'Next',
                style: AppTextStyles.lufgaRegular.copyWith(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        8.verticalSpace,
      ],
    );
  }

  Widget _buildUserAvatar(UserModel? user) {
    if (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty) {
      return Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(user.profileImageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    if (user != null) {
      return Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.7)],
          ),
        ),
        child: Center(
          child: Text(
            _getInitials(user.name),
            style: AppTextStyles.lufgaMedium.copyWith(
              color: Colors.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 44.w,
      height: 44.w,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryColor,
      ),
      child: const Icon(Icons.person, color: Colors.black),
    );
  }

  Widget _buildResultsView() {
    final percent = (_score / widget.quiz.questions.length) * 100;
    String scoreText = "Keep trying!";
    IconData scoreIcon = Icons.stars;
    Color scoreColor = Colors.orange;

    if (percent >= 80) {
      scoreText = "Excellent Job!";
      scoreIcon = Icons.emoji_events;
      scoreColor = AppColors.primaryColor;
    } else if (percent >= 50) {
      scoreText = "Good Effort!";
      scoreIcon = Icons.thumb_up;
      scoreColor = Colors.amber;
    }

    return Column(
      children: [
        16.verticalSpace,
        Icon(scoreIcon, size: 70.sp, color: scoreColor),
        16.verticalSpace,
        Text(
          scoreText,
          style: AppTextStyles.lufgaLarge.copyWith(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        8.verticalSpace,
        Text(
          'You scored $_score / ${widget.quiz.questions.length} (${percent.toStringAsFixed(0)}% correct)',
          style: AppTextStyles.regular.copyWith(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14.sp,
          ),
        ),
        20.verticalSpace,

        // Premium Review Answers Header
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Review Answers',
            style: AppTextStyles.lufgaMedium.copyWith(
              color: AppColors.primaryColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        10.verticalSpace,

        // Interactive Review List
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.only(bottom: 16.h),
            itemCount: widget.quiz.questions.length,
            separatorBuilder: (context, index) => 12.verticalSpace,
            itemBuilder: (context, qIndex) {
              final q = widget.quiz.questions[qIndex];
              final userAns = _selectedAnswers[qIndex];
              final correctAns = q.correctOptionIndex;
              final isUserCorrect = userAns == correctAns;

              return Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.boxClr,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isUserCorrect 
                        ? const Color(0xff67FFBB).withOpacity(0.2) 
                        : Colors.redAccent.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${qIndex + 1}: ${q.questionText}',
                      style: AppTextStyles.medium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    8.verticalSpace,
                    if (userAns == -1)
                      Text(
                        'Unanswered (Correct: ${q.options[correctAns]})',
                        style: AppTextStyles.small.copyWith(
                          color: Colors.amber[300],
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (isUserCorrect)
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: const Color(0xff67FFBB), size: 16.sp),
                          8.horizontalSpace,
                          Expanded(
                            child: Text(
                              'Correct! You chose: ${q.options[userAns]}',
                              style: AppTextStyles.small.copyWith(
                                color: const Color(0xff67FFBB),
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.redAccent, size: 16.sp),
                              8.horizontalSpace,
                              Expanded(
                                child: Text(
                                  'Your answer: ${q.options[userAns]}',
                                  style: AppTextStyles.small.copyWith(
                                    color: Colors.redAccent,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          4.verticalSpace,
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: const Color(0xff67FFBB), size: 16.sp),
                              8.horizontalSpace,
                              Expanded(
                                child: Text(
                                  'Correct answer: ${q.options[correctAns]}',
                                  style: AppTextStyles.small.copyWith(
                                    color: const Color(0xff67FFBB),
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        16.verticalSpace,

        // CTAs Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Library',
                  style: AppTextStyles.lufgaRegular.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            16.horizontalSpace,
            Expanded(
              child: ElevatedButton(
                onPressed: _resetQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.blackColor,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Play Again',
                  style: AppTextStyles.lufgaRegular.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        8.verticalSpace,
      ],
    );
  }
}
