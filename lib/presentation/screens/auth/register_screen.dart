// register_screen.dart
// Registration screen with name, email, password fields and role selection.

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

/// Registration screen for new patients and therapists.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'patient';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          role: _selectedRole,
        );

    if (!mounted) return;

    if (success) {
      Helpers.showSuccess(context, AppStrings.registerSuccess);
      if (_selectedRole == 'therapist') {
        Navigator.pushReplacementNamed(context, AppRoutes.therapistDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.patientDashboard);
      }
    } else {
      final error =
          ref.read(authProvider).errorMessage ?? AppStrings.error;
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
          decoration:
              const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Logo + title
                    _buildHeader(context),

                    const SizedBox(height: 32),

                    // Role selection
                    _buildRoleSelector()
                        .animate()
                        .fadeIn(delay: 250.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 20),

                    // Name
                    CustomTextField(
                      label: AppStrings.fullName,
                      hint: 'John Doe',
                      controller: _nameController,
                      validator: Validators.name,
                      prefixIcon: Icons.person_outline,
                    ).animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: 14),

                    // Email
                    CustomTextField(
                      label: AppStrings.email,
                      hint: 'your@email.com',
                      controller: _emailController,
                      validator: Validators.email,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                    ).animate().fadeIn(delay: 420.ms),

                    const SizedBox(height: 14),

                    // Password
                    CustomTextField(
                      label: AppStrings.password,
                      controller: _passwordController,
                      validator: Validators.password,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline,
                    ).animate().fadeIn(delay: 490.ms),

                    const SizedBox(height: 14),

                    // Confirm password
                    CustomTextField(
                      label: AppStrings.confirmPassword,
                      controller: _confirmPasswordController,
                      validator: (v) => Validators.confirmPassword(
                          v, _passwordController.text),
                      isPassword: true,
                      prefixIcon: Icons.lock_outline,
                    ).animate().fadeIn(delay: 560.ms),

                    const SizedBox(height: 28),

                    // Register button
                    CustomButton(
                      label: AppStrings.signUp,
                      onPressed: _handleRegister,
                      isLoading: authState.isLoading,
                    ).animate().fadeIn(delay: 630.ms),

                    const SizedBox(height: 20),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.hasAccount,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            AppStrings.signIn,
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

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 170,
          height: 170,
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut).fadeIn(duration: 400.ms),
        const SizedBox(height: 4),
        Text(
          'Create Account',
          style: Theme.of(context).textTheme.displayMedium,
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 4),
        Text(
          'Join PsyCare to start your journey',
          style: Theme.of(context).textTheme.bodyMedium,
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.selectRole,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _RoleChip(
                label: AppStrings.rolePatient,
                icon: Icons.person_rounded,
                isSelected: _selectedRole == 'patient',
                onTap: () => setState(() => _selectedRole = 'patient'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleChip(
                label: AppStrings.roleTherapist,
                icon: Icons.medical_services_rounded,
                isSelected: _selectedRole == 'therapist',
                onTap: () => setState(() => _selectedRole = 'therapist'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A selectable role chip widget used in the role selector.
class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
