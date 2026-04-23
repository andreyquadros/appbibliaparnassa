import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../constants/firebase_constants.dart';
import '../../firebase_options.dart';

class FirebaseService {
  const FirebaseService._();

  static FirebaseAnalytics? _analytics;
  static bool _emulatorsConfigured = false;

  static FirebaseAnalytics? get analytics => _analytics;
  static FirebaseFunctions get functions =>
      FirebaseFunctions.instanceFor(region: FirebaseConstants.functionsRegion);

  static Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
      await _configureLocalEmulatorsIfNeeded();
      _analytics = FirebaseAnalytics.instance;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Firebase init fallback (modo local): $error');
        debugPrint(stackTrace.toString());
      }
    }
  }

  static Future<void> _configureLocalEmulatorsIfNeeded() async {
    if (!kDebugMode || _emulatorsConfigured) {
      return;
    }

    const useEmulators = bool.fromEnvironment(
      'USE_FIREBASE_EMULATORS',
      defaultValue: true,
    );
    if (!useEmulators) {
      return;
    }

    final host = _emulatorHost();
    FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    functions.useFunctionsEmulator(host, 5001);
    FirebaseStorage.instance.useStorageEmulator(host, 9199);

    _emulatorsConfigured = true;
    debugPrint('Firebase emulators habilitados em $host.');
  }

  static String _emulatorHost() {
    if (kIsWeb) {
      return 'localhost';
    }
    return defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
  }
}
