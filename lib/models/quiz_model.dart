class QuestionModel {
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;

  QuestionModel({
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctOptionIndex: map['correctOptionIndex'] ?? 0,
    );
  }

  QuestionModel copyWith({
    String? questionText,
    List<String>? options,
    int? correctOptionIndex,
  }) {
    return QuestionModel(
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
    );
  }
}

class QuizModel {
  final String id;
  final String title;
  final String description;
  final List<QuestionModel> questions;
  final bool isPublished;
  final DateTime createdAt;

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    this.isPublished = true,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toMap()).toList(),
      'isPublished': isPublished,
    };
  }

  factory QuizModel.fromFirestore(String id, Map<String, dynamic> map) {
    final questionsList = map['questions'] as List? ?? [];
    final parsedQuestions = questionsList.map((q) {
      return QuestionModel.fromMap(Map<String, dynamic>.from(q));
    }).toList();

    DateTime parsedDate;
    if (map['createdAt'] is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(map['createdAt']);
    } else if (map['createdAt'] is String) {
      parsedDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return QuizModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      questions: parsedQuestions,
      isPublished: map['isPublished'] ?? true,
      createdAt: parsedDate,
    );
  }

  QuizModel copyWith({
    String? id,
    String? title,
    String? description,
    List<QuestionModel>? questions,
    bool? isPublished,
    DateTime? createdAt,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
