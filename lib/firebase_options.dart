// firebase_options.dart
// Generated Firebase configuration for all platforms.
// DO NOT edit manually — regenerate with: flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCsgfdoAeUImq9oHHOfM3tIggxhdggGJt0',
    appId: '1:505901603194:android:8744a8593763d17da7dec3',
    messagingSenderId: '505901603194',
    projectId: 'psycare-70248',
    storageBucket: 'psycare-70248.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD_YiA9hkXN8h9jo97B_SEwHrWCOnqC4BQ',
    appId: '1:505901603194:ios:f3c0bfb36199ec0aa7dec3',
    messagingSenderId: '505901603194',
    projectId: 'psycare-70248',
    storageBucket: 'psycare-70248.firebasestorage.app',
    iosBundleId: 'com.example.psycare',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD_YiA9hkXN8h9jo97B_SEwHrWCOnqC4BQ',
    appId: '1:505901603194:ios:f3c0bfb36199ec0aa7dec3',
    messagingSenderId: '505901603194',
    projectId: 'psycare-70248',
    storageBucket: 'psycare-70248.firebasestorage.app',
    iosBundleId: 'com.example.psycare',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD_YiA9hkXN8h9jo97B_SEwHrWCOnqC4BQ',
    appId: '1:505901603194:ios:f3c0bfb36199ec0aa7dec3',
    messagingSenderId: '505901603194',
    projectId: 'psycare-70248',
    storageBucket: 'psycare-70248.firebasestorage.app',
  );
}
