// login_screen.dart
// Sign in screen with email/password fields and role-aware navigation.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_textfield.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/psycare_logo.dart';

/// Login screen — entry point for all returning users.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).signIn(
          _emailController.text,
          _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      final role = ref.read(authProvider).user?.role ?? 'patient';
      Helpers.showSuccess(context, AppStrings.loginSuccess);
      if (role == 'therapist') {
        Navigator.pushReplacementNamed(context, AppRoutes.therapistDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.patientDashboard);
      }
    } else {
      final error = ref.read(authProvider).errorMessage ?? AppStrings.error;
      Helpers.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return LoadingOverlay(
      isLoading: authState.isLoading,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),

                    // Logo
                    _buildLogo(),

                    const SizedBox(height: 36),

                    // Title
                    Text(
                      'Welcome Back',
                      style: Theme.of(context).textTheme.displayMedium,
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 6),

                    Text(
                      'Sign in to continue your wellness journey',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 36),

                    // Email field
                    CustomTextField(
                      label: AppStrings.email,
                      hint: 'your@email.com',
                      controller: _emailController,
                      validator: Validators.email,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 16),

                    // Password field
                    CustomTextField(
                      label: AppStrings.password,
                      controller: _passwordController,
                      validator: Validators.password,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline,
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 28),

                    // Sign in button
                    CustomButton(
                      label: AppStrings.signIn,
                      onPressed: _handleLogin,
                      isLoading: authState.isLoading,
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 20),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.noAccount,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.register),
                          child: const Text(
                            AppStrings.signUp,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 700.ms),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return const PsyCareLogo(size: 120, showText: true)
        .animate()
        .scale(duration: 600.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 400.ms);
  }
}
