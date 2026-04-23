import 'package:hive_flutter/hive_flutter.dart';

class LocalCacheService {
  const LocalCacheService._();

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>('palavra_viva_cache');
  }

  static Box<dynamic> get box => Hive.box<dynamic>('palavra_viva_cache');
}
