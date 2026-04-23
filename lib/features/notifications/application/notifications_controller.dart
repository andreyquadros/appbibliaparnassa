import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationPreference {
  const NotificationPreference({
    required this.dailyStudy,
    required this.streakRisk,
    required this.weeklyLeague,
    required this.motivationalVerses,
  });

  final bool dailyStudy;
  final bool streakRisk;
  final bool weeklyLeague;
  final bool motivationalVerses;

  NotificationPreference copyWith({
    bool? dailyStudy,
    bool? streakRisk,
    bool? weeklyLeague,
    bool? motivationalVerses,
  }) {
    return NotificationPreference(
      dailyStudy: dailyStudy ?? this.dailyStudy,
      streakRisk: streakRisk ?? this.streakRisk,
      weeklyLeague: weeklyLeague ?? this.weeklyLeague,
      motivationalVerses: motivationalVerses ?? this.motivationalVerses,
    );
  }
}

class NotificationsController extends StateNotifier<NotificationPreference> {
  NotificationsController()
    : super(
        const NotificationPreference(
          dailyStudy: true,
          streakRisk: true,
          weeklyLeague: true,
          motivationalVerses: true,
        ),
      );

  void update(NotificationPreference next) => state = next;
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationPreference>((
      ref,
    ) {
      return NotificationsController();
    });
