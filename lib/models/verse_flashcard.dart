enum FlashcardReviewGrade { again, hard, good, easy }

class VerseFlashcard {
  const VerseFlashcard({
    required this.id,
    required this.reference,
    required this.verseText,
    this.sourceStudyId,
    required this.createdAt,
    required this.dueAt,
    this.lastReviewedAt,
    this.repetitions = 0,
    this.intervalDays = 0,
    this.easeFactor = 2.5,
    this.reviewCount = 0,
  });

  final String id;
  final String reference;
  final String verseText;
  final String? sourceStudyId;
  final DateTime createdAt;
  final DateTime dueAt;
  final DateTime? lastReviewedAt;
  final int repetitions;
  final int intervalDays;
  final double easeFactor;
  final int reviewCount;

  bool get isDue => !dueAt.isAfter(DateTime.now());

  VerseFlashcard copyWith({
    DateTime? dueAt,
    DateTime? lastReviewedAt,
    int? repetitions,
    int? intervalDays,
    double? easeFactor,
    int? reviewCount,
  }) {
    return VerseFlashcard(
      id: id,
      reference: reference,
      verseText: verseText,
      sourceStudyId: sourceStudyId,
      createdAt: createdAt,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      repetitions: repetitions ?? this.repetitions,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
