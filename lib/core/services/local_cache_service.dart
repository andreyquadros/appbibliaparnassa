import 'package:hive_flutter/hive_flutter.dart';

class LocalCacheService {
  const LocalCacheService._();

  static const _boxName = 'palavra_viva_cache';
  static const _onboardingCompletedKey = 'onboarding_completed';

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
}
