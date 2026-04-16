// patient_card.dart
// A card widget displaying a patient's summary in the therapist's patient list.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/patient_model.dart';

/// Displays a compact patient summary card for the therapist's patient list.
/// Tapping the card triggers [onTap].
class PatientCard extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback onTap;
  final int index;

  const PatientCard({
    super.key,
    required this.patient,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final severity = Helpers.scoreSeverity(patient.totalScore);
    final severityColor = _severityColor(severity);
    final initials = Helpers.getInitials(patient.name);
    final submittedDate = patient.submittedAt != null
        ? Helpers.formatDate(patient.submittedAt!)
        : 'Pending';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.accentLight,
              child: Text(
                initials,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name.isNotEmpty ? patient.name : 'Patient',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    patient.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 11, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        submittedDate,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Severity badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    severity,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: severityColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right,
                    color: AppColors.textHint, size: 20),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 80).ms, duration: 300.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Color _severityColor(String severity) {
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
}
