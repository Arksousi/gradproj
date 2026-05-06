// app_constants.dart
// Central place for build-time and runtime constants.
//
// To override the backend URL for a physical device or production, build with:
//   flutter run --dart-define=BACKEND_URL=http://192.168.1.x:8000
//   flutter build apk --dart-define=BACKEND_URL=https://your-production-domain.com

class AppConstants {
  AppConstants._();

  /// Python FastAPI backend base URL.
  /// Override at build time with --dart-define=BACKEND_URL=...
  /// Default: Android emulator loopback (10.0.2.2 → host machine localhost).
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const Duration httpTimeout = Duration(seconds: 30);
}
