class BibleBookDefinition {
  const BibleBookDefinition({
    required this.id,
    required this.displayName,
    required this.queryName,
    required this.chapters,
  });

  final String id;
  final String displayName;
  final String queryName;
  final int chapters;
}

const bibleBooks = <BibleBookDefinition>[
  BibleBookDefinition(
    id: 'genesis',
    displayName: 'Gênesis',
    queryName: 'Genesis',
    chapters: 50,
  ),
  BibleBookDefinition(
    id: 'exodo',
    displayName: 'Êxodo',
    queryName: 'Exodus',
    chapters: 40,
  ),
  BibleBookDefinition(
    id: 'levitico',
    displayName: 'Levítico',
    queryName: 'Leviticus',
    chapters: 27,
  ),
  BibleBookDefinition(
    id: 'numeros',
    displayName: 'Números',
    queryName: 'Numbers',
    chapters: 36,
  ),
  BibleBookDefinition(
    id: 'deuteronomio',
    displayName: 'Deuteronômio',
    queryName: 'Deuteronomy',
    chapters: 34,
  ),
  BibleBookDefinition(
    id: 'josue',
    displayName: 'Josué',
    queryName: 'Joshua',
    chapters: 24,
  ),
  BibleBookDefinition(
    id: 'juizes',
    displayName: 'Juízes',
    queryName: 'Judges',
    chapters: 21,
  ),
  BibleBookDefinition(
    id: 'rute',
    displayName: 'Rute',
    queryName: 'Ruth',
    chapters: 4,
  ),
  BibleBookDefinition(
    id: '1samuel',
    displayName: '1 Samuel',
    queryName: '1 Samuel',
    chapters: 31,
  ),
  BibleBookDefinition(
    id: '2samuel',
    displayName: '2 Samuel',
    queryName: '2 Samuel',
    chapters: 24,
  ),
  BibleBookDefinition(
    id: '1reis',
    displayName: '1 Reis',
    queryName: '1 Kings',
    chapters: 22,
  ),
  BibleBookDefinition(
    id: '2reis',
    displayName: '2 Reis',
    queryName: '2 Kings',
    chapters: 25,
  ),
  BibleBookDefinition(
    id: '1cronicas',
    displayName: '1 Crônicas',
    queryName: '1 Chronicles',
    chapters: 29,
  ),
  BibleBookDefinition(
    id: '2cronicas',
    displayName: '2 Crônicas',
    queryName: '2 Chronicles',
    chapters: 36,
  ),
  BibleBookDefinition(
    id: 'esdras',
    displayName: 'Esdras',
    queryName: 'Ezra',
    chapters: 10,
  ),
  BibleBookDefinition(
    id: 'neemias',
    displayName: 'Neemias',
    queryName: 'Nehemiah',
    chapters: 13,
  ),
  BibleBookDefinition(
    id: 'ester',
    displayName: 'Ester',
    queryName: 'Esther',
    chapters: 10,
  ),
  BibleBookDefinition(
    id: 'jo',
    displayName: 'Jó',
    queryName: 'Job',
    chapters: 42,
  ),
  BibleBookDefinition(
    id: 'salmos',
    displayName: 'Salmos',
    queryName: 'Psalms',
    chapters: 150,
  ),
  BibleBookDefinition(
    id: 'proverbios',
    displayName: 'Provérbios',
    queryName: 'Proverbs',
    chapters: 31,
  ),
  BibleBookDefinition(
    id: 'eclesiastes',
    displayName: 'Eclesiastes',
    queryName: 'Ecclesiastes',
    chapters: 12,
  ),
  BibleBookDefinition(
    id: 'canticos',
    displayName: 'Cantares',
    queryName: 'Song of Solomon',
    chapters: 8,
  ),
  BibleBookDefinition(
    id: 'isaias',
    displayName: 'Isaías',
    queryName: 'Isaiah',
    chapters: 66,
  ),
  BibleBookDefinition(
    id: 'jeremias',
    displayName: 'Jeremias',
    queryName: 'Jeremiah',
    chapters: 52,
  ),
  BibleBookDefinition(
    id: 'lamentacoes',
    displayName: 'Lamentações',
    queryName: 'Lamentations',
    chapters: 5,
  ),
  BibleBookDefinition(
    id: 'ezequiel',
    displayName: 'Ezequiel',
    queryName: 'Ezekiel',
    chapters: 48,
  ),
  BibleBookDefinition(
    id: 'daniel',
    displayName: 'Daniel',
    queryName: 'Daniel',
    chapters: 12,
  ),
  BibleBookDefinition(
    id: 'oseias',
    displayName: 'Oséias',
    queryName: 'Hosea',
    chapters: 14,
  ),
  BibleBookDefinition(
    id: 'joel',
    displayName: 'Joel',
    queryName: 'Joel',
    chapters: 3,
  ),
  BibleBookDefinition(
    id: 'amos',
    displayName: 'Amós',
    queryName: 'Amos',
    chapters: 9,
  ),
  BibleBookDefinition(
    id: 'obadias',
    displayName: 'Obadias',
    queryName: 'Obadiah',
    chapters: 1,
  ),
  BibleBookDefinition(
    id: 'jonas',
    displayName: 'Jonas',
    queryName: 'Jonah',
    chapters: 4,
  ),
  BibleBookDefinition(
    id: 'miqueias',
    displayName: 'Miquéias',
    queryName: 'Micah',
    chapters: 7,
  ),
  BibleBookDefinition(
    id: 'naum',
    displayName: 'Naum',
    queryName: 'Nahum',
    chapters: 3,
  ),
  BibleBookDefinition(
    id: 'habacuque',
    displayName: 'Habacuque',
    queryName: 'Habakkuk',
    chapters: 3,
  ),
  BibleBookDefinition(
    id: 'sofonias',
    displayName: 'Sofonias',
    queryName: 'Zephaniah',
    chapters: 3,
  ),
  BibleBookDefinition(
    id: 'ageu',
    displayName: 'Ageu',
    queryName: 'Haggai',
    chapters: 2,
  ),
  BibleBookDefinition(
    id: 'zacarias',
    displayName: 'Zacarias',
    queryName: 'Zechariah',
    chapters: 14,
  ),
  BibleBookDefinition(
    id: 'malaquias',
    displayName: 'Malaquias',
    queryName: 'Malachi',
    chapters: 4,
  ),
  BibleBookDefinition(
    id: 'mateus',
    displayName: 'Mateus',
    queryName: 'Matthew',
    chapters: 28,
  ),
  BibleBookDefinition(
    id: 'marcos',
    displayName: 'Marcos',
    queryName: 'Mark',
    chapters: 16,
  ),
  BibleBookDefinition(
    id: 'lucas',
    displayName: 'Lucas',
    queryName: 'Luke',
    chapters: 24,
  ),
  BibleBookDefinition(
    id: 'joao',
    displayName: 'João',
    queryName: 'John',
    chapters: 21,
  ),
  BibleBookDefinition(
    id: 'atos',
    displayName: 'Atos',
    queryName: 'Acts',
    chapters: 28,
  ),
  BibleBookDefinition(
    id: 'romanos',
    displayName: 'Romanos',
    queryName: 'Romans',
    chapters: 16,
  ),
  BibleBookDefinition(
    id: '1corintios',
    displayName: '1 Coríntios',
    queryName: '1 Corinthians',
    chapters: 16,
  ),
  BibleBookDefinition(
    id: '2corintios',
    displayName: '2 Coríntios',
    queryName: '2 Corinthians',
    chapters: 13,
  ),
  BibleBookDefinition(
    id: 'galatas',
    displayName: 'Gálatas',
    queryName: 'Galatians',
    chapters: 6,
  ),
  BibleBookDefinition(
    id: 'efesios',
    displayName: 'Efésios',
    queryName: 'Ephesians',
    chapters: 6,
  ),
  BibleBookDefinition(
    id: 'filipenses',
    displayName: 'Filipenses',
    queryName: 'Philippians',
    chapters: 4,
  ),
  BibleBookDefinition(
    id: 'colossenses',
    displayName: 'Colossenses',
    queryName: 'Colossians',
    chapters: 4,
  ),
  BibleBookDefinition(
    id: '1tessalonicenses',
    displayName: '1 Tessalonicenses',
    queryName: '1 Thessalonians',
    chapters: 5,
  ),
  BibleBookDefinition(
    id: '2tessalonicenses',
    displayName: '2 Tessalonicenses',
    queryName: '2 Thessalonians',
    chapters: 3,
  ),
  BibleBookDefinition(
    id: '1timoteo',
    displayName: '1 Timóteo',
    queryName: '1 Timothy',
    chapters: 6,
  ),
  BibleBookDefinition(
    id: '2timoteo',
    displayName: '2 Timóteo',
    queryName: '2 Timothy',
    chapters: 4,
  ),
  BibleBookDefinition(
    id: 'tito',
    displayName: 'Tito',
    queryName: 'Titus',
    chapters: 3,
  ),
  BibleBookDefinition(
    id: 'filemom',
    displayName: 'Filemom',
    queryName: 'Philemon',
    chapters: 1,
  ),
  BibleBookDefinition(
    id: 'hebreus',
    displayName: 'Hebreus',
    queryName: 'Hebrews',
    chapters: 13,
  ),
  BibleBookDefinition(
    id: 'tiago',
    displayName: 'Tiago',
    queryName: 'James',
    chapters: 5,
  ),
  BibleBookDefinition(
    id: '1pedro',
    displayName: '1 Pedro',
    queryName: '1 Peter',
    chapters: 5,
  ),
  BibleBookDefinition(
    id: '2pedro',
    displayName: '2 Pedro',
    queryName: '2 Peter',
    chapters: 3,
  ),
  BibleBookDefinition(
    id: '1joao',
    displayName: '1 João',
    queryName: '1 John',
    chapters: 5,
  ),
  BibleBookDefinition(
    id: '2joao',
    displayName: '2 João',
    queryName: '2 John',
    chapters: 1,
  ),
  BibleBookDefinition(
    id: '3joao',
    displayName: '3 João',
    queryName: '3 John',
    chapters: 1,
  ),
  BibleBookDefinition(
    id: 'judas',
    displayName: 'Judas',
    queryName: 'Jude',
    chapters: 1,
  ),
  BibleBookDefinition(
    id: 'apocalipse',
    displayName: 'Apocalipse',
    queryName: 'Revelation',
    chapters: 22,
  ),
];

BibleBookDefinition bibleBookById(String id) {
  return bibleBooks.firstWhere(
    (book) => book.id == id,
    orElse: () => bibleBooks.first,
  );
}

int bibleBookIndexById(String id) {
  return bibleBooks.indexWhere((book) => book.id == id);
}
