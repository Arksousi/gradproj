// splash_screen.dart
// Animated splash screen that routes to login or dashboard based on auth state.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../widgets/common/psycare_logo.dart';

/// Splash screen shown on app launch.
/// Waits 2 seconds, then navigates based on authentication state.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final authState = ref.read(authProvider);

    if (authState.isAuthenticated) {
      final role = authState.user!.role;
      if (role == 'therapist') {
        Navigator.pushReplacementNamed(context, AppRoutes.therapistDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.patientDashboard);
      }
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // PsyCare logo
              const PsyCareLogo(size: 160, showText: true)
                  .animate()
                  .scale(duration: 700.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 500.ms),

              const SizedBox(height: 8),

              // Tagline
              const Text(
                AppStrings.appTagline,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 500.ms),

              const SizedBox(height: 60),

              // Loading indicator
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
