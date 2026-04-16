// patient_detail_screen.dart
// Shows a patient's assessment answers, description, and AI summary.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/assessment_model.dart';
import '../../../data/models/patient_model.dart';
import '../../../domain/providers/therapist_provider.dart';
import '../../widgets/common/custom_button.dart';

// TODO: Move this to a secure config / environment variable before production.
// For development, replace with your actual Groq API key.
const _kGroqApiKey = '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';

/// Screen showing full patient details for a therapist.
/// Accepts a [PatientModel] via route arguments.
class PatientDetailScreen extends ConsumerWidget {
  const PatientDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = ModalRoute.of(context)!.settings.arguments as PatientModel;
    final summaryState = ref.watch(aiSummaryProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_rounded,
                            color: AppColors.textPrimary, size: 20),
                      ),
                      Expanded(
                        child: Text(
                          AppStrings.patientDetail,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Patient header card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: _PatientHeaderCard(patient: patient),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
              ),

              // Assessment section
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: _SectionTitle(AppStrings.assessmentAnswers),
                ),
              ),

              SliverToBoxAdapter(
                child: patient.assessment.isNotEmpty
                    ? _AssessmentAnswersList(assessment: patient.assessment)
                    : const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No assessment submitted yet.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
              ),

              // Description section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle(AppStrings.patientDescription),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          patient.description.isNotEmpty
                              ? patient.description
                              : 'No description provided.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ),

              // AI Summary section
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: _SectionTitle(AppStrings.aiSummary),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: CustomButton(
                    label: AppStrings.summarizeWithAI,
                    onPressed: summaryState.isLoading
                        ? null
                        : () => _handleSummarize(context, ref, patient),
                    isLoading: summaryState.isLoading,
                    icon: Icons.auto_awesome_rounded,
                  ),
                ).animate().fadeIn(delay: 450.ms),
              ),

              if (summaryState.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        AppStrings.generating,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),

              if (summaryState.errorMessage != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: _ErrorBox(summaryState.errorMessage!),
                  ).animate().fadeIn(),
                ),

              if (summaryState.summary != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                    child: _AiSummaryCard(summary: summaryState.summary!),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.1, end: 0),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSummarize(
      BuildContext context, WidgetRef ref, PatientModel patient) async {
    if (patient.assessment.isEmpty) {
      Helpers.showError(
          context, 'Patient has not submitted an assessment yet.');
      return;
    }
    await ref.read(aiSummaryProvider.notifier).summarize(
          patient: patient,
          apiKey: _kGroqApiKey,
        );
    if (context.mounted) {
      final state = ref.read(aiSummaryProvider);
      if (state.errorMessage != null) {
        Helpers.showError(context, state.errorMessage!);
      }
    }
  }
}

/// Header card showing patient name, email, and severity badge.
class _PatientHeaderCard extends StatelessWidget {
  final PatientModel patient;

  const _PatientHeaderCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final severity = Helpers.scoreSeverity(patient.totalScore);
    final initials = Helpers.getInitials(patient.name);
    final submittedDate = patient.submittedAt != null
        ? Helpers.formatDate(patient.submittedAt!)
        : 'Not submitted';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.accentLight,
            child: Text(
              initials,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name.isNotEmpty ? patient.name : 'Patient',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  patient.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 12, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      submittedDate,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                    const Spacer(),
                    Text(
                      'Score: ${patient.totalScore}/90',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SeverityBadge(severity: severity),
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;

  const _SeverityBadge({required this.severity});

  Color get _color {
    switch (severity) {
      case 'Minimal':
        return AppColors.success;
      case 'Mild':
        return AppColors.warning;
      case 'Moderate':
        return Colors.orange;
      case 'Severe':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        severity,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

/// Scrollable list of assessment Q&A pairs.
class _AssessmentAnswersList extends StatelessWidget {
  final List<int> assessment;

  const _AssessmentAnswersList({required this.assessment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: List.generate(
          assessment.length.clamp(0, AssessmentModel.questions.length),
          (i) {
            final q = AssessmentModel.questions[i];
            final answerIdx = assessment[i];
            final answer =
                answerIdx < q.options.length ? q.options[answerIdx] : 'N/A';
            return Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          q.category,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Q${i + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    q.question,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.arrow_right_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        answer,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (i * 30).ms, duration: 200.ms);
          },
        ),
      ),
    );
  }
}

/// Card displaying the AI-generated summary with styled formatting.
class _AiSummaryCard extends StatelessWidget {
  final String summary;

  const _AiSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI Clinical Summary',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Groq · Llama 3.3',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.border),
            const SizedBox(height: 12),
            Text(
              summary,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
