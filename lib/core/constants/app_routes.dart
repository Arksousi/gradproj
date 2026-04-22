// app_routes.dart
// Named route constants used for navigation across PsyCare.

/// Centralized route name constants to avoid magic strings in navigation calls.
class AppRoutes {
  AppRoutes._(); // Prevent instantiation

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Patient routes
  static const String patientDashboard = '/patient-dashboard';
  static const String assessment = '/assessment';
  static const String description = '/description';

  // Therapist routes
  static const String therapistDashboard = '/therapist-dashboard';
  static const String patientList = '/patient-list';
  static const String patientDetail = '/patient-detail';

  // New patient routes
  static const String dsm5Questions = '/dsm5';
  static const String openText = '/open-text';
  static const String aiSummary = '/ai-summary';
  static const String postAssessment = '/post-assessment';
  static const String immediateChatWaiting = '/immediate-chat-waiting';
  static const String chat = '/chat';
  static const String therapistDirectory = '/therapist-directory';
  static const String therapistProfile = '/therapist-profile';
  static const String bookingConsent = '/booking-consent';

  // New therapist routes
  static const String incomingRequests = '/incoming-requests';

  // Shared routes
  static const String settings = '/settings';
}
