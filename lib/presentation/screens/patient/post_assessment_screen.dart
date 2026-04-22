// post_assessment_screen.dart
// Shown after assessment submission — patient chooses their next step.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/localization/app_localizations.dart';

const int _kOpenHour = 9;
const int _kCloseHour = 22;

bool _isWithinHours() {
  final now = DateTime.now();
  return now.hour >= _kOpenHour && now.hour < _kCloseHour;
}

/// Screen displayed after the patient finishes their assessment.
/// Lets them choose to talk now, find a therapist, or decide later.
class PostAssessmentScreen extends StatelessWidget {
  const PostAssessmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    final patientSummary = args?['patientSummary'] ?? '';
    final clinicalReport = args?['clinicalReport'] ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  context.tr('youreNotAlone'),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppColors.dark,
                        fontWeight: FontWeight.bold,
                      ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 10),
                Text(
                  context.tr('takeYourTime'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 40),
                _TalkNowCard(
                  patientSummary: patientSummary,
                  clinicalReport: clinicalReport,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 16),
                _FindTherapistCard()
                    .animate()
                    .fadeIn(delay: 400.ms)
                    .slideY(begin: 0.1, end: 0),
                const Spacer(),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, AppRoutes.patientDashboard, (_) => false),
                    child: Text(
                      context.tr('decideLater'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TalkNowCard extends StatelessWidget {
  final String patientSummary;
  final String clinicalReport;

  const _TalkNowCard({
    required this.patientSummary,
    required this.clinicalReport,
  });

  @override
  Widget build(BuildContext context) {
    final available = _isWithinHours();
    final now = DateTime.now();
    final nextOpenKey = now.hour < _kOpenHour ? 'nextOpenToday' : 'nextOpenTomorrow';

    return GestureDetector(
      onTap: available
          ? () => Navigator.pushNamed(
                context,
                AppRoutes.immediateChatWaiting,
                arguments: {
                  'patientSummary': patientSummary,
                  'clinicalReport': clinicalReport,
                },
              )
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: available ? AppColors.primaryGradient : null,
          color: available ? null : AppColors.border,
          borderRadius: BorderRadius.circular(20),
          boxShadow: available
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: available
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.textHint.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.chat_bubble_rounded,
                color: available ? Colors.white : AppColors.textHint,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('talkNow'),
                    style: TextStyle(
                      color: available ? Colors.white : AppColors.textHint,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    available
                        ? context.tr('talkNowSub')
                        : '${context.tr('availableFrom')} ${context.tr(nextOpenKey)}',
                    style: TextStyle(
                      color: available
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.textHint,
                      fontSize: 12,
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
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _FindTherapistCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.therapistDirectory),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.person_search_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('findTherapist'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('findTherapistSub'),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}
