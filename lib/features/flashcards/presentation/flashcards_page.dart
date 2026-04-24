import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/verse_flashcard.dart';
import '../../../shared/widgets/main_bottom_nav_bar.dart';
import '../../../shared/widgets/pv_scaffold.dart';
import '../application/flashcard_controller.dart';

class FlashcardsPage extends ConsumerStatefulWidget {
  const FlashcardsPage({super.key});

  @override
  ConsumerState<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends ConsumerState<FlashcardsPage> {
  final TextEditingController _themeController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  Future<void> _generate(FlashcardSuggestionType type) async {
    if (_creating) {
      return;
    }

    setState(() => _creating = true);
    try {
      final added = await ref
          .read(flashcardControllerProvider)
          .generateSuggestions(type: type, theme: _themeController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added > 0
                ? '$added flashcards adicionados.'
                : 'Nenhum novo flashcard foi adicionado.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao gerar sugestões: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  Future<void> _openReviewSession(List<VerseFlashcard> cards) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FlashcardReviewSessionPage(cards: cards),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dueAsync = ref.watch(dueFlashcardsProvider);
    final allAsync = ref.watch(allFlashcardsProvider);
    final showBack = Navigator.of(context).canPop();
    final dueCards = dueAsync.asData?.value ?? const <VerseFlashcard>[];
    final allCards = allAsync.asData?.value ?? const <VerseFlashcard>[];
    final reviewCards = dueCards.isNotEmpty ? dueCards : allCards;

    return PvScaffold(
      title: 'Cards',
      showBackButton: showBack,
      bottomNavigationBar: const MainBottomNavBar(current: MainSection.cards),
      body: ListView(
        children: [
          Card(
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sessão de hoje',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 1.1,
                      color: Colors.white.withValues(alpha: 0.76),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _CountPill(
                        label: 'Devidos',
                        value: dueAsync.asData?.value.length ?? 0,
                      ),
                      const SizedBox(width: 8),
                      _CountPill(
                        label: 'Total',
                        value: allAsync.asData?.value.length ?? 0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Faça sua revisão em tela focada, um versículo por vez, com revelação animada e resposta rápida de memória.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (dueAsync.isLoading || allAsync.isLoading)
                    const LinearProgressIndicator(
                      minHeight: 3,
                      color: AppColors.accent,
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: reviewCards.isEmpty
                            ? null
                            : () => _openReviewSession(reviewCards),
                        child: Text(
                          reviewCards.isEmpty
                              ? 'Nenhum card disponível'
                              : dueCards.isNotEmpty
                              ? 'Revisar cards pendentes'
                              : 'Revisar coleção de cards',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gerador de Flashcards',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione lotes prontos ou gere por tema.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _GenerateChip(
                        label: 'Versículos lindos',
                        onTap: _creating
                            ? null
                            : () =>
                                  _generate(FlashcardSuggestionType.beautiful),
                      ),
                      _GenerateChip(
                        label: 'Menores versículos',
                        onTap: _creating
                            ? null
                            : () => _generate(FlashcardSuggestionType.short),
                      ),
                      _GenerateChip(
                        label: 'Mais importantes',
                        onTap: _creating
                            ? null
                            : () =>
                                  _generate(FlashcardSuggestionType.essential),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _themeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Tema (ex.: fé, ansiedade, oração)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(
                        Icons.auto_awesome_outlined,
                        color: AppColors.accent,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.accent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: _creating
                        ? null
                        : () => _generate(FlashcardSuggestionType.byTheme),
                    icon: _creating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.generating_tokens_rounded),
                    label: const Text('Gerar por tema'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          allAsync.when(
            data: (cards) {
              if (cards.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.style_outlined),
                    title: Text('Sua coleção ainda está vazia'),
                    subtitle: Text(
                      'Gere sugestões ou salve versículos para começar.',
                    ),
                  ),
                );
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coleção',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Prévia dos seus próximos cards.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 14),
                      ...cards
                          .take(4)
                          .map(
                            (card) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _CollectionPreviewCard(card: card),
                            ),
                          ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Falha ao carregar flashcards: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FlashcardReviewSessionPage extends ConsumerStatefulWidget {
  const FlashcardReviewSessionPage({super.key, required this.cards});

  final List<VerseFlashcard> cards;

  @override
  ConsumerState<FlashcardReviewSessionPage> createState() =>
      _FlashcardReviewSessionPageState();
}

class _FlashcardReviewSessionPageState
    extends ConsumerState<FlashcardReviewSessionPage> {
  int _index = 0;
  bool _revealed = false;
  bool _submitting = false;

  VerseFlashcard get _current => widget.cards[_index];
  bool get _finished => _index >= widget.cards.length;

  Future<void> _grade(FlashcardReviewGrade grade) async {
    if (_submitting || _finished) {
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(flashcardControllerProvider).review(_current, grade);
      if (!mounted) return;
      if (_index == widget.cards.length - 1) {
        setState(() {
          _index += 1;
          _revealed = false;
        });
        return;
      }

      setState(() {
        _index += 1;
        _revealed = false;
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.cards.length;
    final progress = total == 0 ? 0.0 : ((_index + 1) / total).clamp(0.0, 1.0);

    return PvScaffold(
      title: _finished ? 'Sessão concluída' : 'Revisão de cards',
      showBackButton: true,
      useSafeArea: true,
      bottomNavigationBar: null,
      body: _finished
          ? _ReviewCompleteState(total: total)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Card ${_index + 1} de $total',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Respire, tente lembrar e só então revele.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Center(
                    child: _AnimatedFlashcard(
                      card: _current,
                      revealed: _revealed,
                      onTap: _submitting
                          ? null
                          : () => setState(() => _revealed = !_revealed),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!_revealed)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting
                          ? null
                          : () => setState(() => _revealed = true),
                      child: const Text('Revelar resposta'),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () => _grade(FlashcardReviewGrade.again),
                        child: const Text('Errei'),
                      ),
                      OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () => _grade(FlashcardReviewGrade.hard),
                        child: const Text('Difícil'),
                      ),
                      FilledButton.tonal(
                        onPressed: _submitting
                            ? null
                            : () => _grade(FlashcardReviewGrade.good),
                        child: const Text('Bom'),
                      ),
                      FilledButton(
                        onPressed: _submitting
                            ? null
                            : () => _grade(FlashcardReviewGrade.easy),
                        child: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Fácil'),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}

class _AnimatedFlashcard extends StatelessWidget {
  const _AnimatedFlashcard({
    required this.card,
    required this.revealed,
    this.onTap,
  });

  final VerseFlashcard card;
  final bool revealed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.78,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: revealed ? 1 : 0),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
        builder: (context, value, child) {
          final angle = value * math.pi;
          final isBack = value >= 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _FlashcardFace.back(card: card, onTap: onTap),
                  )
                : _FlashcardFace.front(card: card, onTap: onTap),
          );
        },
      ),
    );
  }
}

class _FlashcardFace extends StatelessWidget {
  const _FlashcardFace.front({required this.card, this.onTap}) : _back = false;

  const _FlashcardFace.back({required this.card, this.onTap}) : _back = true;

  final VerseFlashcard card;
  final VoidCallback? onTap;
  final bool _back;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            color: _back ? Colors.white : AppColors.primary,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.secondary, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _back ? 'RESPOSTA' : 'VERSÍCULO',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _back ? AppColors.textSecondary : AppColors.accent,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  card.reference.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _back ? AppColors.secondary : Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  _back
                      ? '"${card.verseText}"'
                      : 'Tente lembrar deste texto antes de tocar para revelar.',
                  style:
                      (_back
                              ? Theme.of(context).textTheme.headlineSmall
                              : Theme.of(context).textTheme.bodyLarge)
                          ?.copyWith(
                            color: _back ? AppColors.textPrimary : Colors.white,
                            height: 1.7,
                          ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      _back
                          ? Icons.auto_awesome_rounded
                          : Icons.touch_app_rounded,
                      color: _back ? AppColors.secondary : AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _back
                            ? 'Agora escolha como foi sua lembrança.'
                            : 'Toque no card para iniciar a revelação animada.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _back
                              ? AppColors.textSecondary
                              : Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCompleteState extends StatelessWidget {
  const _ReviewCompleteState({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: AppColors.primary,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.accent,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Sessão concluída',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                'Você revisou $total card${total == 1 ? '' : 's'} nesta sessão.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Voltar para Cards'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionPreviewCard extends StatelessWidget {
  const _CollectionPreviewCard({required this.card});

  final VerseFlashcard card;

  @override
  Widget build(BuildContext context) {
    final dueLabel = card.isDue ? 'Pendente' : 'Programado';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.style_outlined, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.reference,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  card.verseText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: card.isDue
                  ? AppColors.accent.withValues(alpha: 0.32)
                  : Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              dueLabel,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _GenerateChip extends StatelessWidget {
  const _GenerateChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      avatar: const Icon(
        Icons.add_circle_outline,
        size: 16,
        color: AppColors.darkPrimary,
      ),
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
      labelStyle: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(color: AppColors.darkPrimary),
    );
  }
}
