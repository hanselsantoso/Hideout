import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'FirebaseOptions for this platform are not configured yet. '
          'Run FlutterFire configure before building native apps.',
        );
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDsYg8Cc1WK3b5JY4wWGYEwDqe4EJXwz7Q',
    appId: '1:182996477617:web:cec45729a0b49a57de6490',
    messagingSenderId: '182996477617',
    projectId: 'tournamentmanagement-942ef',
    authDomain: 'tournamentmanagement-942ef.firebaseapp.com',
    storageBucket: 'tournamentmanagement-942ef.firebasestorage.app',
    measurementId: 'G-S5PJLNBNMK',
  );
}
