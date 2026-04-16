// main.dart
// App entry point — initializes Firebase and wraps the app in ProviderScope.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

Future<void> main() async {
  // Ensure Flutter engine is initialized before platform channel calls
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for a consistent mobile experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style (status bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase — requires google-services.json (Android)
  // and GoogleService-Info.plist (iOS) to be configured.
  await Firebase.initializeApp();

  // Wrap the entire app in ProviderScope to enable Riverpod state management
  runApp(
    const ProviderScope(
      child: PsyCareApp(),
    ),
  );
}
