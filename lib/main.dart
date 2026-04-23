import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/firebase_service.dart';
import 'core/services/local_cache_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalCacheService.init();
  await FirebaseService.init();

  runApp(const ProviderScope(child: PalavraVivaApp()));
}
