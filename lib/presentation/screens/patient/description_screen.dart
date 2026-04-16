// description_screen.dart
// Free-text input screen where the patient describes their feelings before submission.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/helpers.dart';
import '../../../domain/providers/patient_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

/// Screen where the patient writes a free-text description of their feelings.
/// On submission, both assessment answers and description are sent to Firestore.
class DescriptionScreen extends ConsumerStatefulWidget {
  const DescriptionScreen({super.key});

  @override
  ConsumerState<DescriptionScreen> createState() => _DescriptionScreenState();
}

class _DescriptionScreenState extends ConsumerState<DescriptionScreen> {
  final _controller = TextEditingController();
  final int _minChars = 20;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.length < _minChars) {
      Helpers.showError(
          context, 'Please write at least $_minChars characters.');
      return;
    }

    final success =
        await ref.read(assessmentProvider.notifier).submitAssessment(text);

    if (!mounted) return;

    if (success) {
      Helpers.showSuccess(context, AppStrings.assessmentSubmitted);
      // Navigate back to dashboard and clear the stack
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.patientDashboard, (route) => false);
    } else {
      final error = ref.read(assessmentProvider).errorMessage ??
          AppStrings.error;
      Helpers.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);

    return LoadingOverlay(
      isLoading: state.isSubmitting,
      message: 'Submitting your assessment...',
      child: Scaffold(
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
                  Text(
                    AppStrings.descriptionTitle,
                    style: Theme.of(context).textTheme.displayMedium,
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 8),

                  Text(
                    'This helps your therapist understand your current mental state. '
                    'Be as honest and detailed as you like.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 24),

                  // Mood emoji selector
                  _MoodSelector().animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 20),

                  // Text area
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                        decoration: const InputDecoration(
                          hintText: AppStrings.descriptionHint,
                          hintStyle: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(18),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 8),

                  // Character count
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_controller.text.length} characters',
                      style: TextStyle(
                        fontSize: 12,
                        color: _controller.text.length < _minChars
                            ? AppColors.error
                            : AppColors.textHint,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Submit button
                  CustomButton(
                    label: AppStrings.submitAssessment,
                    onPressed:
                        _controller.text.length >= _minChars ? _handleSubmit : null,
                    isLoading: state.isSubmitting,
                    icon: Icons.send_rounded,
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A simple row of mood emoji buttons for quick emotional check-in.
class _MoodSelector extends StatefulWidget {
  @override
  State<_MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<_MoodSelector> {
  int? _selected;

  static const _moods = [
    ('😔', 'Very Low'),
    ('😟', 'Low'),
    ('😐', 'Neutral'),
    ('🙂', 'Good'),
    ('😊', 'Great'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How are you feeling right now?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_moods.length, (i) {
            final (emoji, label) = _moods[i];
            final isSelected = _selected == i;
            return GestureDetector(
              onTap: () => setState(() => _selected = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textHint,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
