import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationsService {
  NotificationsService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  Future<void> init() async {
    await _messaging.requestPermission();

    if (kDebugMode) {
      final token = await _messaging.getToken();
      debugPrint('FCM token: $token');
    }
  }
}
