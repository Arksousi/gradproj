// patient_dashboard.dart
// Main dashboard for patients — shows welcome message and action cards.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/booking_provider.dart';
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
    final bookingsAsync =
        ref.watch(patientBookingsProvider(user?.uid ?? ''));

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
                      Flexible(
                        child: Row(
                          children: [
                            Image.asset('assets/images/logo.png',
                                width: 64, height: 64),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Column(
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
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

              // AI Insights card (only when therapist has generated a summary)
              SliverToBoxAdapter(
                child: patientAsync.whenData((patient) {
                  if (patient?.aiSummary == null || patient!.aiSummary!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: _AiInsightsCard(summary: patient.aiSummary!),
                  ).animate().fadeIn(delay: 230.ms).slideY(begin: 0.1, end: 0);
                }).value ?? const SizedBox.shrink(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Booking status card (only when there's an active booking)
              SliverToBoxAdapter(
                child: bookingsAsync.whenData((bookings) {
                  final active = bookings
                      .where((b) =>
                          b.status == 'pending' || b.status == 'confirmed')
                      .toList();
                  if (active.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: _BookingStatusCard(booking: active.first),
                  ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.1, end: 0);
                }).value ??
                    const SizedBox.shrink(),
              ),

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
                          Navigator.pushNamed(context, AppRoutes.assessmentIntro),
                    ),
                    const SizedBox(height: 14),
                    _ActionCard(
                      icon: Icons.favorite_rounded,
                      title: context.tr('talkToAI'),
                      subtitle: context.tr('talkToAISubtitle'),
                      color: AppColors.accent,
                      delay: 500,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.chatbot),
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
// Booking status card
// ---------------------------------------------------------------------------

class _BookingStatusCard extends ConsumerWidget {
  final dynamic booking; // BookingRequest

  const _BookingStatusCard({required this.booking});

  ({Color color, IconData icon, String labelKey}) _statusMeta(String status) {
    switch (status) {
      case 'confirmed':
        return (
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
          labelKey: 'bookingStatusConfirmed'
        );
      case 'declined':
        return (
          color: AppColors.error,
          icon: Icons.cancel_rounded,
          labelKey: 'bookingStatusDeclined'
        );
      case 'cancelled_by_patient':
        return (
          color: AppColors.textSecondary,
          icon: Icons.block_rounded,
          labelKey: 'bookingStatusCancelledPatient'
        );
      case 'cancelled_by_therapist':
        return (
          color: AppColors.error,
          icon: Icons.block_rounded,
          labelKey: 'bookingStatusCancelledTherapist'
        );
      case 'reschedule_requested':
        return (
          color: AppColors.primary,
          icon: Icons.schedule_rounded,
          labelKey: 'bookingStatusRescheduleRequested'
        );
      default: // pending
        return (
          color: AppColors.warning,
          icon: Icons.hourglass_top_rounded,
          labelKey: 'bookingStatusPending'
        );
    }
  }

  Future<void> _showCancelDialog(
      BuildContext context, WidgetRef ref) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('cancelBookingTitle')),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: context.tr('cancelBookingHint'),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('cancelBookingConfirm')),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(bookingActionProvider.notifier).cancel(
            booking.id,
            cancelledBy: 'patient',
            reason: reasonCtrl.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.tr('bookingCancelledSnack')),
          backgroundColor: AppColors.textSecondary,
        ));
      }
    }
  }

  Future<void> _showRescheduleDialog(
      BuildContext context, WidgetRef ref) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('rescheduleTitle')),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: context.tr('rescheduleHint'),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('rescheduleConfirm')),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref
          .read(bookingActionProvider.notifier)
          .requestReschedule(booking.id, noteCtrl.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.tr('rescheduleSentSnack')),
          backgroundColor: AppColors.primary,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = (booking.status as String?) ?? 'pending';
    final meta = _statusMeta(status);
    final therapistLabel = ((booking.therapistName as String?) ?? '').isNotEmpty
        ? booking.therapistName as String
        : context.tr('yourTherapist');
    final isActionable =
        status == 'pending' || status == 'confirmed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: meta.color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(meta.icon, color: meta.color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(meta.labelKey),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: meta.color,
                      ),
                    ),
                    Text(
                      therapistLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isActionable) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCancelDialog(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.5)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: Text(context.tr('cancelBooking')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRescheduleDialog(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.5)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: Text(context.tr('requestReschedule')),
                  ),
                ),
              ],
            ),
          ],
          if (status == 'reschedule_requested' &&
              (booking.rescheduleNote as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              '${context.tr('rescheduleNote')}: ${booking.rescheduleNote}',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
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

class _AiInsightsCard extends StatelessWidget {
  final String summary;

  const _AiInsightsCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                context.tr('aiInsights'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              const Text(
                'Groq · Llama 3.3',
                style: TextStyle(fontSize: 10, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
