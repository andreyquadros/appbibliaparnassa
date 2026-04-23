enum PrayerStatus { believing, answered }

class PrayerEntry {
  const PrayerEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.verse,
    this.status = PrayerStatus.believing,
    required this.createdAt,
    this.answeredAt,
  });

  final String id;
  final String title;
  final String content;
  final String verse;
  final PrayerStatus status;
  final DateTime createdAt;
  final DateTime? answeredAt;

  PrayerEntry copyWith({PrayerStatus? status, DateTime? answeredAt}) {
    return PrayerEntry(
      id: id,
      title: title,
      content: content,
      verse: verse,
      status: status ?? this.status,
      createdAt: createdAt,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }
}
