import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/gamification.dart';
import '../../../models/streak_state.dart';
import '../../auth/application/auth_controller.dart';

class ProgressController {
  ProgressController(this.ref);

  final Ref ref;

  void grantAction(GamificationAction action) {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }

    final reward = GamificationTable.grants[action]!;
    final updatedXp = user.xp + reward.xp;
    final levelInfo = GamificationTable.levelForXp(updatedXp);

    ref
        .read(authControllerProvider.notifier)
        .updateUser(
          user.copyWith(
            xp: updatedXp,
            manadas: user.manadas + reward.manadas,
            level: levelInfo.level,
            title: levelInfo.title,
          ),
        );
  }

  void markStudyDone() {
    _updateStreak((streak) {
      final next = _nextDailyCount(
        current: streak.studyStreak,
        lastDate: streak.lastStudyDate,
      );
      return streak.copyWith(studyStreak: next, lastStudyDate: DateTime.now());
    });
  }

  bool didStudyToday() {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return false;
    }
    return _isSameDay(user.streak.lastStudyDate, DateTime.now());
  }

  void markPrayerDone() {
    _updateStreak((streak) {
      final next = _nextDailyCount(
        current: streak.prayerStreak,
        lastDate: streak.lastPrayerDate,
      );
      return streak.copyWith(
        prayerStreak: next,
        lastPrayerDate: DateTime.now(),
      );
    });
  }

  bool didPrayToday() {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return false;
    }
    return _isSameDay(user.streak.lastPrayerDate, DateTime.now());
  }

  void markFastDone() {
    _updateStreak((streak) {
      final next = _nextDailyCount(
        current: streak.fastingStreak,
        lastDate: streak.lastFastDate,
      );
      return streak.copyWith(
        fastingStreak: next,
        lastFastDate: DateTime.now(),
      );
    });
  }

  bool didFastToday() {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return false;
    }
    return _isSameDay(user.streak.lastFastDate, DateTime.now());
  }

  int _nextDailyCount({
    required int current,
    required DateTime? lastDate,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    if (_isSameDay(lastDate, today)) {
      return current;
    }

    final yesterday = DateTime(today.year, today.month, today.day - 1);
    if (_isSameDay(lastDate, yesterday)) {
      return current + 1;
    }

    return 1;
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }

    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _updateStreak(StreakState Function(StreakState streak) transform) {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }

    ref
        .read(authControllerProvider.notifier)
        .updateUser(user.copyWith(streak: transform(user.streak)));
  }

  void spendManadas(int cost) {
    final user = ref.read(currentUserProvider);
    if (user == null || user.manadas < cost) {
      return;
    }

    ref
        .read(authControllerProvider.notifier)
        .updateUser(user.copyWith(manadas: user.manadas - cost));
  }
}

final progressControllerProvider = Provider<ProgressController>((ref) {
  return ProgressController(ref);
});
