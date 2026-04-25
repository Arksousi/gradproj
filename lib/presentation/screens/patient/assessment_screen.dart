// assessment_screen.dart
// Paged MCQ form for the 30-question mental health assessment.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/assessment_model.dart';
import '../../../domain/providers/patient_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/patient/question_card.dart';

Future<void> _confirmLeaveAssessment(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(context.tr('leaveAssessment')),
      content: Text(context.tr('leaveBody')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(context.tr('keepGoing')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: Text(context.tr('leave')),
        ),
      ],
    ),
  );
  if ((leave ?? false) && context.mounted) {
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.patientDashboard, (_) => false);
  }
}

/// Full-screen assessment form showing one question per page.
/// Uses a [PageView] for smooth swipe navigation.
class AssessmentScreen extends ConsumerStatefulWidget {
  const AssessmentScreen({super.key});

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends ConsumerState<AssessmentScreen> {
  late final PageController _pageController;
  static const int _totalQuestions = 30; // AssessmentModel.totalQuestions

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToNext(int current) async {
    if (current < _totalQuestions - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final success =
          await ref.read(assessmentProvider.notifier).submitAssessment();
      if (!mounted) return;
      if (success) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.assessmentComplete, (_) => false);
      } else {
        Helpers.showError(context, 'Failed to submit. Please try again.');
      }
    }
  }

  void _goToPrevious(int current) {
    if (current > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final assessmentState = ref.watch(assessmentProvider);
    final notifier = ref.read(assessmentProvider.notifier);
    final currentPage = assessmentState.currentPage;
    final progress = (currentPage + 1) / _totalQuestions;

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (currentPage == 0) {
                          Navigator.pop(context);
                        } else {
                          _goToPrevious(currentPage);
                        }
                      },
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: AppColors.textPrimary, size: 20),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _confirmLeaveAssessment(context),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text(context.tr('leave')),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${AppStrings.questionOf} ${currentPage + 1} ${AppStrings.of} $_totalQuestions',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.border,
                              color: AppColors.primary,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Page title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  AppStrings.assessmentTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 4),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  AppStrings.assessmentSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Questions
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => notifier.setPage(page),
                  itemCount: _totalQuestions,
                  itemBuilder: (context, index) {
                    final question = AssessmentModel.questions[index];
                    final selected = assessmentState.answers[index];
                    return SingleChildScrollView(
                      child: QuestionCard(
                        question: question,
                        questionNumber: index + 1,
                        selectedAnswerIndex: selected,
                        onAnswerSelected: (answerIdx) {
                          notifier.setAnswer(index, answerIdx);
                        },
                      ),
                    );
                  },
                ),
              ),

              // Navigation buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: _buildNavButtons(
                    context, currentPage, assessmentState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButtons(
      BuildContext context, int current, AssessmentState state) {
    final isAnswered = state.answers.containsKey(current);
    final isLast = current == _totalQuestions - 1;

    return Column(
      children: [
        if (isLast && isAnswered)
          CustomButton(
            label: 'Complete Assessment',
            onPressed: state.isSubmitting ? null : () => _goToNext(current),
            isLoading: state.isSubmitting,
            icon: Icons.check_rounded,
          ).animate().fadeIn(duration: 300.ms)
        else
          CustomButton(
            label: AppStrings.next,
            onPressed: isAnswered ? () => _goToNext(current) : null,
            icon: Icons.arrow_forward_rounded,
          ),
        if (current > 0) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => _goToPrevious(current),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text(AppStrings.back),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ],
        // Answered counter
        const SizedBox(height: 8),
        Text(
          '${state.answeredCount} of $_totalQuestions answered',
          style: const TextStyle(
              fontSize: 12, color: AppColors.textHint),
        ),
      ],
    );
  }
}
