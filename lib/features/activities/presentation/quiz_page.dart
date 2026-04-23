import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:palavra_viva/core/constants/app_colors.dart';
import 'package:palavra_viva/shared/widgets/pv_scaffold.dart';

import '../../study/application/study_controller.dart';
import '../application/quiz_controller.dart';

class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({super.key});

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  int _questionIndex = 0;
  int? _selectedIndex;
  bool _finished = false;
  String? _activeStudyDateId;

  void _confirmAnswer(int totalQuestions, int correctIndex) {
    if (_selectedIndex == null) return;

    final isCorrect = _selectedIndex == correctIndex;
    ref.read(quizControllerProvider.notifier).answer(correct: isCorrect);

    if (_questionIndex == totalQuestions - 1) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _questionIndex++;
      _selectedIndex = null;
    });
  }

  void _restart() {
    ref.read(quizControllerProvider.notifier).reset();
    setState(() {
      _questionIndex = 0;
      _selectedIndex = null;
      _finished = false;
    });
  }

  void _resetForStudyIfNeeded(String studyDateId) {
    if (_activeStudyDateId == studyDateId) return;
    _activeStudyDateId = studyDateId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(quizControllerProvider.notifier).reset();
      setState(() {
        _questionIndex = 0;
        _selectedIndex = null;
        _finished = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final studyAsync = ref.watch(studyControllerProvider);
    final quizState = ref.watch(quizControllerProvider);

    return PvScaffold(
      title: 'Quiz Bíblico',
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: studyAsync.when(
          data: (study) {
            _resetForStudyIfNeeded(study.dateId);
            final questions = study.quiz;
            if (questions.isEmpty) {
              return const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'O estudo de hoje ainda não possui quiz. Gere um estudo primeiro.',
                    ),
                  ),
                ),
              );
            }

            if (_finished) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceTint,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(
                              Icons.emoji_events_outlined,
                              size: 38,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Quiz concluído',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pontuação acumulada: ${quizState.score}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _restart,
                              child: const Text('Refazer quiz'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            final safeQuestionIndex = _questionIndex.clamp(
              0,
              questions.length - 1,
            );
            final question = questions[safeQuestionIndex];
            final position = safeQuestionIndex + 1;
            final progress = position / questions.length;

            return ListView(
              key: ValueKey<String>('${study.dateId}-$safeQuestionIndex'),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pergunta $position de ${questions.length}',
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            color: AppColors.secondary,
                            backgroundColor: AppColors.border,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          question.question,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ...List.generate(
                  question.options.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _QuizOptionTile(
                      selected: _selectedIndex == index,
                      text: question.options[index],
                      onTap: () => setState(() => _selectedIndex = index),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FilledButton(
                  onPressed: _selectedIndex == null
                      ? null
                      : () => _confirmAnswer(
                          questions.length,
                          question.correctIndex,
                        ),
                  child: Text(
                    safeQuestionIndex == questions.length - 1
                        ? 'Finalizar'
                        : 'Próxima',
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Falha ao carregar quiz: $error'),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizOptionTile extends StatelessWidget {
  const _QuizOptionTile({
    required this.selected,
    required this.text,
    required this.onTap,
  });

  final bool selected;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.accent : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
