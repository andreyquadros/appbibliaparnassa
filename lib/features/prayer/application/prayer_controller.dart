import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/gamification.dart';
import '../../../models/prayer_entry.dart';
import '../../auth/application/auth_controller.dart';
import '../../dashboard/application/progress_controller.dart';
import '../data/prayer_repository.dart';

class PrayerActions {
  PrayerActions(this.ref, this._repository);

  final Ref ref;
  final PrayerRepository _repository;

  Future<void> addPrayer({
    required String title,
    required String content,
    required String verse,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await _repository.add(
      userId: user.id,
      title: title,
      content: content,
      verse: verse,
    );

    final progress = ref.read(progressControllerProvider);
    if (!progress.didPrayToday()) {
      progress.grantAction(GamificationAction.registerPrayer);
    }
    progress.markPrayerDone();
  }

  Future<void> markPrayerToday() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await _repository.markToday(userId: user.id);
    final progress = ref.read(progressControllerProvider);
    if (!progress.didPrayToday()) {
      progress.grantAction(GamificationAction.registerPrayer);
    }
    progress.markPrayerDone();
  }

  Future<void> markAnswered(String prayerId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await _repository.markAnswered(userId: user.id, prayerId: prayerId);
    ref
        .read(progressControllerProvider)
        .grantAction(GamificationAction.answeredPrayer);
  }
}

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  return PrayerRepository();
});

final prayerActionsProvider = Provider<PrayerActions>((ref) {
  return PrayerActions(ref, ref.watch(prayerRepositoryProvider));
});

final prayerEntriesProvider = StreamProvider<List<PrayerEntry>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const <PrayerEntry>[]);
  }
  return ref.watch(prayerRepositoryProvider).watchEntries(user.id);
});
