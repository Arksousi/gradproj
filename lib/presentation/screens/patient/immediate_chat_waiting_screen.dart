// immediate_chat_waiting_screen.dart
// Shown while waiting for a therapist to accept the immediate chat request.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/chat_provider.dart';
import '../../../domain/providers/patient_provider.dart';

class ImmediateChatWaitingScreen extends ConsumerStatefulWidget {
  const ImmediateChatWaitingScreen({super.key});

  @override
  ConsumerState<ImmediateChatWaitingScreen> createState() =>
      _ImmediateChatWaitingScreenState();
}

class _ImmediateChatWaitingScreenState
    extends ConsumerState<ImmediateChatWaitingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _initiated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    // Defer to first build so context args are available
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRequest());
  }

  void _startRequest() {
    if (_initiated) return;
    _initiated = true;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    final user = ref.read(currentUserProvider);
    final patient = ref.read(currentPatientProvider).value;

    ref.read(immediateChatProvider.notifier).requestImmediate(
          patientId: user?.uid ?? '',
          patientName: user?.name ?? '',
          patientSummary: args?['patientSummary'] ??
              patient?.description ??
              '',
          clinicalReport: args?['clinicalReport'] ?? '',
        );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(immediateChatProvider);

    // Navigate when accepted
    ref.listen<ImmediateChatState>(immediateChatProvider, (_, next) {
      if (next.status == 'accepted' && next.sessionId != null) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.chat,
          arguments: {
            'sessionId': next.sessionId!,
            'therapistId': next.therapistId ?? '',
          },
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing heart
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale =
                        1.0 + (_pulseController.value * 0.15);
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  context.tr('connectingNow'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.dark,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 16),

                Text(
                  context.tr('holdOn'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 40),

                if (chatState.status == 'error') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      chatState.errorMessage ?? context.tr('error'),
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  // Animated dots
                  _WaitingDots().animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 40),
                ],

                TextButton.icon(
                  onPressed: () {
                    ref.read(immediateChatProvider.notifier).reset();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(context.tr('cancel')),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaitingDots extends StatefulWidget {
  @override
  State<_WaitingDots> createState() => _WaitingDotsState();
}

class _WaitingDotsState extends State<_WaitingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final frame = (_controller.value * 4).floor() % 4;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= frame
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.2),
              ),
            );
          }),
        );
      },
    );
  }
}
