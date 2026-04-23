import 'quiz_question.dart';

class DailyStudy {
  const DailyStudy({
    required this.dateId,
    required this.title,
    required this.passage,
    required this.mainText,
    required this.historicalContext,
    required this.exegesis,
    required this.application,
    required this.connection,
    required this.meditation,
    required this.memoryVerse,
    required this.guidedPrayer,
    required this.quiz,
    required this.reflectionQuestion,
    required this.theme,
    required this.generatedAt,
  });

  final String dateId;
  final String title;
  final String passage;
  final String mainText;
  final String historicalContext;
  final String exegesis;
  final String application;
  final String connection;
  final String meditation;
  final String memoryVerse;
  final String guidedPrayer;
  final List<QuizQuestion> quiz;
  final String reflectionQuestion;
  final String theme;
  final DateTime generatedAt;
}
