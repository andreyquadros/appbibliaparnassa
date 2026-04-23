class BibleVerse {
  const BibleVerse({
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  final String bookName;
  final int chapter;
  final int verse;
  final String text;
}

class BiblePassage {
  const BiblePassage({
    required this.reference,
    required this.text,
    required this.translationId,
    required this.verses,
  });

  final String reference;
  final String text;
  final String translationId;
  final List<BibleVerse> verses;
}
