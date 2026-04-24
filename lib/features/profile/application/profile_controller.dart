import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/saved_items_repository.dart';
import '../../../models/saved_item.dart';

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

final savedItemsRepositoryProvider = Provider<SavedItemsRepository>((ref) {
  return SavedItemsRepository();
});

final savedItemsProvider = StreamProvider<List<SavedItem>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const <SavedItem>[]);
  }
  return ref.watch(savedItemsRepositoryProvider).watchItems(user.id);
});
