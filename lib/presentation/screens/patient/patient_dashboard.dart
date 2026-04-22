// patient_dashboard.dart
// Main dashboard for patients — shows welcome message and action cards.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/patient_provider.dart';

const int _kOpenHour = 9;
const int _kCloseHour = 22;

bool _isWithinHours() {
  final now = DateTime.now();
  return now.hour >= _kOpenHour && now.hour < _kCloseHour;
}

/// Patient's home screen — displays their name and quick-action cards.
class PatientDashboard extends ConsumerWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final patientAsync = ref.watch(currentPatientProvider);

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/images/logo.png',
                              width: 64, height: 64),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${context.tr('hello')}, 👋',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                user?.name ?? context.tr('rolePatient'),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms).slideX(
                          begin: -0.1, end: 0),
                      // Settings button
                      IconButton(
                        onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.settings),
                        icon: const Icon(Icons.settings_rounded,
                            color: AppColors.textSecondary),
                        tooltip: context.tr('settings'),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // Status card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: patientAsync.when(
                    data: (patient) => _StatusCard(
                      hasSubmitted: patient?.submittedAt != null,
                    ),
                    loading: () => const _StatusCardSkeleton(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Live chat button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _LiveChatButton(),
                ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.1, end: 0),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // Section title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    context.tr('whatToDo'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ).animate().fadeIn(delay: 300.ms),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Action cards
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ActionCard(
                      icon: Icons.assignment_rounded,
                      title: context.tr('mentalHealthAssessment'),
                      subtitle: context.tr('answerQuestions'),
                      color: AppColors.primary,
                      delay: 400,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.assessment),
                    ),
                    const SizedBox(height: 14),
                    _ActionCard(
                      icon: Icons.edit_note_rounded,
                      title: context.tr('describeYourFeelings'),
                      subtitle: context.tr('writeAboutMind'),
                      color: AppColors.accent,
                      delay: 500,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.description),
                    ),
                    const SizedBox(height: 14),
                    _ActionCard(
                      icon: Icons.info_outline_rounded,
                      title: context.tr('aboutPsycare'),
                      subtitle: context.tr('learnPrivacy'),
                      color: AppColors.success,
                      delay: 600,
                      onTap: () => _showAboutDialog(context),
                    ),
                  ]),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('appName')),
        content: const Text(
          'PsyCare helps you connect with licensed therapists and track your '
          'mental wellbeing. Your data is encrypted and only shared with your '
          'assigned therapist.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('gotIt')),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Live chat button
// ---------------------------------------------------------------------------

class _LiveChatButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = _isWithinHours();

    return GestureDetector(
      onTap: available
          ? () => Navigator.pushNamed(
                context,
                AppRoutes.postAssessment,
                arguments: <String, String>{
                  'patientSummary': '',
                  'clinicalReport': '',
                },
              )
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: available ? AppColors.primaryGradient : null,
          color: available ? null : AppColors.border,
          borderRadius: BorderRadius.circular(16),
          boxShadow: available
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.support_agent_rounded,
              color: available ? Colors.white : AppColors.textHint,
              size: 26,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('talkSomeoneNow'),
                    style: TextStyle(
                      color: available ? Colors.white : AppColors.textHint,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    available
                        ? context.tr('connectTherapistNow')
                        : context.tr('availableHours'),
                    style: TextStyle(
                      color: available
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              available
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.lock_clock_rounded,
              color: available ? Colors.white : AppColors.textHint,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status card
// ---------------------------------------------------------------------------

class _StatusCard extends StatelessWidget {
  final bool hasSubmitted;

  const _StatusCard({required this.hasSubmitted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasSubmitted
                      ? context.tr('assessmentSubmitted')
                      : context.tr('assessmentPending'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasSubmitted
                      ? context.tr('therapistNotified')
                      : context.tr('completeAssessment'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            hasSubmitted
                ? Icons.check_circle_rounded
                : Icons.pending_rounded,
            color: Colors.white,
            size: 40,
          ),
        ],
      ),
    );
  }
}

class _StatusCardSkeleton extends StatelessWidget {
  const _StatusCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action card
// ---------------------------------------------------------------------------

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 22),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 300.ms)
        .slideX(begin: 0.05, end: 0);
  }
}
