import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/gamification.dart';
import '../../../models/fast_entry.dart';
import '../../auth/application/auth_controller.dart';
import '../../dashboard/application/progress_controller.dart';
import '../data/fasting_repository.dart';

class FastingActions {
  FastingActions(this.ref, this._repository);

  final Ref ref;
  final FastingRepository _repository;

  Future<void> startFast({
    required FastType type,
    required int durationHours,
    required String purpose,
    required String verse,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await _repository.start(
      userId: user.id,
      type: type,
      durationHours: durationHours,
      purpose: purpose,
      verse: verse,
    );
    final progress = ref.read(progressControllerProvider);
    if (!progress.didFastToday()) {
      progress.grantAction(GamificationAction.registerFast);
    }
    progress.markFastDone();
  }

  Future<void> completeFast({
    required String id,
    required String testimony,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await _repository.complete(
      userId: user.id,
      fastId: id,
      testimony: testimony,
    );
    ref
      ..read(
        progressControllerProvider,
      ).grantAction(GamificationAction.registerFast)
      ..read(progressControllerProvider).markFastDone();
  }
}

final fastingRepositoryProvider = Provider<FastingRepository>((ref) {
  return FastingRepository();
});

final fastingActionsProvider = Provider<FastingActions>((ref) {
  return FastingActions(ref, ref.watch(fastingRepositoryProvider));
});

final fastingEntriesProvider = StreamProvider<List<FastEntry>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const <FastEntry>[]);
  }
  return ref.watch(fastingRepositoryProvider).watchEntries(user.id);
});
