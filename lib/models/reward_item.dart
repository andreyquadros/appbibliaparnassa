class RewardItem {
  const RewardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.tier,
    required this.manadasCost,
    required this.category,
    required this.preview,
    this.unlocked = false,
  });

  final String id;
  final String title;
  final String description;
  final int tier;
  final int manadasCost;
  final String category;
  final String preview;
  final bool unlocked;

  RewardItem copyWith({bool? unlocked}) {
    return RewardItem(
      id: id,
      title: title,
      description: description,
      tier: tier,
      manadasCost: manadasCost,
      category: category,
      preview: preview,
      unlocked: unlocked ?? this.unlocked,
    );
  }
}
