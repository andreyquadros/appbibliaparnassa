import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/ranking_entry.dart';
import '../../auth/application/auth_controller.dart';
import '../data/ranking_repository.dart';
import '../domain/ranking_period.dart';

class RankingController extends StateNotifier<RankingPeriod> {
  RankingController() : super(RankingPeriod.weekly);

  void updatePeriod(RankingPeriod period) => state = period;
}

final rankingPeriodProvider =
    StateNotifierProvider<RankingController, RankingPeriod>((ref) {
      return RankingController();
    });

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return RankingRepository();
});

final rankingEntriesProvider = StreamProvider<List<RankingEntry>>((ref) {
  final period = ref.watch(rankingPeriodProvider);
  final currentUserId = ref.watch(currentUserProvider)?.id;
  return ref
      .watch(rankingRepositoryProvider)
      .watchEntries(period, currentUserId: currentUserId);
});
