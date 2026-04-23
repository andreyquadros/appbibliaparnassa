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
    _updateStreak(
      (streak) => streak.copyWith(
        studyStreak: streak.studyStreak + 1,
        lastStudyDate: DateTime.now(),
      ),
    );
  }

  void markPrayerDone() {
    _updateStreak(
      (streak) => streak.copyWith(
        prayerStreak: streak.prayerStreak + 1,
        lastPrayerDate: DateTime.now(),
      ),
    );
  }

  void markFastDone() {
    _updateStreak(
      (streak) => streak.copyWith(
        fastingStreak: streak.fastingStreak + 1,
        lastFastDate: DateTime.now(),
      ),
    );
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

  void _updateStreak(StreakState Function(StreakState streak) transform) {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }

    ref
        .read(authControllerProvider.notifier)
        .updateUser(user.copyWith(streak: transform(user.streak)));
  }
}

final progressControllerProvider = Provider<ProgressController>((ref) {
  return ProgressController(ref);
});
