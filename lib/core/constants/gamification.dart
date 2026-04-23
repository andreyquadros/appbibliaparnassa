import 'package:flutter/material.dart';

enum GamificationAction {
  completeDailyStudy,
  correctQuiz,
  registerPrayer,
  registerFast,
  streak7,
  streak30,
  memorizeVerse,
  shareStudy,
  dailyLogin,
  completeThemeTrack,
  answeredPrayer,
}

class RewardGrant {
  const RewardGrant({required this.xp, required this.manadas});

  final int xp;
  final int manadas;
}

class DiscipleLevel {
  const DiscipleLevel({
    required this.level,
    required this.title,
    required this.minXp,
    required this.maxXp,
  });

  final int level;
  final String title;
  final int minXp;
  final int maxXp;
}

class GamificationTable {
  const GamificationTable._();

  static const grants = <GamificationAction, RewardGrant>{
    GamificationAction.completeDailyStudy: RewardGrant(xp: 50, manadas: 10),
    GamificationAction.correctQuiz: RewardGrant(xp: 10, manadas: 2),
    GamificationAction.registerPrayer: RewardGrant(xp: 20, manadas: 5),
    GamificationAction.registerFast: RewardGrant(xp: 80, manadas: 20),
    GamificationAction.streak7: RewardGrant(xp: 100, manadas: 25),
    GamificationAction.streak30: RewardGrant(xp: 500, manadas: 100),
    GamificationAction.memorizeVerse: RewardGrant(xp: 30, manadas: 8),
    GamificationAction.shareStudy: RewardGrant(xp: 15, manadas: 3),
    GamificationAction.dailyLogin: RewardGrant(xp: 5, manadas: 1),
    GamificationAction.completeThemeTrack: RewardGrant(xp: 200, manadas: 50),
    GamificationAction.answeredPrayer: RewardGrant(xp: 40, manadas: 10),
  };

  static const levels = <DiscipleLevel>[
    DiscipleLevel(level: 1, title: 'Neófito', minXp: 0, maxXp: 500),
    DiscipleLevel(level: 2, title: 'Aprendiz', minXp: 501, maxXp: 1500),
    DiscipleLevel(level: 3, title: 'Discípulo', minXp: 1501, maxXp: 3500),
    DiscipleLevel(level: 4, title: 'Levita', minXp: 3501, maxXp: 7000),
    DiscipleLevel(level: 5, title: 'Escriba', minXp: 7001, maxXp: 14000),
    DiscipleLevel(level: 6, title: 'Profeta', minXp: 14001, maxXp: 28000),
    DiscipleLevel(level: 7, title: 'Apóstolo', minXp: 28001, maxXp: 56000),
    DiscipleLevel(level: 8, title: 'Ancião', minXp: 56001, maxXp: 100000),
    DiscipleLevel(
      level: 9,
      title: 'Guardião da Palavra',
      minXp: 100001,
      maxXp: 2147483647,
    ),
  ];

  static DiscipleLevel levelForXp(int xp) {
    return levels.firstWhere(
      (level) => xp >= level.minXp && xp <= level.maxXp,
      orElse: () => levels.last,
    );
  }
}

class PillarStatus {
  const PillarStatus({
    required this.studyDone,
    required this.prayerDone,
    required this.fastingDone,
  });

  final bool studyDone;
  final bool prayerDone;
  final bool fastingDone;

  int get completedCount =>
      [studyDone, prayerDone, fastingDone].where((item) => item).length;

  Color statusColor(bool value) => value ? Colors.green : Colors.orange;
}
