// app.dart
// Root application widget — sets up MaterialApp with theme, routes, localization and Riverpod.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_strings.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'domain/providers/locale_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/patient/ai_summary_screen.dart';
import 'presentation/screens/patient/assessment_complete_screen.dart';
import 'presentation/screens/patient/assessment_intro_screen.dart';
import 'presentation/screens/patient/assessment_screen.dart';
import 'presentation/screens/patient/booking_consent_screen.dart';
import 'presentation/screens/patient/chat_screen.dart';
import 'presentation/screens/patient/description_screen.dart';
import 'presentation/screens/patient/immediate_chat_waiting_screen.dart';
import 'presentation/screens/patient/patient_dashboard.dart';
import 'presentation/screens/patient/post_assessment_screen.dart';
import 'presentation/screens/patient/therapist_directory_screen.dart';
import 'presentation/screens/patient/therapist_profile_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/therapist/incoming_requests_screen.dart';
import 'presentation/screens/therapist/patient_detail_screen.dart';
import 'presentation/screens/therapist/patient_list_screen.dart';
import 'presentation/screens/therapist/therapist_dashboard.dart';

/// The root [ConsumerWidget] of PsyCare.
/// Wraps [MaterialApp] with theme, locale, and named route table.
class PsyCareApp extends ConsumerWidget {
  const PsyCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Localization
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Initial route
      initialRoute: AppRoutes.splash,

      // Named route table
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),

        // Patient routes
        AppRoutes.patientDashboard: (_) => const PatientDashboard(),
        AppRoutes.assessmentIntro: (_) => const AssessmentIntroScreen(),
        AppRoutes.assessment: (_) => const AssessmentScreen(),
        AppRoutes.assessmentComplete: (_) => const AssessmentCompleteScreen(),
        AppRoutes.description: (_) => const DescriptionScreen(),
        AppRoutes.aiSummary: (_) => const AiSummaryScreen(),
        AppRoutes.postAssessment: (_) => const PostAssessmentScreen(),
        AppRoutes.immediateChatWaiting: (_) =>
            const ImmediateChatWaitingScreen(),
        AppRoutes.chat: (_) => const ChatScreen(),
        AppRoutes.therapistDirectory: (_) =>
            const TherapistDirectoryScreen(),
        AppRoutes.therapistProfile: (_) => const TherapistProfileScreen(),
        AppRoutes.bookingConsent: (_) => const BookingConsentScreen(),

        // Therapist routes
        AppRoutes.therapistDashboard: (_) => const TherapistDashboard(),
        AppRoutes.patientList: (_) => const PatientListScreen(),
        AppRoutes.patientDetail: (_) => const PatientDetailScreen(),
        AppRoutes.incomingRequests: (_) => const IncomingRequestsScreen(),

        // Shared
        AppRoutes.settings: (_) => const SettingsScreen(),
      },
    );
  }
}
