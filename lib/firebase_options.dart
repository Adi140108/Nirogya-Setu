import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for AarogyaSetu AI.
///
/// To connect to your real Firebase project:
/// 1. Run `flutterfire configure` in the terminal.
/// 2. Alternatively, replace the values below with your Firebase Console configuration.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAarogyaSetuDemoKey_WebDummy2026',
    appId: '1:1029384756:web:89abcdef0123456789',
    messagingSenderId: '1029384756',
    projectId: 'aarogya-setu-ai',
    authDomain: 'aarogya-setu-ai.firebaseapp.com',
    storageBucket: 'aarogya-setu-ai.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAarogyaSetuDemoKey_AndroidDummy2026',
    appId: '1:1029384756:android:1234567890abcdef',
    messagingSenderId: '1029384756',
    projectId: 'aarogya-setu-ai',
    storageBucket: 'aarogya-setu-ai.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAarogyaSetuDemoKey_IOSDummy2026',
    appId: '1:1029384756:ios:abcdef1234567890',
    messagingSenderId: '1029384756',
    projectId: 'aarogya-setu-ai',
    storageBucket: 'aarogya-setu-ai.appspot.com',
    iosBundleId: 'com.aarogyasetu.aarogyaSetu',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAarogyaSetuDemoKey_WindowsDummy2026',
    appId: '1:1029384756:windows:9876543210fedcba',
    messagingSenderId: '1029384756',
    projectId: 'aarogya-setu-ai',
    storageBucket: 'aarogya-setu-ai.appspot.com',
  );
}
