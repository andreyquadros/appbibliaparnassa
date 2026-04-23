import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/reward_item.dart';
import '../../auth/application/auth_controller.dart';
import '../data/rewards_repository.dart';

enum RewardFilter { all, tier1, tier2, tier3, tier4 }

class RewardsController extends StateNotifier<RewardFilter> {
  RewardsController() : super(RewardFilter.all);

  void setFilter(RewardFilter filter) => state = filter;
}

class RewardsActions {
  RewardsActions(this.ref, this._repository);

  final Ref ref;
  final RewardsRepository _repository;

  Future<bool> unlock(RewardItem reward) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;
    return _repository.unlock(userId: user.id, reward: reward);
  }
}

final rewardsFilterProvider =
    StateNotifierProvider<RewardsController, RewardFilter>((ref) {
      return RewardsController();
    });

final rewardsRepositoryProvider = Provider<RewardsRepository>((ref) {
  return RewardsRepository();
});

final rewardsCatalogProvider = StreamProvider<List<RewardItem>>((ref) {
  return ref.watch(rewardsRepositoryProvider).watchCatalog();
});

final unlockedRewardIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(<String>{});
  }
  return ref.watch(rewardsRepositoryProvider).watchUnlockedIds(user.id);
});

final rewardsActionsProvider = Provider<RewardsActions>((ref) {
  return RewardsActions(ref, ref.watch(rewardsRepositoryProvider));
});

final filteredRewardsProvider = Provider<AsyncValue<List<RewardItem>>>((ref) {
  final catalogAsync = ref.watch(rewardsCatalogProvider);
  final unlockedAsync = ref.watch(unlockedRewardIdsProvider);
  final filter = ref.watch(rewardsFilterProvider);

  return switch ((catalogAsync, unlockedAsync)) {
    (AsyncData(value: final value), AsyncData(value: final unlockedIds)) =>
      AsyncValue.data(
        value
            .map(
              (item) => item.copyWith(unlocked: unlockedIds.contains(item.id)),
            )
            .where((item) => _matchesFilter(item, filter))
            .toList(growable: false),
      ),
    (AsyncError(error: final error, stackTrace: final stackTrace), _) =>
      AsyncValue.error(error, stackTrace),
    (_, AsyncError(error: final error, stackTrace: final stackTrace)) =>
      AsyncValue.error(error, stackTrace),
    _ => const AsyncValue.loading(),
  };
});

bool _matchesFilter(RewardItem item, RewardFilter filter) {
  switch (filter) {
    case RewardFilter.all:
      return true;
    case RewardFilter.tier1:
      return item.tier == 1;
    case RewardFilter.tier2:
      return item.tier == 2;
    case RewardFilter.tier3:
      return item.tier == 3;
    case RewardFilter.tier4:
      return item.tier == 4;
  }
}
