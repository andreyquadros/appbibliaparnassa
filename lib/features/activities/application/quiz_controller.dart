import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/gamification.dart';
import '../../dashboard/application/progress_controller.dart';

class QuizState {
  const QuizState({this.score = 0, this.combo = 0, this.questionsAnswered = 0});

  final int score;
  final int combo;
  final int questionsAnswered;

  QuizState copyWith({int? score, int? combo, int? questionsAnswered}) {
    return QuizState(
      score: score ?? this.score,
      combo: combo ?? this.combo,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
    );
  }
}

class QuizController extends StateNotifier<QuizState> {
  QuizController(this.ref) : super(const QuizState());

  final Ref ref;

  void answer({required bool correct}) {
    if (correct) {
      final combo = state.combo + 1;
      state = state.copyWith(
        score: state.score + 10 + (combo >= 3 ? 5 : 0),
        combo: combo,
        questionsAnswered: state.questionsAnswered + 1,
      );
      ref
          .read(progressControllerProvider)
          .grantAction(GamificationAction.correctQuiz);
      return;
    }

    state = state.copyWith(
      combo: 0,
      questionsAnswered: state.questionsAnswered + 1,
    );
  }

  void reset() {
    state = const QuizState();
  }
}

final quizControllerProvider = StateNotifierProvider<QuizController, QuizState>(
  (ref) {
    return QuizController(ref);
  },
);
