import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';

final profileStatsProvider = Provider<Map<String, int>>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return const <String, int>{};
  }

  return <String, int>{
    'totalStudies': user.streak.studyStreak,
    'totalPrayers': user.streak.prayerStreak,
    'totalFasts': user.streak.fastingStreak,
    'xpTotal': user.xp,
  };
});
