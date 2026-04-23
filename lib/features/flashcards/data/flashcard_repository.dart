import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/verse_flashcard.dart';

class FlashcardRepository {
  FlashcardRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore.collection('users').doc(userId).collection('flashcards');
  }

  Stream<List<VerseFlashcard>> watchDueCards(String userId) {
    final now = Timestamp.fromDate(DateTime.now());
    return _collection(userId)
        .where('dueAt', isLessThanOrEqualTo: now)
        .orderBy('dueAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => _fromDoc(doc))
              .toList(growable: false);
        });
  }

  Stream<List<VerseFlashcard>> watchAllCards(String userId) {
    return _collection(userId).orderBy('dueAt').limit(100).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) => _fromDoc(doc)).toList(growable: false);
    });
  }

  Future<bool> addCard({
    required String userId,
    required String reference,
    required String verseText,
    String? sourceStudyId,
  }) async {
    final ref = _collection(userId).doc(_toDocId(reference));
    final snapshot = await ref.get();
    if (snapshot.exists) {
      return false;
    }

    final now = DateTime.now();
    await ref.set(<String, dynamic>{
      'reference': reference.trim(),
      'verseText': verseText.trim(),
      'sourceStudyId': sourceStudyId,
      'createdAt': FieldValue.serverTimestamp(),
      'dueAt': Timestamp.fromDate(now),
      'lastReviewedAt': null,
      'repetitions': 0,
      'intervalDays': 0,
      'easeFactor': 2.5,
      'reviewCount': 0,
    });
    return true;
  }

  Future<void> review({
    required String userId,
    required VerseFlashcard card,
    required FlashcardReviewGrade grade,
  }) async {
    final result = _next(card, grade, DateTime.now());
    await _collection(userId).doc(card.id).set(<String, dynamic>{
      'dueAt': Timestamp.fromDate(result.nextDueAt),
      'lastReviewedAt': FieldValue.serverTimestamp(),
      'repetitions': result.repetitions,
      'intervalDays': result.intervalDays,
      'easeFactor': result.easeFactor,
      'reviewCount': card.reviewCount + 1,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  VerseFlashcard _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return VerseFlashcard(
      id: doc.id,
      reference: _string(data['reference'], 'Referência'),
      verseText: _string(data['verseText'], ''),
      sourceStudyId: _nullableString(data['sourceStudyId']),
      createdAt: _date(data['createdAt']) ?? DateTime.now(),
      dueAt: _date(data['dueAt']) ?? DateTime.now(),
      lastReviewedAt: _date(data['lastReviewedAt']),
      repetitions: _int(data['repetitions']),
      intervalDays: _int(data['intervalDays']),
      easeFactor: _double(data['easeFactor'], 2.5),
      reviewCount: _int(data['reviewCount']),
    );
  }

  String _toDocId(String reference) {
    return reference
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String _string(Object? value, String fallback) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? fallback : text;
  }

  String? _nullableString(Object? value) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? null : text;
  }

  int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  double _double(Object? value, double fallback) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return fallback;
  }
}

class _ReviewResult {
  const _ReviewResult({
    required this.nextDueAt,
    required this.repetitions,
    required this.intervalDays,
    required this.easeFactor,
  });

  final DateTime nextDueAt;
  final int repetitions;
  final int intervalDays;
  final double easeFactor;
}

_ReviewResult _next(
  VerseFlashcard card,
  FlashcardReviewGrade grade,
  DateTime now,
) {
  final quality = switch (grade) {
    FlashcardReviewGrade.again => 1,
    FlashcardReviewGrade.hard => 3,
    FlashcardReviewGrade.good => 4,
    FlashcardReviewGrade.easy => 5,
  };

  final newEase =
      (card.easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
          .clamp(1.3, 3.0);

  if (grade == FlashcardReviewGrade.again) {
    return _ReviewResult(
      nextDueAt: now.add(const Duration(minutes: 10)),
      repetitions: 0,
      intervalDays: 0,
      easeFactor: newEase,
    );
  }

  final repetitions = card.repetitions + 1;
  int interval;

  if (repetitions == 1) {
    interval = 1;
  } else if (repetitions == 2) {
    interval = 3;
  } else {
    final modifier = switch (grade) {
      FlashcardReviewGrade.hard => 0.85,
      FlashcardReviewGrade.good => 1.0,
      FlashcardReviewGrade.easy => 1.25,
      FlashcardReviewGrade.again => 1.0,
    };
    interval = (card.intervalDays * newEase * modifier).round();
    if (interval < 1) {
      interval = 1;
    }
  }

  return _ReviewResult(
    nextDueAt: now.add(Duration(days: interval)),
    repetitions: repetitions,
    intervalDays: interval,
    easeFactor: newEase,
  );
}
