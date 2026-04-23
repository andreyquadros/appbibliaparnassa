class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.author,
    required this.verse,
    required this.comment,
    this.amemCount = 0,
    this.prayedCount = 0,
    this.edifiedCount = 0,
    required this.createdAt,
  });

  final String id;
  final String author;
  final String verse;
  final String comment;
  final int amemCount;
  final int prayedCount;
  final int edifiedCount;
  final DateTime createdAt;
}
