class RankingEntry {
  const RankingEntry({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.level,
    required this.streak,
    required this.weekXp,
    required this.position,
    this.delta = 0,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final int level;
  final int streak;
  final int weekXp;
  final int position;
  final int delta;
}
