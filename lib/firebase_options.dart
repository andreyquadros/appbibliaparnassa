// File generated manually from Firebase MCP SDK configs.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'FirebaseOptions nao foram configuradas para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAnJqWxjBS6pCwBjCXk1WdflBC9fjrN8Zw',
    appId: '1:650786366043:web:bd0a149ce3d5d1db89957e',
    messagingSenderId: '650786366043',
    projectId: 'palavraviva-app-2026',
    authDomain: 'palavraviva-app-2026.firebaseapp.com',
    storageBucket: 'palavraviva-app-2026.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDPi0KXsE6KZZwwJTaDKhfcXgW_VrVq75k',
    appId: '1:650786366043:android:8c00a75f15b4a4c189957e',
    messagingSenderId: '650786366043',
    projectId: 'palavraviva-app-2026',
    storageBucket: 'palavraviva-app-2026.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC7gPfZ9I1o6sjBMCeJ1U0I9VfKQmQHzJ0',
    appId: '1:650786366043:ios:01b1c5adf18f761389957e',
    messagingSenderId: '650786366043',
    projectId: 'palavraviva-app-2026',
    storageBucket: 'palavraviva-app-2026.firebasestorage.app',
    iosBundleId: 'com.palavraviva.palavraViva',
  );
}
