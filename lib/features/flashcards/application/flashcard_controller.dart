import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai_service.dart';
import '../../../core/services/bible_api_service.dart';
import '../../../core/constants/gamification.dart';
import '../../../models/daily_study.dart';
import '../../../models/verse_flashcard.dart';
import '../../auth/application/auth_controller.dart';
import '../../dashboard/application/progress_controller.dart';
import '../data/flashcard_repository.dart';

class FlashcardController {
  FlashcardController(this.ref, this._repository);

  final Ref ref;
  final FlashcardRepository _repository;
  final AiService _aiService = AiService();
  final BibleApiService _bibleApiService = BibleApiService();

  Future<bool> addFromStudy(DailyStudy study) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;

    final added = await _repository.addCard(
      userId: user.id,
      reference: study.passage,
      verseText: study.memoryVerse,
      sourceStudyId: study.dateId,
    );
    return added;
  }

  Future<void> review(VerseFlashcard card, FlashcardReviewGrade grade) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await _repository.review(userId: user.id, card: card, grade: grade);
    if (grade == FlashcardReviewGrade.good ||
        grade == FlashcardReviewGrade.easy) {
      ref
          .read(progressControllerProvider)
          .grantAction(GamificationAction.memorizeVerse);
    }
  }

  Future<int> generateSuggestions({
    required FlashcardSuggestionType type,
    String theme = '',
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return 0;

    switch (type) {
      case FlashcardSuggestionType.beautiful:
        return _addPreset(user.id, _beautifulSet);
      case FlashcardSuggestionType.short:
        return _addPreset(user.id, _shortSet);
      case FlashcardSuggestionType.essential:
        return _addPreset(user.id, _essentialSet);
      case FlashcardSuggestionType.byTheme:
        return _addByTheme(user.id, theme);
    }
  }

  Future<int> _addPreset(String userId, List<_SuggestedVerse> verses) async {
    var added = 0;
    for (final verse in verses) {
      final created = await _repository.addCard(
        userId: userId,
        reference: verse.reference,
        verseText: verse.text,
      );
      if (created) {
        added += 1;
      }
    }
    return added;
  }

  Future<int> _addByTheme(String userId, String theme) async {
    final query = theme.trim();
    if (query.isEmpty) {
      return 0;
    }

    final results = await _aiService.searchVerses(query);
    var added = 0;
    for (final item in results.take(7)) {
      final reference = (item['reference'] ?? '').trim();
      if (reference.isEmpty) {
        continue;
      }

      final resolvedText = await _resolveVerseText(
        reference: reference,
        fallback: (item['text'] ?? '').trim(),
      );

      final created = await _repository.addCard(
        userId: userId,
        reference: reference,
        verseText: resolvedText,
      );
      if (created) {
        added += 1;
      }
    }
    return added;
  }

  Future<String> _resolveVerseText({
    required String reference,
    required String fallback,
  }) async {
    try {
      final passage = await _bibleApiService.fetchPassage(reference);
      final text = passage.verses.isNotEmpty
          ? passage.verses.first.text.trim()
          : passage.text.trim();
      if (text.isNotEmpty) {
        return text;
      }
    } catch (_) {}
    return fallback.isNotEmpty ? fallback : reference;
  }
}

enum FlashcardSuggestionType { beautiful, short, essential, byTheme }

class _SuggestedVerse {
  const _SuggestedVerse({required this.reference, required this.text});

  final String reference;
  final String text;
}

const List<_SuggestedVerse> _beautifulSet = <_SuggestedVerse>[
  _SuggestedVerse(
    reference: 'Salmos 23:1',
    text: 'O Senhor é o meu pastor; nada me faltará.',
  ),
  _SuggestedVerse(
    reference: 'Salmos 119:105',
    text: 'Lâmpada para os meus pés é a tua palavra, e luz para o meu caminho.',
  ),
  _SuggestedVerse(
    reference: 'Romanos 8:28',
    text:
        'Sabemos que todas as coisas cooperam para o bem daqueles que amam a Deus.',
  ),
  _SuggestedVerse(
    reference: 'Isaías 41:10',
    text:
        'Não temas, porque eu sou contigo; não te assombres, porque eu sou teu Deus.',
  ),
];

const List<_SuggestedVerse> _shortSet = <_SuggestedVerse>[
  _SuggestedVerse(reference: 'João 11:35', text: 'Jesus chorou.'),
  _SuggestedVerse(
    reference: '1 Tessalonicenses 5:17',
    text: 'Orai sem cessar.',
  ),
  _SuggestedVerse(
    reference: 'Salmos 119:11',
    text: 'Escondi a tua palavra no meu coração.',
  ),
  _SuggestedVerse(
    reference: 'Gálatas 5:22',
    text: 'O fruto do Espírito é amor, alegria e paz.',
  ),
];

const List<_SuggestedVerse> _essentialSet = <_SuggestedVerse>[
  _SuggestedVerse(
    reference: 'João 3:16',
    text:
        'Porque Deus amou o mundo de tal maneira que deu o seu Filho unigênito.',
  ),
  _SuggestedVerse(
    reference: 'Efésios 2:8',
    text: 'Pela graça sois salvos, mediante a fé; e isto não vem de vós.',
  ),
  _SuggestedVerse(
    reference: 'Romanos 12:2',
    text:
        'Não vos conformeis com este século, mas transformai-vos pela renovação da mente.',
  ),
  _SuggestedVerse(
    reference: 'Provérbios 3:5',
    text:
        'Confia no Senhor de todo o teu coração e não te estribes no teu próprio entendimento.',
  ),
];

final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  return FlashcardRepository();
});

final flashcardControllerProvider = Provider<FlashcardController>((ref) {
  return FlashcardController(ref, ref.watch(flashcardRepositoryProvider));
});

final dueFlashcardsProvider = StreamProvider<List<VerseFlashcard>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const <VerseFlashcard>[]);
  }
  return ref.watch(flashcardRepositoryProvider).watchDueCards(user.id);
});

final allFlashcardsProvider = StreamProvider<List<VerseFlashcard>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const <VerseFlashcard>[]);
  }
  return ref.watch(flashcardRepositoryProvider).watchAllCards(user.id);
});
