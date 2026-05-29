import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/models/quiz_model.dart';
import 'package:the_woodlands_series/services/quiz_service.dart';

class AddQuizScreen extends StatefulWidget {
  final QuizModel? quizToEdit;

  const AddQuizScreen({super.key, this.quizToEdit});

  @override
  State<AddQuizScreen> createState() => _AddQuizScreenState();
}

class _AddQuizScreenState extends State<AddQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  List<QuestionDraft> _questions = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.quizToEdit != null) {
      _titleController.text = widget.quizToEdit!.title;
      _descriptionController.text = widget.quizToEdit!.description;
      _questions = widget.quizToEdit!.questions.map((q) {
        return QuestionDraft(
          questionController: TextEditingController(text: q.questionText),
          optionControllers: q.options.map((opt) => TextEditingController(text: opt)).toList(),
          correctIndex: q.correctOptionIndex,
        );
      }).toList();
    } else {
      // Add one default question
      _addQuestion();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuestionDraft(
        questionController: TextEditingController(),
        optionControllers: [
          TextEditingController(),
          TextEditingController(),
        ],
        correctIndex: 0,
      ));
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) {
      CustomToast.showError(context, 'A quiz must have at least one question!');
      return;
    }
    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
    });
  }

  void _addOption(int questionIndex) {
    final question = _questions[questionIndex];
    if (question.optionControllers.length >= 6) {
      CustomToast.showError(context, 'Maximum of 6 options allowed per question!');
      return;
    }
    setState(() {
      question.optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int questionIndex, int optionIndex) {
    final question = _questions[questionIndex];
    if (question.optionControllers.length <= 2) {
      CustomToast.showError(context, 'A question must have at least 2 options!');
      return;
    }
    setState(() {
      question.optionControllers[optionIndex].dispose();
      question.optionControllers.removeAt(optionIndex);
      // Adjust correct index if needed
      if (question.correctIndex >= question.optionControllers.length) {
        question.correctIndex = question.optionControllers.length - 1;
      }
    });
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      CustomToast.showError(context, 'Please enter a quiz title');
      return;
    }

    if (description.isEmpty) {
      CustomToast.showError(context, 'Please enter a quiz description');
      return;
    }

    // Validate questions and options
    List<QuestionModel> finalQuestions = [];
    for (int i = 0; i < _questions.length; i++) {
      final qDraft = _questions[i];
      final qText = qDraft.questionController.text.trim();
      if (qText.isEmpty) {
        CustomToast.showError(context, 'Question ${i + 1} cannot be blank!');
        return;
      }

      List<String> finalOptions = [];
      for (int o = 0; o < qDraft.optionControllers.length; o++) {
        final oText = qDraft.optionControllers[o].text.trim();
        if (oText.isEmpty) {
          CustomToast.showError(context, 'Option ${o + 1} of Question ${i + 1} cannot be blank!');
          return;
        }
        finalOptions.add(oText);
      }

      if (qDraft.correctIndex < 0 || qDraft.correctIndex >= finalOptions.length) {
        CustomToast.showError(context, 'Please select a correct answer for Question ${i + 1}');
        return;
      }

      finalQuestions.add(QuestionModel(
        questionText: qText,
        options: finalOptions,
        correctOptionIndex: qDraft.correctIndex,
      ));
    }

    setState(() {
      _isSaving = true;
    });

    try {
      bool success;
      if (widget.quizToEdit != null) {
        final updatedQuiz = widget.quizToEdit!.copyWith(
          title: title,
          description: description,
          questions: finalQuestions,
        );
        success = await QuizService.updateQuiz(updatedQuiz);
      } else {
        final newQuiz = QuizModel(
          id: '',
          title: title,
          description: description,
          questions: finalQuestions,
          isPublished: false, // Starts as draft
          createdAt: DateTime.now(),
        );
        success = await QuizService.createQuiz(newQuiz);
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        if (success) {
          CustomToast.showSuccess(
            context,
            widget.quizToEdit != null ? 'Quiz updated successfully!' : 'Quiz created successfully!',
          );
          Navigator.pop(context);
        } else {
          CustomToast.showError(context, 'Failed to save quiz to Firestore');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        CustomToast.showError(context, 'An error occurred: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.quizToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.bgClr,
      appBar: AppBar(
        backgroundColor: AppColors.boxClr,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Quiz' : 'Create Quiz',
          style: AppTextStyles.lufgaMedium.copyWith(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isSaving)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: AppColors.primaryColor, strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveQuiz,
              child: Text(
                'Save',
                style: AppTextStyles.lufgaRegular.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Description section
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.boxClr,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz Details',
                      style: AppTextStyles.lufgaMedium.copyWith(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    16.verticalSpace,
                    PrimaryTextField(
                      controller: _titleController,
                      hint: 'Enter Quiz Title (e.g. Finn and the Glowshrooms)',
                      height: 55.h,
                      verticalPad: 10.h,
                    ),
                    12.verticalSpace,
                    PrimaryTextField(
                      controller: _descriptionController,
                      hint: 'Enter Quiz Description (e.g. Test your understanding of Chapter 3)',
                      height: 55.h,
                      verticalPad: 10.h,
                    ),
                  ],
                ),
              ),
              24.verticalSpace,

              // Questions header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Questions (${_questions.length})',
                    style: AppTextStyles.lufgaMedium.copyWith(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.blackColor,
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    icon: Icon(Icons.add, size: 18.sp),
                    label: Text(
                      'Add Question',
                      style: AppTextStyles.small.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              16.verticalSpace,

              // Questions List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                itemBuilder: (context, qIndex) {
                  final qDraft = _questions[qIndex];

                  return Container(
                    margin: EdgeInsets.only(bottom: 20.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.boxClr,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Question ${qIndex + 1}',
                              style: AppTextStyles.lufgaMedium.copyWith(
                                color: AppColors.primaryColor,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeQuestion(qIndex),
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        12.verticalSpace,
                        PrimaryTextField(
                          controller: qDraft.questionController,
                          hint: 'Enter Question text',
                          height: 55.h,
                          verticalPad: 10.h,
                        ),
                        16.verticalSpace,
                        Text(
                          'Options (Select the correct answer checkmark)',
                          style: AppTextStyles.small.copyWith(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        12.verticalSpace,

                        // Options Fields
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: qDraft.optionControllers.length,
                          itemBuilder: (context, oIndex) {
                            final oController = qDraft.optionControllers[oIndex];
                            final isCorrect = qDraft.correctIndex == oIndex;

                            return Container(
                              margin: EdgeInsets.only(bottom: 10.h),
                              child: Row(
                                children: [
                                  // Correct Choice Selector
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        qDraft.correctIndex = oIndex;
                                      });
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(right: 12.w),
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: isCorrect
                                            ? AppColors.primaryColor
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isCorrect
                                              ? AppColors.primaryColor
                                              : Colors.white.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: isCorrect ? Colors.black : Colors.transparent,
                                        size: 16.sp,
                                      ),
                                    ),
                                  ),
                                  
                                  // Option Text Field
                                  Expanded(
                                    child: PrimaryTextField(
                                      controller: oController,
                                      hint: 'Option ${oIndex + 1}',
                                      height: 50.h,
                                      verticalPad: 8.h,
                                    ),
                                  ),
                                  
                                  // Delete Option Button
                                  if (qDraft.optionControllers.length > 2)
                                    IconButton(
                                      onPressed: () => _removeOption(qIndex, oIndex),
                                      icon: const Icon(Icons.close, color: Colors.grey),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        
                        // Add option helper row
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => _addOption(qIndex),
                              icon: Icon(Icons.add, size: 16.sp, color: AppColors.primaryColor),
                              label: Text(
                                'Add Option',
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.primaryColor,
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
              ),
              40.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}

class QuestionDraft {
  final TextEditingController questionController;
  final List<TextEditingController> optionControllers;
  int correctIndex;

  QuestionDraft({
    required this.questionController,
    required this.optionControllers,
    required this.correctIndex,
  });

  void dispose() {
    questionController.dispose();
    for (var controller in optionControllers) {
      controller.dispose();
    }
  }
}
