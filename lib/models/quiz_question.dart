class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}
