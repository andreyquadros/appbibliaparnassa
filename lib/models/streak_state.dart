class StreakState {
  const StreakState({
    this.studyStreak = 0,
    this.prayerStreak = 0,
    this.fastingStreak = 0,
    this.lastStudyDate,
    this.lastPrayerDate,
    this.lastFastDate,
    this.availableFreeze = 1,
  });

  final int studyStreak;
  final int prayerStreak;
  final int fastingStreak;
  final DateTime? lastStudyDate;
  final DateTime? lastPrayerDate;
  final DateTime? lastFastDate;
  final int availableFreeze;

  StreakState copyWith({
    int? studyStreak,
    int? prayerStreak,
    int? fastingStreak,
    DateTime? lastStudyDate,
    DateTime? lastPrayerDate,
    DateTime? lastFastDate,
    int? availableFreeze,
  }) {
    return StreakState(
      studyStreak: studyStreak ?? this.studyStreak,
      prayerStreak: prayerStreak ?? this.prayerStreak,
      fastingStreak: fastingStreak ?? this.fastingStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      lastPrayerDate: lastPrayerDate ?? this.lastPrayerDate,
      lastFastDate: lastFastDate ?? this.lastFastDate,
      availableFreeze: availableFreeze ?? this.availableFreeze,
    );
  }
}
