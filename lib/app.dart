// app.dart
// Root application widget — sets up MaterialApp with theme, routes, and Riverpod.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/patient/assessment_screen.dart';
import 'presentation/screens/patient/description_screen.dart';
import 'presentation/screens/patient/patient_dashboard.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/therapist/patient_detail_screen.dart';
import 'presentation/screens/therapist/patient_list_screen.dart';
import 'presentation/screens/therapist/therapist_dashboard.dart';

/// The root [ConsumerWidget] of PsyCare.
/// Wraps [MaterialApp] with the app theme and named route table.
class PsyCareApp extends ConsumerWidget {
  const PsyCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Initial route — always starts at the splash screen
      initialRoute: AppRoutes.splash,

      // Named route table
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.patientDashboard: (_) => const PatientDashboard(),
        AppRoutes.assessment: (_) => const AssessmentScreen(),
        AppRoutes.description: (_) => const DescriptionScreen(),
        AppRoutes.therapistDashboard: (_) => const TherapistDashboard(),
        AppRoutes.patientList: (_) => const PatientListScreen(),
        AppRoutes.patientDetail: (_) => const PatientDetailScreen(),
      },
    );
  }
}
