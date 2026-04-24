class SavedItem {
  const SavedItem({
    required this.id,
    required this.title,
    required this.reference,
    required this.excerpt,
    required this.category,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String reference;
  final String excerpt;
  final String category;
  final DateTime createdAt;
}
