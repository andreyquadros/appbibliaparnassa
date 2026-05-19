class DailyVerseEntry {
  const DailyVerseEntry({required this.reference, required this.theme});

  final String reference;
  final String theme;
}

class DailyVersePlan {
  const DailyVersePlan._();

  static DailyVerseEntry forDateKey(String dateKey) {
    final parsed = DateTime.tryParse(dateKey);
    final date = parsed ?? DateTime.now();
    return forDate(date);
  }

  static DailyVerseEntry forDate(DateTime date) {
    final dayIndex = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(date.year)).inDays;
    return entries[dayIndex % entries.length];
  }

  static List<DailyVerseEntry> get entries =>
      List<DailyVerseEntry>.unmodifiable(
        _planSegments.expand(
          (segment) => List<DailyVerseEntry>.generate(
            segment.chapterCount,
            (index) => DailyVerseEntry(
              reference: '${segment.book} ${index + 1}:1',
              theme: segment.theme,
            ),
          ),
        ),
      );
}

class _DailyVersePlanSegment {
  const _DailyVersePlanSegment({
    required this.book,
    required this.chapterCount,
    required this.theme,
  });

  final String book;
  final int chapterCount;
  final String theme;
}

const List<_DailyVersePlanSegment> _planSegments = <_DailyVersePlanSegment>[
  _DailyVersePlanSegment(
    book: 'Salmos',
    chapterCount: 150,
    theme: 'Adoração, confiança e cuidado de Deus',
  ),
  _DailyVersePlanSegment(
    book: 'Provérbios',
    chapterCount: 31,
    theme: 'Sabedoria para a vida diária',
  ),
  _DailyVersePlanSegment(
    book: 'Isaías',
    chapterCount: 66,
    theme: 'Esperança, santidade e consolo',
  ),
  _DailyVersePlanSegment(
    book: 'Mateus',
    chapterCount: 28,
    theme: 'O Reino de Deus revelado em Cristo',
  ),
  _DailyVersePlanSegment(
    book: 'Marcos',
    chapterCount: 16,
    theme: 'Serviço, fé e discipulado',
  ),
  _DailyVersePlanSegment(
    book: 'Lucas',
    chapterCount: 24,
    theme: 'Graça, compaixão e salvação',
  ),
  _DailyVersePlanSegment(
    book: 'João',
    chapterCount: 21,
    theme: 'Vida em Cristo',
  ),
  _DailyVersePlanSegment(
    book: 'Romanos',
    chapterCount: 16,
    theme: 'Evangelho, graça e transformação',
  ),
  _DailyVersePlanSegment(
    book: 'Efésios',
    chapterCount: 6,
    theme: 'Identidade e maturidade em Cristo',
  ),
  _DailyVersePlanSegment(
    book: 'Filipenses',
    chapterCount: 4,
    theme: 'Alegria e perseverança no Senhor',
  ),
  _DailyVersePlanSegment(
    book: 'Colossenses',
    chapterCount: 4,
    theme: 'Cristo no centro de todas as coisas',
  ),
];
