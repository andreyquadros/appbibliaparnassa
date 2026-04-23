enum FastType { parcial, total, daniel }

class FastEntry {
  const FastEntry({
    required this.id,
    required this.type,
    required this.durationHours,
    required this.purpose,
    required this.verse,
    required this.startedAt,
    this.completedAt,
    this.testimony,
  });

  final String id;
  final FastType type;
  final int durationHours;
  final String purpose;
  final String verse;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? testimony;

  bool get isCompleted => completedAt != null;

  FastEntry complete({required String testimony, DateTime? completedAt}) {
    return FastEntry(
      id: id,
      type: type,
      durationHours: durationHours,
      purpose: purpose,
      verse: verse,
      startedAt: startedAt,
      completedAt: completedAt ?? DateTime.now(),
      testimony: testimony,
    );
  }
}
