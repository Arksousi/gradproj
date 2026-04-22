// ai_summary_screen.dart
// Displays the AI-generated summary for a patient after assessment submission.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/providers/patient_provider.dart';
import '../../../domain/providers/therapist_provider.dart';

class AiSummaryScreen extends ConsumerWidget {
  const AiSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(aiSummaryProvider);
    final patientAsync = ref.watch(currentPatientProvider);

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: AppColors.textPrimary, size: 20),
                  padding: EdgeInsets.zero,
                ),

                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Summary',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Powered by Groq',
                            style:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 24),

                // Content
                Expanded(
                  child: summaryState.isLoading
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                  color: AppColors.primary),
                              SizedBox(height: 16),
                              Text(
                                'Generating your summary...',
                                style: TextStyle(
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : summaryState.errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: AppColors.error, size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    summaryState.errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : summaryState.summary != null
                              ? SingleChildScrollView(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius:
                                          BorderRadius.circular(18),
                                      border: Border.all(
                                          color: AppColors.border),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.06),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      summaryState.summary!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                        height: 1.7,
                                      ),
                                    ),
                                  ).animate().fadeIn(delay: 200.ms),
                                )
                              : Center(
                                  child: Text(
                                    context.tr('error'),
                                    style: const TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                ),

                const SizedBox(height: 20),

                // CTA — navigate to post-assessment
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final patient = patientAsync.value;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.postAssessment,
                        (route) => route.settings.name ==
                                AppRoutes.patientDashboard ||
                            route.isFirst,
                        arguments: {
                          'patientSummary': summaryState.summary ?? '',
                          'clinicalReport': patient?.description ?? '',
                        },
                      );
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('What would you like to do next?'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
