import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration is injected at build time via `--dart-define`
/// (see README "Connect your own Firebase project").
///
/// Example:
///   flutter run --dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_PROJECT_ID=...
/// or use `flutterfire configure` to generate this file yourself.
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
          'Run `flutterfire configure` before building native apps.',
        );
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    authDomain: String.fromEnvironment(
      'FIREBASE_AUTH_DOMAIN',
      defaultValue: '',
    ),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
  );

  /// True when the build was produced with Firebase config values.
  static bool get isConfigured =>
      const String.fromEnvironment('FIREBASE_PROJECT_ID').isNotEmpty;
}
