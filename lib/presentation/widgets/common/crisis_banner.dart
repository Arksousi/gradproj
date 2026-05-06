import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

/// Prominent banner displayed when crisis language is detected in a patient
/// message. Shows emergency hotlines and a dismiss button.
/// Wire up [onDismiss] to hide it from the parent widget.
class CrisisBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const CrisisBanner({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_rounded,
                      color: AppColors.error, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('crisisTitle'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.error,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textHint, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Body text
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              context.tr('crisisBody'),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),

          // Hotlines
          const _Divider(),
          _HotlineRow(
            label: context.tr('crisisIntlLabel'),
            number: context.tr('crisisIntlNumber'),
          ),
          _HotlineRow(
            label: context.tr('crisisLocalLabel'),
            number: context.tr('crisisLocalNumber'),
          ),
          _HotlineRow(
            label: context.tr('crisisEmergencyLabel'),
            number: context.tr('crisisEmergencyNumber'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: -0.08, end: 0, curve: Curves.easeOut);
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFFFD5D5),
        indent: 16,
        endIndent: 16,
      );
}

class _HotlineRow extends StatelessWidget {
  final String label;
  final String number;
  const _HotlineRow({required this.label, required this.number});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: number));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$number copied'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.textSecondary,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.phone_rounded, color: AppColors.error, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy_rounded, color: AppColors.textHint, size: 14),
          ],
        ),
      ),
    );
  }
}
