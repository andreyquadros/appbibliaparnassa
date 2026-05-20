import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'local_cache_service.dart';

class NotificationReminderTime {
  const NotificationReminderTime({required this.hour, required this.minute});

  final int hour;
  final int minute;

  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static NotificationReminderTime parse(String value) {
    final parts = value.split(':');
    return NotificationReminderTime(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}

class NotificationsService {
  NotificationsService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  static const int _dailyReminderIdBase = 1001;
  static bool _timeZoneReady = false;

  Future<void> init() async {
    await _initLocalNotifications();
    await _initTimeZone();
    await _requestPermissions();
    if (LocalCacheService.notificationRemindersEnabled) {
      await scheduleDailyStudyReminders();
    } else {
      await cancelDailyStudyReminders();
    }

    if (kDebugMode) {
      try {
        final token = await _messaging.getToken();
        debugPrint('FCM token: $token');
      } catch (error) {
        debugPrint('FCM token indisponível no ambiente local: $error');
      }
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);
  }

  Future<void> _requestPermissions() async {
    try {
      await _messaging.requestPermission();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Permissão FCM indisponível neste ambiente: $error');
      }
    }

    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();

    final ios = _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _initTimeZone() async {
    if (_timeZoneReady) return;
    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Mantem o timezone padrão caso o dispositivo não retorne um nome válido.
    }
    _timeZoneReady = true;
  }

  Future<void> scheduleDailyStudyReminders({
    List<NotificationReminderTime>? times,
  }) async {
    await _initTimeZone();
    const androidDetails = AndroidNotificationDetails(
      'daily_study_reminder',
      'Lembretes diários de estudo',
      channelDescription: 'Lembretes para abrir o app e ler a Palavra.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await cancelDailyStudyReminders();

    final reminderTimes =
        times ??
        LocalCacheService.notificationReminderTimes
            .map(NotificationReminderTime.parse)
            .toList(growable: false);

    for (var index = 0; index < reminderTimes.length; index++) {
      final time = reminderTimes[index];
      await _localNotifications.zonedSchedule(
        _dailyReminderIdBase + index,
        _titleFor(time),
        _bodyFor(time),
        _nextInstanceOf(time),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelDailyStudyReminders() async {
    for (var index = 0; index < 6; index++) {
      await _localNotifications.cancel(_dailyReminderIdBase + index);
    }
  }

  tz.TZDateTime _nextInstanceOf(NotificationReminderTime time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  String _titleFor(NotificationReminderTime time) {
    if (time.hour < 12) return 'Bom dia na Palavra';
    if (time.hour < 18) return 'Pausa para renovar a mente';
    return 'Termine o dia com Deus';
  }

  String _bodyFor(NotificationReminderTime time) {
    if (time.hour < 12) {
      return 'Separe alguns minutos para começar o dia com o estudo bíblico.';
    }
    if (time.hour < 18) {
      return 'Uma leitura breve agora pode firmar seu coração para o restante do dia.';
    }
    return 'Antes de descansar, volte à Palavra e encerre o dia em oração.';
  }
}
