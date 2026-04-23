import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:palavra_viva/core/constants/app_colors.dart';
import 'package:palavra_viva/core/services/ai_service.dart';
import 'package:palavra_viva/core/services/bible_api_service.dart';
import 'package:palavra_viva/features/flashcards/application/flashcard_controller.dart';
import 'package:palavra_viva/features/study/application/study_controller.dart';
import 'package:palavra_viva/models/bible_passage.dart';
import 'package:palavra_viva/models/daily_study.dart';
import 'package:palavra_viva/shared/widgets/main_bottom_nav_bar.dart';
import 'package:palavra_viva/shared/widgets/pv_scaffold.dart';

class StudyPage extends ConsumerStatefulWidget {
  const StudyPage({super.key, this.onCompleteStudy});

  final VoidCallback? onCompleteStudy;

  @override
  ConsumerState<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends ConsumerState<StudyPage> {
  final _strongQueryController = TextEditingController();
  final AiService _aiService = AiService();
  List<Map<String, dynamic>> _strongEntries = const [];
  bool _searchingStrong = false;
  String? _strongError;
  bool _addingFlashcard = false;

  @override
  void dispose() {
    _strongQueryController.dispose();
    super.dispose();
  }

  Future<void> _addStudyVerseToFlashcards(DailyStudy study) async {
    setState(() => _addingFlashcard = true);
    try {
      final added = await ref
          .read(flashcardControllerProvider)
          .addFromStudy(study);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added
                ? 'Versículo adicionado aos flashcards.'
                : 'Esse versículo já está na sua revisão.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _addingFlashcard = false);
      }
    }
  }

  Future<void> _searchStrong() async {
    final query = _strongQueryController.text.trim();
    if (query.isEmpty) {
      setState(() => _strongError = 'Digite um termo, lemma ou código Strong.');
      return;
    }

    setState(() {
      _searchingStrong = true;
      _strongError = null;
    });

    try {
      final entries = await _aiService.searchStrong(query);
      if (!mounted) {
        return;
      }
      setState(() => _strongEntries = entries);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _strongError = 'Falha na busca Strong: $error');
    } finally {
      if (mounted) {
        setState(() => _searchingStrong = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studyAsync = ref.watch(studyControllerProvider);
    final showBack = Navigator.of(context).canPop();
    return PvScaffold(
      title: 'Estudo',
      showBackButton: showBack,
      bottomNavigationBar: const MainBottomNavBar(current: MainSection.study),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: ListView(
          children: [
            FilledButton.tonalIcon(
              onPressed: () {
                ref
                    .read(studyControllerProvider.notifier)
                    .refreshStudy(forceGenerate: true);
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Gerar Estudo Personalizado'),
            ),
            const SizedBox(height: 12),
            studyAsync.when(
              data: (study) => _StudyContent(
                study: study,
                onCompleteStudy: widget.onCompleteStudy,
                addingFlashcard: _addingFlashcard,
                onSaveFlashcard: () => _addStudyVerseToFlashcards(study),
              ),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Não foi possível carregar o estudo.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('$error'),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: () {
                          ref
                              .read(studyControllerProvider.notifier)
                              .refreshStudy();
                        },
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _StrongSearchCard(
              queryController: _strongQueryController,
              searching: _searchingStrong,
              errorText: _strongError,
              entries: _strongEntries,
              onSearch: _searchStrong,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _StudyContent extends StatefulWidget {
  const _StudyContent({
    required this.study,
    this.onCompleteStudy,
    this.onSaveFlashcard,
    this.addingFlashcard = false,
  });

  final DailyStudy study;
  final VoidCallback? onCompleteStudy;
  final VoidCallback? onSaveFlashcard;
  final bool addingFlashcard;

  @override
  State<_StudyContent> createState() => _StudyContentState();
}

class _StudyContentState extends State<_StudyContent> {
  final AiService _aiService = AiService();
  final BibleApiService _bibleApiService = BibleApiService();
  late Future<BiblePassage> _passageFuture;
  bool _explanationLoading = false;

  @override
  void initState() {
    super.initState();
    _passageFuture = _loadPassage();
  }

  @override
  void didUpdateWidget(covariant _StudyContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.study.passage != widget.study.passage) {
      _passageFuture = _loadPassage();
    }
  }

  Future<BiblePassage> _loadPassage() {
    return _bibleApiService.fetchPassage(widget.study.passage);
  }

  Future<void> _explainText(String selectedText) async {
    final trimmed = selectedText.trim();
    if (trimmed.isEmpty || _explanationLoading) {
      return;
    }

    setState(() => _explanationLoading = true);
    String passageText = '';
    try {
      final passage = await _passageFuture;
      passageText = passage.text;
    } catch (_) {
      passageText = widget.study.mainText;
    }

    try {
      final explanation = await _aiService.explainScripture(
        reference: widget.study.passage,
        selectedText: trimmed,
        passageText: passageText,
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explicação do texto',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  trimmed,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: MarkdownBody(
                      data: _normalizeAiText(explanation),
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.7,
                        ),
                        strong: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        h1: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                        h2: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao explicar texto: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _explanationLoading = false);
      }
    }
  }

  Future<void> _openChat() async {
    String passageText = widget.study.mainText;
    try {
      final passage = await _passageFuture;
      if (passage.text.trim().isNotEmpty) {
        passageText = passage.text.trim();
      }
    } catch (_) {}

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _StudyChatSheet(
        reference: widget.study.passage,
        passageText: passageText,
      ),
    );
  }

  void _shareStudy() {
    Share.share(
      '${widget.study.passage}\n\n${widget.study.memoryVerse}\n\n${widget.study.mainText}',
      subject: widget.study.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.secondary),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.study.passage.toUpperCase(),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.accent,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.study.title,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '"${widget.study.memoryVerse}"',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            height: 1.55,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tema: ${widget.study.theme}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _StudyActionChip(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Conversar',
                          onTap: _openChat,
                        ),
                        _StudyActionChip(
                          icon: Icons.bookmark_add_outlined,
                          label: widget.addingFlashcard
                              ? 'Salvando...'
                              : 'Salvar',
                          onTap: widget.addingFlashcard
                              ? null
                              : widget.onSaveFlashcard,
                        ),
                        _StudyActionChip(
                          icon: Icons.share_outlined,
                          label: 'Compartilhar',
                          onTap: _shareStudy,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 360.ms)
            .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 12),
        Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _ExplainableParagraph(
                  text: widget.study.mainText,
                  loading: _explanationLoading,
                  onTap: () => _explainText(widget.study.mainText),
                  darkCard: true,
                ),
              ),
            )
            .animate(delay: 40.ms)
            .fadeIn(duration: 360.ms)
            .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 12),
        FutureBuilder<BiblePassage>(
              future: _passageFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Texto bíblico (API gratuita)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Não foi possível buscar o texto agora: ${snapshot.error}',
                          ),
                          const SizedBox(height: 10),
                          FilledButton.tonal(
                            onPressed: () {
                              setState(() => _passageFuture = _loadPassage());
                            },
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final passage = snapshot.data;
                if (passage == null) {
                  return const SizedBox.shrink();
                }

                return Card(
                  color: AppColors.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Texto bíblico',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          passage.reference,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.accent),
                        ),
                        const SizedBox(height: 8),
                        ...passage.verses.map(
                          (verse) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => _explainText(verse.text),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                child: Text(
                                  '${verse.chapter}:${verse.verse} ${verse.text}',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          onPressed: _openChat,
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Modo chat com o texto'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
            .animate(delay: 80.ms)
            .fadeIn(duration: 360.ms)
            .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 12),
        Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contexto',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    _ExplainableParagraph(
                      text: widget.study.historicalContext,
                      loading: _explanationLoading,
                      onTap: () => _explainText(widget.study.historicalContext),
                      darkCard: true,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Exegese',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    _ExplainableParagraph(
                      text: widget.study.exegesis,
                      loading: _explanationLoading,
                      onTap: () => _explainText(widget.study.exegesis),
                      darkCard: true,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aplicação',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    _ExplainableParagraph(
                      text: widget.study.application,
                      loading: _explanationLoading,
                      onTap: () => _explainText(widget.study.application),
                      darkCard: true,
                    ),
                  ],
                ),
              ),
            )
            .animate(delay: 120.ms)
            .fadeIn(duration: 360.ms)
            .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: widget.onCompleteStudy,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Concluir estudo do dia (+50 XP)'),
        ).animate(delay: 160.ms).fadeIn(duration: 320.ms),
        const SizedBox(height: 10),
        Card(
          color: AppColors.primary,
          child: ListTile(
            leading: const Icon(
              Icons.push_pin_outlined,
              color: AppColors.accent,
            ),
            title: Text(
              'Versículo para memorizar: ${widget.study.memoryVerse}',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              widget.study.meditation,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
            ),
            onTap: () => _explainText(widget.study.memoryVerse),
          ),
        ).animate(delay: 180.ms).fadeIn(duration: 320.ms),
        const SizedBox(height: 12),
        Card(
          color: AppColors.primary,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Oração guiada',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                _ExplainableParagraph(
                  text: widget.study.guidedPrayer,
                  loading: _explanationLoading,
                  onTap: () => _explainText(widget.study.guidedPrayer),
                  darkCard: true,
                ),
              ],
            ),
          ),
        ).animate(delay: 220.ms).fadeIn(duration: 320.ms),
        const SizedBox(height: 12),
        Card(
          color: AppColors.primary,
          child: ListTile(
            leading: const Icon(
              Icons.psychology_outlined,
              color: AppColors.accent,
            ),
            title: const Text(
              'Reflexão pessoal',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              widget.study.reflectionQuestion,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
            ),
            onTap: () => _explainText(widget.study.reflectionQuestion),
          ),
        ).animate(delay: 260.ms).fadeIn(duration: 320.ms),
      ],
    );
  }
}

class _ExplainableParagraph extends StatelessWidget {
  const _ExplainableParagraph({
    required this.text,
    required this.onTap,
    required this.loading,
    this.darkCard = false,
  });

  final String text;
  final VoidCallback onTap;
  final bool loading;
  final bool darkCard;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: loading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: _normalizeAiText(text),
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: darkCard ? Colors.white : AppColors.textPrimary,
                  height: 1.7,
                ),
                strong: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: darkCard ? AppColors.accent : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  loading
                      ? Icons.hourglass_top_rounded
                      : Icons.touch_app_outlined,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  loading ? 'Gerando explicação...' : 'Toque para explicar',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: darkCard
                        ? Colors.white.withValues(alpha: 0.76)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyChatSheet extends StatefulWidget {
  const _StudyChatSheet({required this.reference, required this.passageText});

  final String reference;
  final String passageText;

  @override
  State<_StudyChatSheet> createState() => _StudyChatSheetState();
}

class _StudyChatSheetState extends State<_StudyChatSheet> {
  final AiService _aiService = AiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      role: 'assistant',
      text: 'Vamos aprender juntos. Pergunte sobre o texto bíblico.',
    ),
  ];
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final question = _controller.text.trim();
    if (question.isEmpty || _sending) {
      return;
    }

    setState(() {
      _sending = true;
      _messages.add(_ChatMessage(role: 'user', text: question));
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final answer = await _aiService.chatScripture(
        reference: widget.reference,
        passageText: widget.passageText,
        question: question,
        history: _messages
            .map((message) => {'role': message.role, 'content': message.text})
            .toList(growable: false),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: 'assistant', text: answer));
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            role: 'assistant',
            text: 'Falha ao consultar IA agora: $error',
          ),
        );
      });
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.82,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                'Chat do texto',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Text(
                  widget.reference,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg.role == 'user';
                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        constraints: const BoxConstraints(maxWidth: 380),
                        decoration: BoxDecoration(
                          color: isUser
                              ? AppColors.primary
                              : AppColors.surfaceTint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: isUser
                                ? Colors.white
                                : AppColors.textPrimary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        decoration: const InputDecoration(
                          hintText: 'Pergunte sobre o texto...',
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _sending ? null : _send,
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.role, required this.text});

  final String role;
  final String text;
}

class _StudyActionChip extends StatelessWidget {
  const _StudyActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

String _normalizeAiText(String input) {
  final text = input.trim();
  if (text.isEmpty) {
    return 'Sem conteúdo disponível.';
  }

  final normalizedHeaders = text.replaceAllMapped(
    RegExp(r'\*\*(\d+\)\s*[^\n*]+)\*\*'),
    (match) => '\n## ${match.group(1)?.trim() ?? ''}\n',
  );

  return normalizedHeaders
      .replaceAll('•', '- ')
      .replaceAll(RegExp(r'\*\*'), '')
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

class _StrongSearchCard extends StatelessWidget {
  const _StrongSearchCard({
    required this.queryController,
    required this.searching,
    required this.errorText,
    required this.entries,
    required this.onSearch,
  });

  final TextEditingController queryController;
  final bool searching;
  final String? errorText;
  final List<Map<String, dynamic>> entries;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estudo de palavras bíblicas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: queryController,
              decoration: const InputDecoration(
                hintText: 'Ex: H3899, agape, chesed, pão',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onSubmitted: (_) => onSearch(),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: searching ? null : onSearch,
              icon: searching
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.menu_book_outlined),
              label: Text(searching ? 'Consultando...' : 'Buscar no Strong'),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (!searching && errorText == null && entries.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      '${entry['strongNumber'] ?? ''} - ${entry['lemma'] ?? ''}',
                    ),
                    subtitle: Text(
                      '${entry['transliteration'] ?? ''}\n${entry['definition'] ?? ''}',
                    ),
                    isThreeLine: true,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
