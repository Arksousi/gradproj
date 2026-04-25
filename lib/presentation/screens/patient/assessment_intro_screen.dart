// assessment_intro_screen.dart
// Informational consent screen shown before the DSM-5 assessment begins.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';

class AssessmentIntroScreen extends StatefulWidget {
  const AssessmentIntroScreen({super.key});

  @override
  State<AssessmentIntroScreen> createState() => _AssessmentIntroScreenState();
}

class _AssessmentIntroScreenState extends State<AssessmentIntroScreen> {
  bool _consentChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoSection(
                        delay: 0,
                        title: 'What is this assessment?',
                        body:
                            'This assessment is based on the DSM-5 Level 1 Cross-Cutting Symptom Measure, '
                            'developed by the American Psychiatric Association. '
                            'It is one of the most trusted and widely used tools in mental health care today.',
                      ),
                      _InfoSection(
                        delay: 80,
                        title: 'What is the goal?',
                        body:
                            'The goal of this assessment is not to diagnose you. '
                            'It is to help your therapist understand where you are right now, '
                            'so your first session can be as focused and helpful as possible. '
                            'Your answers give your therapist a clear, honest picture of what you have been experiencing.',
                      ),
                      _InfoSection(
                        delay: 160,
                        title: 'What will you be asked?',
                        bullets: const [
                          '30 questions across 13 mental health domains (such as mood, anxiety, sleep, and concentration)',
                          'Each question uses a simple 0–4 scale',
                          'There are no right or wrong answers',
                          'The whole assessment takes about 5–10 minutes',
                          'After the questions, your therapist will receive a detailed clinical summary',
                        ],
                      ),
                      _InfoSection(
                        delay: 240,
                        title: 'Where do these questions come from?',
                        body:
                            'These questions come directly from the DSM-5, the Diagnostic and Statistical '
                            'Manual of Mental Disorders, Fifth Edition. '
                            'This is the standard reference used by psychiatrists, psychologists, and therapists '
                            'worldwide to guide mental health assessment.',
                      ),
                      _ConsentSection(
                        delay: 320,
                        checked: _consentChecked,
                        onChanged: (v) =>
                            setState(() => _consentChecked = v ?? false),
                      ),
                      const SizedBox(height: 28),
                      _BeginButton(
                        enabled: _consentChecked,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.assessment),
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 24, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
          const SizedBox(width: 4),
          Text(
            'Before We Begin 🌿',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

// ── Private widgets ──────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final int delay;
  final String title;
  final String? body;
  final List<String>? bullets;

  const _InfoSection({
    required this.delay,
    required this.title,
    this.body,
    this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            if (body != null)
              Text(
                body!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.65,
                ),
              ),
            if (bullets != null)
              ...bullets!.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 7),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          b,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 300.ms)
        .slideY(begin: 0.08, duration: 300.ms);
  }
}

class _ConsentSection extends StatelessWidget {
  final int delay;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  const _ConsentSection({
    required this.delay,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Consent',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'By continuing, you agree that:\n'
            '• Your answers will be shared with your assigned therapist\n'
            '• Your responses will be stored securely and used only for your care\n'
            '• You can stop at any time\n'
            '• This assessment does not replace a professional clinical diagnosis',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => onChanged(!checked),
            child: Row(
              children: [
                Checkbox(
                  value: checked,
                  onChanged: onChanged,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'I understand and I agree to proceed',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 300.ms)
        .slideY(begin: 0.08, duration: 300.ms);
  }
}

class _BeginButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _BeginButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.primaryGradient : null,
          color: enabled ? null : AppColors.border,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            'Begin Assessment →',
            style: TextStyle(
              color: enabled ? Colors.white : AppColors.textHint,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
