import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/gamification.dart';
import '../../../models/daily_study.dart';
import '../../dashboard/application/progress_controller.dart';
import '../data/study_repository.dart';

class StudyController extends StateNotifier<AsyncValue<DailyStudy>> {
  StudyController(this.ref, this._repository)
    : super(const AsyncValue.loading()) {
    refreshStudy();
    _scheduleNextDailyRefresh();
  }

  final Ref ref;
  final StudyRepository _repository;
  Timer? _dailyRefreshTimer;

  Future<void> refreshStudy({bool forceGenerate = false}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.fetchTodayStudy(forceGenerate: forceGenerate),
    );
  }

  Future<void> refreshIfNeeded() async {
    final currentStudy = state.asData?.value;
    if (currentStudy == null) return;
    if (currentStudy.dateId == _todayDateKey()) return;
    await refreshStudy();
  }

  String _todayDateKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  void _scheduleNextDailyRefresh() {
    _dailyRefreshTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(
      now.year,
      now.month,
      now.day + 1,
    ).add(const Duration(minutes: 1));
    _dailyRefreshTimer = Timer(nextMidnight.difference(now), () async {
      await refreshStudy();
      _scheduleNextDailyRefresh();
    });
  }

  void completeTodayStudy() {
    final progress = ref.read(progressControllerProvider);
    if (!progress.didStudyToday()) {
      progress.grantAction(GamificationAction.completeDailyStudy);
    }
    progress.markStudyDone();
  }

  @override
  void dispose() {
    _dailyRefreshTimer?.cancel();
    super.dispose();
  }
}

final studyControllerProvider =
    StateNotifierProvider<StudyController, AsyncValue<DailyStudy>>((ref) {
      return StudyController(ref, ref.watch(studyRepositoryProvider));
    });

final studyRepositoryProvider = Provider<StudyRepository>((ref) {
  return StudyRepository();
});
