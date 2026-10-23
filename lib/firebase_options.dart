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
    apiKey: String.fromEnvironment(
      'FIREBASE_WEB_API_KEY',
      defaultValue: 'AIzaSyDemoPlaceholderAarogyaSetu_Scrubbed',
    ),
    appId: '1:558469968732:web:aarogyasetuweb2026',
    messagingSenderId: '558469968732',
    projectId: 'aarogya-setu-sdg',
    authDomain: 'aarogya-setu-sdg.firebaseapp.com',
    storageBucket: 'aarogya-setu-sdg.firebasestorage.app',
  );


  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_ANDROID_API_KEY',
      defaultValue: 'AIzaSyDemoPlaceholderAarogyaSetu_Scrubbed',
    ),
    appId: '1:558469968732:android:21658157e0a971dfdd8799',
    messagingSenderId: '558469968732',
    projectId: 'aarogya-setu-sdg',
    storageBucket: 'aarogya-setu-sdg.firebasestorage.app',
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
