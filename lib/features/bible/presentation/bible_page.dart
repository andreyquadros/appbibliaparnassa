import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:palavra_viva/core/constants/app_colors.dart';
import 'package:palavra_viva/core/services/ai_service.dart';
import 'package:palavra_viva/core/services/bible_api_service.dart';
import 'package:palavra_viva/core/services/local_cache_service.dart';
import 'package:palavra_viva/features/bible/data/bible_books.dart';
import 'package:palavra_viva/features/bible/data/bible_library_repository.dart';
import 'package:palavra_viva/features/study/data/study_repository.dart';
import 'package:palavra_viva/models/bible_passage.dart';
import 'package:palavra_viva/shared/widgets/main_bottom_nav_bar.dart';
import 'package:palavra_viva/shared/widgets/pv_scaffold.dart';

class BiblePage extends StatefulWidget {
  const BiblePage({super.key});

  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage> {
  static const _favoritesKey = 'bible:favorites';
  static const _historyKey = 'bible:history';
  static const _translationKey = 'bible:preferred_translation';
  static const _currentBookIdKey = 'bible:current_book_id';
  static const _currentChapterKey = 'bible:current_chapter';
  static const _defaultTranslation = 'almeida';
  static const _defaultBookId = 'salmos';
  static const _defaultChapter = 119;

  static const _translations = <_BibleTranslationOption>[
    _BibleTranslationOption(
      code: 'almeida',
      label: 'Almeida',
      subtitle: 'Português',
    ),
    _BibleTranslationOption(
      code: 'kjv',
      label: 'King James',
      subtitle: 'English',
    ),
    _BibleTranslationOption(
      code: 'web',
      label: 'World English',
      subtitle: 'English',
    ),
  ];

  final BibleApiService _bibleApiService = BibleApiService();
  final BibleLibraryRepository _libraryRepository = BibleLibraryRepository();
  final AiService _aiService = AiService();
  final StudyRepository _studyRepository = StudyRepository();

  BiblePassage? _passage;
  String? _errorText;
  bool _loading = false;
  bool _explaining = false;
  bool _syncing = false;
  String _selectedTranslation = _defaultTranslation;
  String _selectedBookId = _defaultBookId;
  int _selectedChapter = _defaultChapter;
  List<BibleLibraryEntry> _favorites = const <BibleLibraryEntry>[];
  List<BibleLibraryEntry> _history = const <BibleLibraryEntry>[];
  bool _hasSavedReadingLocation = false;

  BibleBookDefinition get _selectedBook => bibleBookById(_selectedBookId);

  @override
  void initState() {
    super.initState();
    _restoreLocalState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  Future<void> _bootstrap() async {
    await _syncLibraryFromRemote();
    if (!_hasSavedReadingLocation) {
      await _applyDailyStudyDefault();
    }
    await _loadCurrentSelection();
  }

  void _restoreLocalState() {
    final box = LocalCacheService.box;
    final translation = (box.get(_translationKey) as String?)
        ?.trim()
        .toLowerCase();
    final bookId = (box.get(_currentBookIdKey) as String?)?.trim();
    final chapterRaw = box.get(_currentChapterKey);
    final chapter = switch (chapterRaw) {
      final int value => value,
      final num value => value.toInt(),
      _ => _defaultChapter,
    };
    final preferredTranslation = translation != null && translation.isNotEmpty
        ? translation
        : _defaultTranslation;
    final hasSavedLocation =
        bookId != null && bookId.isNotEmpty && chapterRaw != null;

    setState(() {
      _selectedTranslation = preferredTranslation;
      _selectedBookId = bookId != null && bookId.isNotEmpty
          ? bookId
          : _defaultBookId;
      _selectedChapter = chapter > 0 ? chapter : _defaultChapter;
      _favorites = _normalizeEntries(
        box.get(_favoritesKey),
        fallbackTranslation: preferredTranslation,
      );
      _history = _normalizeEntries(
        box.get(_historyKey),
        fallbackTranslation: preferredTranslation,
      );
      _hasSavedReadingLocation = hasSavedLocation;
    });
  }

  Future<void> _applyDailyStudyDefault() async {
    try {
      final todayStudy = await _studyRepository.fetchTodayStudy();
      final parsed = _parseReference(todayStudy.passage);
      if (parsed == null) {
        return;
      }
      _selectedBookId = parsed.$1;
      _selectedChapter = parsed.$2;
    } catch (_) {
      // Mantemos o fallback padrão da página quando não houver estudo disponível.
    }
  }

  Future<void> _syncLibraryFromRemote() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final remote = await _libraryRepository.fetch(userId);
      if (remote == null) {
        await _persistLibrary(syncRemote: true);
        return;
      }

      final preferredTranslation = _selectedTranslation != _defaultTranslation
          ? _selectedTranslation
          : remote.preferredTranslation;

      final merged = BibleLibrarySnapshot(
        preferredTranslation: preferredTranslation,
        favorites: _mergeEntries(_favorites, remote.favorites, limit: 24),
        history: _mergeEntries(_history, remote.history, limit: 24),
      );
      _applyLibrarySnapshot(merged);
    } catch (error) {
      debugPrint('Falha ao sincronizar biblioteca bíblica: $error');
    }
  }

  void _applyLibrarySnapshot(BibleLibrarySnapshot snapshot) {
    LocalCacheService.box.put(_translationKey, snapshot.preferredTranslation);
    LocalCacheService.box.put(
      _favoritesKey,
      snapshot.favorites.map((item) => item.toMap()).toList(growable: false),
    );
    LocalCacheService.box.put(
      _historyKey,
      snapshot.history.map((item) => item.toMap()).toList(growable: false),
    );

    if (!mounted) return;
    setState(() {
      _selectedTranslation = snapshot.preferredTranslation;
      _favorites = snapshot.favorites;
      _history = snapshot.history;
    });
  }

  Future<void> _persistLibrary({required bool syncRemote}) async {
    final snapshot = BibleLibrarySnapshot(
      preferredTranslation: _selectedTranslation,
      favorites: _favorites,
      history: _history,
    );
    _applyLibrarySnapshot(snapshot);

    if (!syncRemote) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _syncing = true);
    try {
      await _libraryRepository.save(userId, snapshot);
    } catch (error) {
      debugPrint('Falha ao salvar biblioteca bíblica no Firebase: $error');
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _loadCurrentSelection({bool addToHistory = true}) async {
    final queryReference = '${_selectedBook.queryName} $_selectedChapter';

    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      final passage = await _bibleApiService.fetchPassage(
        queryReference,
        translation: _selectedTranslation,
      );
      if (!mounted) return;

      final nextHistory = addToHistory
          ? _mergeEntries([_currentEntry()], _history, limit: 24)
          : _history;

      LocalCacheService.box.put(_currentBookIdKey, _selectedBookId);
      LocalCacheService.box.put(_currentChapterKey, _selectedChapter);

      setState(() {
        _passage = passage;
        _history = nextHistory;
      });

      await _persistLibrary(syncRemote: addToHistory);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorText = 'Falha ao carregar passagem: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  BibleLibraryEntry _currentEntry() {
    return BibleLibraryEntry(
      reference: '${_selectedBook.queryName} $_selectedChapter',
      displayReference: '${_selectedBook.displayName} $_selectedChapter',
      bookId: _selectedBookId,
      chapter: _selectedChapter,
      translation: _selectedTranslation,
      updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _selectTranslation(String? translation) async {
    if (translation == null || translation == _selectedTranslation) return;
    setState(() => _selectedTranslation = translation);
    await _persistLibrary(syncRemote: true);
    await _loadCurrentSelection(addToHistory: false);
  }

  Future<void> _toggleFavorite() async {
    final passage = _passage;
    if (passage == null) return;

    final entry = _currentEntry();
    final alreadyFavorite = _containsEntry(_favorites, entry);
    final nextFavorites = alreadyFavorite
        ? _favorites
              .where((item) => item.cacheKey != entry.cacheKey)
              .toList(growable: false)
        : _mergeEntries([entry], _favorites, limit: 24);

    setState(() => _favorites = nextFavorites);
    await _persistLibrary(syncRemote: true);
  }

  Future<void> _moveChapter(int direction) async {
    final currentBookIndex = bibleBookIndexById(_selectedBookId);
    if (currentBookIndex < 0) return;

    final currentBook = bibleBooks[currentBookIndex];
    var nextBookIndex = currentBookIndex;
    var nextChapter = _selectedChapter + direction;

    if (nextChapter < 1) {
      if (currentBookIndex == 0) return;
      nextBookIndex = currentBookIndex - 1;
      nextChapter = bibleBooks[nextBookIndex].chapters;
    } else if (nextChapter > currentBook.chapters) {
      if (currentBookIndex == bibleBooks.length - 1) return;
      nextBookIndex = currentBookIndex + 1;
      nextChapter = 1;
    }

    setState(() {
      _selectedBookId = bibleBooks[nextBookIndex].id;
      _selectedChapter = nextChapter;
    });
    await _loadCurrentSelection();
  }

  Future<void> _pickBook() async {
    final selected = await showModalBottomSheet<BibleBookDefinition>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Escolha o livro',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: bibleBooks.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final book = bibleBooks[index];
                    final selected = book.id == _selectedBookId;
                    return ListTile(
                      title: Text(book.displayName),
                      subtitle: Text('${book.chapters} capítulos'),
                      trailing: selected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.secondary,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(book),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null || selected.id == _selectedBookId) return;

    setState(() {
      _selectedBookId = selected.id;
      _selectedChapter = 1;
    });
    await _loadCurrentSelection();
  }

  Future<void> _pickChapter() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Capítulos de ${_selectedBook.displayName}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.08,
                  ),
                  itemCount: _selectedBook.chapters,
                  itemBuilder: (context, index) {
                    final chapter = index + 1;
                    final selected = chapter == _selectedChapter;
                    return InkWell(
                      onTap: () => Navigator.of(context).pop(chapter),
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surfaceTint,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppColors.secondary
                                : AppColors.border,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$chapter',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null || selected == _selectedChapter) return;
    setState(() => _selectedChapter = selected);
    await _loadCurrentSelection();
  }

  Future<void> _loadEntry(BibleLibraryEntry entry) async {
    if (entry.bookId != null && entry.bookId!.isNotEmpty) {
      _selectedBookId = entry.bookId!;
    }
    if ((entry.chapter ?? 0) > 0) {
      _selectedChapter = entry.chapter!;
    }
    _selectedTranslation = entry.translation;
    await _loadCurrentSelection(addToHistory: false);
  }

  Future<void> _openReadingMode() async {
    final passage = _passage;
    if (passage == null) return;

    final isFavorite = _containsEntry(_favorites, _currentEntry());
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _BibleReaderModePage(
          title: '${_selectedBook.displayName} $_selectedChapter',
          passage: passage,
          isFavorite: isFavorite,
          onFavoriteToggle: _toggleFavorite,
          onExplainVerse: _explainVerse,
        ),
      ),
    );
  }

  Future<void> _explainVerse(BibleVerse verse) async {
    final passage = _passage;
    if (passage == null || _explaining) return;

    setState(() => _explaining = true);
    try {
      _showExplainLoadingSheet(verse);
      final explanation = await _aiService.explainScripture(
        reference: '${_selectedBook.displayName} $_selectedChapter',
        selectedText: verse.text,
        passageText: passage.text,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

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
                  '${_selectedBook.displayName} ${verse.chapter}:${verse.verse}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 8),
                Text(
                  verse.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: MarkdownBody(
                      data: explanation,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.7,
                        ),
                        h1: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                        h2: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                        strong: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
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
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao explicar versículo: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _explaining = false);
      }
    }
  }

  void _showExplainLoadingSheet(BibleVerse verse) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: const BorderSide(color: AppColors.secondary),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preparando explicação',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Analisando ${verse.chapter}:${verse.verse} para te responder com mais clareza.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentEntry = _currentEntry();
    final isFavorite = _containsEntry(_favorites, currentEntry);

    return PvScaffold(
      title: 'Bíblia',
      showBackButton: false,
      bottomNavigationBar: const MainBottomNavBar(current: MainSection.bible),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.secondary),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Leitor contínuo por livro e capítulo',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                    if (_syncing)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Escolha o livro, selecione o capítulo e avance continuamente pela leitura bíblica sem depender de busca manual.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeroSelectorButton(
                        label: 'Livro',
                        value: _selectedBook.displayName,
                        icon: Icons.menu_book_rounded,
                        onTap: _pickBook,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroSelectorButton(
                        label: 'Capítulo',
                        value: '$_selectedChapter',
                        icon: Icons.format_list_numbered_rounded,
                        onTap: _pickChapter,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _BibleShortcutChip(
                      icon: Icons.favorite_outline_rounded,
                      label: '${_favorites.length} favoritos',
                    ),
                    _BibleShortcutChip(
                      icon: Icons.history_rounded,
                      label: '${_history.length} recentes',
                    ),
                    _BibleShortcutChip(
                      icon: Icons.translate_rounded,
                      label: _translationLabel(_selectedTranslation),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Controles de leitura',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _TranslationSelector(
                        value: _selectedTranslation,
                        options: _translations,
                        onChanged: _selectTranslation,
                      ),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : () => _moveChapter(-1),
                        icon: const Icon(Icons.chevron_left_rounded),
                        label: const Text('Anterior'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : () => _moveChapter(1),
                        icon: const Icon(Icons.chevron_right_rounded),
                        label: const Text('Próximo'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _passage != null ? _openReadingMode : null,
                        icon: const Icon(Icons.fullscreen_rounded),
                        label: const Text('Tela cheia'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_favorites.isNotEmpty) ...[
            _ReferenceStrip(
              title: 'Favoritos',
              items: _favorites,
              onTap: _loadEntry,
            ),
            const SizedBox(height: 12),
          ],
          if (_history.isNotEmpty) ...[
            _ReferenceStrip(
              title: 'Histórico',
              items: _history,
              onTap: _loadEntry,
            ),
            const SizedBox(height: 12),
          ],
          if (_loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_errorText != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_errorText!),
              ),
            )
          else if (_passage != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_selectedBook.displayName} $_selectedChapter',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tradução: ${_translationLabel(_selectedTranslation)}',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(color: AppColors.secondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite
                                ? const Color(0xFFB74C43)
                                : AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Toque em qualquer versículo para receber uma explicação por IA.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._passage!.verses.map(
                      (verse) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _explainVerse(verse),
                          child: Ink(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceTint,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${verse.verse}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(color: AppColors.secondary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    verse.text,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(height: 1.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _translationLabel(String code) {
    for (final option in _translations) {
      if (option.code == code) return option.label;
    }
    return code.toUpperCase();
  }

  bool _containsEntry(
    List<BibleLibraryEntry> entries,
    BibleLibraryEntry entry,
  ) {
    return entries.any((item) => item.cacheKey == entry.cacheKey);
  }

  List<BibleLibraryEntry> _normalizeEntries(
    Object? raw, {
    required String fallbackTranslation,
  }) {
    if (raw is! List) return const <BibleLibraryEntry>[];

    final now = DateTime.now().millisecondsSinceEpoch;
    final entries = <BibleLibraryEntry>[];
    for (var index = 0; index < raw.length; index++) {
      final entry = BibleLibraryEntry.fromDynamic(
        raw[index],
        fallbackTranslation: fallbackTranslation,
        fallbackUpdatedAtMillis: now - index,
      );
      if (entry != null) entries.add(entry);
    }
    entries.sort((a, b) => b.updatedAtMillis.compareTo(a.updatedAtMillis));
    return entries;
  }

  List<BibleLibraryEntry> _mergeEntries(
    List<BibleLibraryEntry> primary,
    List<BibleLibraryEntry> secondary, {
    required int limit,
  }) {
    final merged = <String, BibleLibraryEntry>{};
    for (final entry in [...primary, ...secondary]) {
      final current = merged[entry.cacheKey];
      if (current == null || entry.updatedAtMillis > current.updatedAtMillis) {
        merged[entry.cacheKey] = entry;
      }
    }
    final items = merged.values.toList(growable: false)
      ..sort((a, b) => b.updatedAtMillis.compareTo(a.updatedAtMillis));
    return items.take(limit).toList(growable: false);
  }

  (String, int)? _parseReference(String reference) {
    final match = RegExp(r'^(.+?)\s+(\d+)(?::.*)?$').firstMatch(reference.trim());
    if (match == null) {
      return null;
    }

    final bookName = _normalizeBookName(match.group(1) ?? '');
    final chapter = int.tryParse(match.group(2) ?? '');
    if (chapter == null || chapter <= 0) {
      return null;
    }

    for (final book in bibleBooks) {
      final display = _normalizeBookName(book.displayName);
      final query = _normalizeBookName(book.queryName);
      if (bookName == display || bookName == query) {
        return (book.id, chapter.clamp(1, book.chapters));
      }
    }

    return null;
  }

  String _normalizeBookName(String input) {
    const accents = <String, String>{
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'ê': 'e',
      'í': 'i',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ç': 'c',
    };

    var normalized = input.trim().toLowerCase();
    accents.forEach((accent, plain) {
      normalized = normalized.replaceAll(accent, plain);
    });
    return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}

class _HeroSelectorButton extends StatelessWidget {
  const _HeroSelectorButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.expand_more_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

class _TranslationSelector extends StatelessWidget {
  const _TranslationSelector({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<_BibleTranslationOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          borderRadius: BorderRadius.circular(18),
          onChanged: onChanged,
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.code,
                  child: Text('${option.label} · ${option.subtitle}'),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _ReferenceStrip extends StatelessWidget {
  const _ReferenceStrip({
    required this.title,
    required this.items,
    required this.onTap,
  });

  final String title;
  final List<BibleLibraryEntry> items;
  final ValueChanged<BibleLibraryEntry> onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: Icon(
                            title == 'Favoritos'
                                ? Icons.favorite_outline_rounded
                                : Icons.history_rounded,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                          label: Text(
                            '${item.resolvedLabel} · ${item.translation.toUpperCase()}',
                          ),
                          onPressed: () => onTap(item),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BibleShortcutChip extends StatelessWidget {
  const _BibleShortcutChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            ).textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _BibleTranslationOption {
  const _BibleTranslationOption({
    required this.code,
    required this.label,
    required this.subtitle,
  });

  final String code;
  final String label;
  final String subtitle;
}

class _BibleReaderModePage extends StatelessWidget {
  const _BibleReaderModePage({
    required this.title,
    required this.passage,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onExplainVerse,
  });

  final String title;
  final BiblePassage passage;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final Future<void> Function(BibleVerse verse) onExplainVerse;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: onFavoriteToggle,
            icon: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Text(
              'Modo leitura',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.accent,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Leitura limpa para concentração. Toque em um versículo para abrir a explicação gerada por IA.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.84),
              ),
            ),
            const SizedBox(height: 20),
            ...passage.verses.map(
              (verse) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onExplainVerse(verse),
                  child: Ink(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '${verse.verse}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: AppColors.accent),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            verse.text,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  height: 1.9,
                                  fontSize: 18,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
