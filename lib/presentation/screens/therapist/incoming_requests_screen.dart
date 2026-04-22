// incoming_requests_screen.dart
// Shows therapists the queue of patients requesting immediate support.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/chat_provider.dart';

class IncomingRequestsScreen extends ConsumerWidget {
  const IncomingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingImmediateRequestsProvider);

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: AppColors.textPrimary, size: 20),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('incomingTitle'),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            context.tr('incomingSubtitle'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 16),

              Expanded(
                child: requestsAsync.when(
                  data: (requests) {
                    if (requests.isEmpty) {
                      return _EmptyState();
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: requests.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (ctx, i) => _RequestCard(
                        request: requests[i],
                        index: i,
                        onAccept: () async {
                          final user = ref.read(currentUserProvider);
                          final repo = ref.read(chatRepositoryProvider);
                          final sessionId = await repo.acceptRequest(
                            requestId: requests[i].id,
                            therapistId: user?.uid ?? '',
                            patientId: requests[i].patientId,
                            patientSummary: requests[i].patientSummary,
                            clinicalReport: requests[i].clinicalReport,
                          );
                          if (ctx.mounted) {
                            Navigator.pushNamed(
                              ctx,
                              AppRoutes.chat,
                              arguments: {
                                'sessionId': sessionId,
                                'therapistId': user?.uid ?? '',
                              },
                            );
                          }
                        },
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Text(e.toString(),
                        style: const TextStyle(
                            color: AppColors.textSecondary)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_rounded,
                color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('noPendingRequests'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('pendingEmpty'),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

class _RequestCard extends StatelessWidget {
  final ImmediateRequest request;
  final int index;
  final VoidCallback onAccept;

  const _RequestCard({
    required this.request,
    required this.index,
    required this.onAccept,
  });

  String _waitingTime(BuildContext context) {
    final diff = DateTime.now().difference(request.createdAt);
    if (diff.inMinutes < 1) return context.tr('justNow');
    if (diff.inMinutes == 1) return context.tr('minuteAgo');
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${context.tr('minutesAgo')}';
    }
    return '${diff.inHours} ${context.tr('hoursAgo')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Pulsing red dot
              _PulsingDot(),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  request.patientName.isNotEmpty
                      ? request.patientName
                      : 'Anonymous',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                _waitingTime(context),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          if (request.patientSummary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              context.tr('assessmentSummary'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              request.patientSummary.length > 120
                  ? '${request.patientSummary.substring(0, 120)}...'
                  : request.patientSummary,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.connect_without_contact_rounded,
                  size: 18),
              label: Text(context.tr('acceptConnect')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 80).ms, duration: 300.ms)
        .slideY(begin: 0.08, end: 0);
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.error
              .withValues(alpha: 0.5 + (_ctrl.value * 0.5)),
        ),
      ),
    );
  }
}
