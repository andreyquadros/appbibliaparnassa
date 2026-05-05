import 'package:hive_flutter/hive_flutter.dart';

class LocalCacheService {
  const LocalCacheService._();

  static const _boxName = 'palavra_viva_cache';
  static const _onboardingCompletedKey = 'onboarding_completed';
  static const _notificationRemindersEnabledKey =
      'notification_reminders_enabled';
  static const _notificationReminderTimesKey = 'notification_reminder_times';
  static const defaultNotificationReminderTimes = <String>[
    '07:00',
    '12:00',
    '21:00',
  ];

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(_boxName);
  }

  static Box<dynamic> get box => Hive.box<dynamic>(_boxName);

  static bool get onboardingCompleted =>
      box.get(_onboardingCompletedKey, defaultValue: false) == true;

  static Future<void> setOnboardingCompleted([bool value = true]) async {
    await box.put(_onboardingCompletedKey, value);
  }

  static bool get notificationRemindersEnabled =>
      box.get(_notificationRemindersEnabledKey, defaultValue: true) == true;

  static Future<void> setNotificationRemindersEnabled(bool value) async {
    await box.put(_notificationRemindersEnabledKey, value);
  }

  static List<String> get notificationReminderTimes {
    final value = box.get(_notificationReminderTimesKey);
    if (value is List) {
      final times = value
          .whereType<String>()
          .where(_isValidTimeLabel)
          .toList(growable: false);
      if (times.isNotEmpty) return times;
    }
    return defaultNotificationReminderTimes;
  }

  static Future<void> setNotificationReminderTimes(List<String> times) async {
    final normalized = times
        .where(_isValidTimeLabel)
        .toSet()
        .toList(growable: false)
      ..sort();
    await box.put(
      _notificationReminderTimesKey,
      normalized.isEmpty ? defaultNotificationReminderTimes : normalized,
    );
  }

  static bool _isValidTimeLabel(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    return hour != null &&
        minute != null &&
        hour >= 0 &&
        hour <= 23 &&
        minute >= 0 &&
        minute <= 59;
  }
}
