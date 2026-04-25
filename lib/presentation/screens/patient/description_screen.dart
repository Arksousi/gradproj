// description_screen.dart
// AI Emotional Support screen — sits between the assessment MCQ and final submission.
// Walks the patient through a 5-step conversational support flow powered by Groq.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../domain/providers/emotional_support_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

class DescriptionScreen extends ConsumerStatefulWidget {
  const DescriptionScreen({super.key});

  @override
  ConsumerState<DescriptionScreen> createState() => _DescriptionScreenState();
}

class _DescriptionScreenState extends ConsumerState<DescriptionScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _secondTextController = TextEditingController();

  // Local UI flags for timed reveals
  bool _submitted = false;
  bool _secondSubmitted = false;
  bool _followUpVisible = false;
  bool _helpQuestionVisible = false;
  bool _reactionsVisible = false;

  // Tracks the locally selected method card before "Show me" is pressed
  String? _localSelectedMethod;

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _secondTextController.dispose();
    super.dispose();
  }

  // ── Scroll ────────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 400,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
    });
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _handleShareWithAI() async {
    final text = _textController.text.trim();
    if (text.length < 20) return;
    setState(() => _submitted = true);
    await ref.read(emotionalSupportProvider.notifier).sendWelcomeRequest(text);
  }

  Future<void> _handleContinue() async {
    final text = _textController.text.trim();
    final esState = ref.read(emotionalSupportProvider);

    // Declined-help path — save support data before submitting
    if (esState.closingReaction == null) {
      await ref.read(emotionalSupportProvider.notifier).saveAndComplete(
            firstMessage: text,
            reaction: 'declined_help',
          );
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.patientDashboard, (route) => false);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final esState = ref.watch(emotionalSupportProvider);

    // React to step transitions
    ref.listen<EmotionalSupportState>(emotionalSupportProvider, (prev, next) {
      if (prev?.step == next.step) return;
      _scrollToBottom();

      // After welcome: show the second text input
      if (next.step == SupportStep.welcome) {
        Future.delayed(800.ms, () {
          if (!mounted) return;
          setState(() => _followUpVisible = true);
          _scrollToBottom();
        });
      }

      // After comfort: 1.5s pause, then reveal the help question
      if (next.step == SupportStep.comfort) {
        Future.delayed(1500.ms, () {
          if (!mounted) return;
          setState(() => _helpQuestionVisible = true);
          _scrollToBottom();
        });
      }

      if (next.step == SupportStep.noHelpClosing ||
          next.step == SupportStep.strugglingDone) {
        _scrollToBottom();
      }

      if (next.step == SupportStep.showMethod) {
        Future.delayed(2000.ms, () {
          if (!mounted) return;
          setState(() => _reactionsVisible = true);
          _scrollToBottom();
        });
      }
    });

    final isLoading = esState.isSaving;

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Saving your session...',
      child: Scaffold(
        body: Container(
          decoration:
              const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: SafeArea(
            child: Column(
              children: [
                _TopBar(onBack: () => Navigator.pop(context)),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildInputSection(esState),

                        // ── Step 1: loading welcome ─────────────────────────
                        if (esState.step == SupportStep.loadingWelcome)
                          const _LoadingBubble(
                              message: 'Reading your words carefully... 💙'),

                        // ── Step 1: welcome response ────────────────────────
                        if (esState.welcomeResponse != null)
                          _AIBubble(text: esState.welcomeResponse!),

                        // ── Second text input ───────────────────────────────
                        if (esState.welcomeResponse != null &&
                            _followUpVisible &&
                            !_secondSubmitted)
                          _buildSecondInputSection(),

                        // ── Divider before comfort step ─────────────────────
                        if (_secondSubmitted &&
                            (esState.step == SupportStep.loadingComfort ||
                                esState.comfortResponse != null))
                          const _StepDivider(),

                        // ── Step 1.5: loading comfort ───────────────────────
                        if (esState.step == SupportStep.loadingComfort)
                          const _LoadingBubble(
                              message:
                                  'Taking a moment to understand you... 🌿'),

                        // ── Step 1.5: comfort response ──────────────────────
                        if (esState.comfortResponse != null)
                          _ComfortBubble(text: esState.comfortResponse!),

                        // ── Step 2: help question ───────────────────────────
                        if (esState.comfortResponse != null &&
                            _helpQuestionVisible &&
                            esState.wantedHelp == null)
                          _buildHelpQuestion(),

                        // ── Declined path ───────────────────────────────────
                        if (esState.wantedHelp == false)
                          _buildDeclinedSection(esState, esState.isSaving),

                        // ── Step 3: method cards ────────────────────────────
                        if (esState.step == SupportStep.selectMethod)
                          _buildMethodCards(esState),

                        // ── Step 4: loading bubble ──────────────────────────
                        if (esState.step == SupportStep.loadingMethod)
                          const _LoadingBubble(
                              message:
                                  'Preparing something just for you... ✨'),

                        // ── Step 4: method response ─────────────────────────
                        if (esState.methodResponse != null)
                          _buildMethodResponseCard(esState),

                        // ── Step 5: closing reactions ───────────────────────
                        if (esState.methodResponse != null &&
                            _reactionsVisible &&
                            esState.closingReaction == null)
                          _buildReactions(),

                        // ── Post-reaction / continue ────────────────────────
                        if (esState.closingReaction != null)
                          _buildPostReaction(esState, esState.isSaving),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'How are you feeling?',
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(fontSize: 24),
            ),
            const SizedBox(width: 8),
            const Text('💙', style: TextStyle(fontSize: 22)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'This is a safe space. Write whatever is on your mind.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.08, duration: 400.ms);
  }

  Widget _buildInputSection(EmotionalSupportState state) {
    final locked = _submitted;
    final chars = _textController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: 400.ms,
          height: locked ? 90 : 200,
          decoration: BoxDecoration(
            color: locked ? AppColors.cardBackground : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: locked
                  ? AppColors.border.withValues(alpha: 0.5)
                  : AppColors.border,
            ),
          ),
          child: TextField(
            controller: _textController,
            readOnly: locked,
            maxLines: null,
            expands: true,
            maxLength: 500,
            textAlignVertical: TextAlignVertical.top,
            style: TextStyle(
              fontSize: 15,
              color:
                  locked ? AppColors.textSecondary : AppColors.textPrimary,
              height: 1.6,
            ),
            decoration: const InputDecoration(
              hintText: 'Share what\'s on your mind...',
              hintStyle:
                  TextStyle(color: AppColors.textHint, fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            locked ? '$chars characters shared' : '$chars / 500',
            style: TextStyle(
              fontSize: 12,
              color: (!locked && chars < 20)
                  ? AppColors.error
                  : AppColors.textHint,
            ),
          ),
        ),
        if (!locked) ...[
          const SizedBox(height: 14),
          _ShareButton(
            enabled: chars >= 20,
            onTap: _handleShareWithAI,
          ).animate().fadeIn(delay: 250.ms),
        ],
      ],
    ).animate().fadeIn(delay: 150.ms);
  }

  Future<void> _handleShareFollowUp() async {
    final firstMessage = _textController.text.trim();
    final secondMessage = _secondTextController.text.trim();
    if (secondMessage.length < 10) return;
    setState(() => _secondSubmitted = true);
    await ref.read(emotionalSupportProvider.notifier).submitFollowUp(
          firstMessage: firstMessage,
          secondMessage: secondMessage,
        );
  }

  Widget _buildSecondInputSection() {
    final chars = _secondTextController.text.length;
    final enabled = chars >= 10;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: 400.ms,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _secondTextController,
              maxLines: null,
              expands: true,
              maxLength: 500,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
              decoration: const InputDecoration(
                hintText: 'Tell me more... 💙',
                hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$chars / 500',
              style: TextStyle(
                fontSize: 12,
                color: !enabled ? AppColors.error : AppColors.textHint,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _ShareButton(
            label: 'Share 💙',
            enabled: enabled,
            onTap: _handleShareFollowUp,
          ).animate().fadeIn(delay: 250.ms),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, duration: 400.ms);
  }

  Widget _buildHelpQuestion() {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Would you like me to share something that might help you right now? 🌿',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ChoiceButton(
                  label: 'Yes, please',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.primary,
                  onTap: () {
                    ref
                        .read(emotionalSupportProvider.notifier)
                        .setWantedHelp(true, patientText: _textController.text.trim());
                    _scrollToBottom();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChoiceButton(
                  label: 'No, thank you',
                  icon: Icons.close_rounded,
                  color: AppColors.textSecondary,
                  onTap: () {
                    ref
                        .read(emotionalSupportProvider.notifier)
                        .setWantedHelp(false, patientText: _textController.text.trim());
                    _scrollToBottom();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, duration: 400.ms);
  }

  Widget _buildDeclinedSection(EmotionalSupportState esState, bool isSubmitting) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esState.step == SupportStep.loadingNoHelpClosing)
            const _LoadingBubble(message: 'Sending you off with care... 💙'),
          if (esState.noHelpResponse != null)
            _ComfortBubble(text: esState.noHelpResponse!),
          if (esState.step == SupportStep.noHelpClosing) ...[
            const SizedBox(height: 20),
            CustomButton(
              label: 'Continue 💙',
              onPressed: _handleContinue,
              isLoading: isSubmitting,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, duration: 400.ms);
  }

  Widget _buildMethodCards(EmotionalSupportState state) {
    const methods = [
      _MethodData('breathing', '🫁', 'Breathing Exercise',
          'A simple technique trusted by millions to calm your nervous system in minutes'),
      _MethodData('meditation', '🧘', 'Quick Meditation',
          'A short guided thought exercise to bring you back to the present moment'),
      _MethodData('reframing', '💭', 'Reframing Thought',
          'A gentle way to look at your situation from a different angle'),
      _MethodData('quotes', '📖', 'Healing Words',
          "A meaningful quote or saying that might speak to what you're feeling"),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What feels right for you in this moment?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...methods.map((m) {
            final selected = _localSelectedMethod == m.id;
            return GestureDetector(
              onTap: () {
                setState(() => _localSelectedMethod = m.id);
                ref
                    .read(emotionalSupportProvider.notifier)
                    .selectMethod(m.id);
              },
              child: AnimatedContainer(
                duration: 200.ms,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.07)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(m.emoji,
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 22),
                  ],
                ),
              ),
            );
          }),
          if (_localSelectedMethod != null) ...[
            const SizedBox(height: 4),
            CustomButton(
              label: 'Show me',
              onPressed: () => ref
                  .read(emotionalSupportProvider.notifier)
                  .fetchMethodGuidance(
                state.secondMessage != null && state.secondMessage!.isNotEmpty
                    ? '${_textController.text.trim()}\n\n${state.secondMessage}'
                    : _textController.text.trim(),
              ),
              icon: Icons.auto_awesome_rounded,
            ).animate().fadeIn(duration: 300.ms),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, duration: 400.ms);
  }

  Widget _buildMethodResponseCard(EmotionalSupportState state) {
    final method = state.selectedMethod ?? 'breathing';

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _methodGradient(method),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_methodEmoji(method),
                    style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Text(
                  _methodTitle(method),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2E2B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (method == 'breathing') ...[
              const _BreathingCircle(),
              const SizedBox(height: 20),
            ],
            Text(
              state.methodResponse ?? '',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF2D3748),
                height: 1.75,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.12, duration: 500.ms);
  }

  Widget _buildReactions() {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How are you feeling now? 🌿',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ReactionButton(
                  emoji: '😌',
                  label: 'A little better',
                  onTap: () => _saveReaction('a_little_better'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ReactionButton(
                  emoji: '💙',
                  label: 'I needed this',
                  onTap: () => _saveReaction('needed_this'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ReactionButton(
                  emoji: '😔',
                  label: 'Still struggling',
                  onTap: () => _saveReaction('still_struggling'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, duration: 400.ms);
  }

  Future<void> _saveReaction(String reaction) async {
    final firstMessage = _textController.text.trim();
    if (reaction == 'still_struggling') {
      await ref
          .read(emotionalSupportProvider.notifier)
          .saveAndFetchStrugglingResponse(firstMessage: firstMessage);
    } else {
      await ref.read(emotionalSupportProvider.notifier).saveAndComplete(
            firstMessage: firstMessage,
            reaction: reaction,
          );
    }
    _scrollToBottom();
  }

  Widget _buildPostReaction(
      EmotionalSupportState state, bool isSubmitting) {
    final isStruggling = state.closingReaction == 'still_struggling';

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isStruggling) ...[
            if (state.step == SupportStep.loadingStruggling)
              const _LoadingBubble(
                  message: 'Holding space for you right now... 💙'),
            if (state.strugglingResponse != null)
              _ComfortBubble(text: state.strugglingResponse!),
            const SizedBox(height: 20),
          ],
          if (!isStruggling || state.step == SupportStep.strugglingDone)
            CustomButton(
              label: 'Continue 💙',
              onPressed: _handleContinue,
              isLoading: isSubmitting,
              icon: Icons.arrow_forward_rounded,
            ).animate().fadeIn(duration: 500.ms),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<Color> _methodGradient(String method) {
    switch (method) {
      case 'breathing':
        return [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)];
      case 'meditation':
        return [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)];
      case 'reframing':
        return [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)];
      case 'quotes':
      default:
        return [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)];
    }
  }

  String _methodEmoji(String method) {
    switch (method) {
      case 'breathing':  return '🫁';
      case 'meditation': return '🧘';
      case 'reframing':  return '💭';
      case 'quotes':     return '📖';
      default:           return '✨';
    }
  }

  String _methodTitle(String method) {
    switch (method) {
      case 'breathing':  return 'Breathing Exercise';
      case 'meditation': return 'Quick Meditation';
      case 'reframing':  return 'Reframing Thought';
      case 'quotes':     return 'Healing Words';
      default:           return 'Guidance';
    }
  }
}

// ── Private widgets ─────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}

// Gradient share button — label defaults to the first-input wording
class _ShareButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  final String label;
  const _ShareButton({
    required this.enabled,
    required this.onTap,
    this.label = 'Share with AI 💙',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: 200.ms,
        height: 52,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: enabled ? null : AppColors.border,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? Colors.white : AppColors.textHint,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// Pulsing AI thinking bubble
class _LoadingBubble extends StatelessWidget {
  final String message;
  const _LoadingBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AIAvatar(),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: const Color(0xFFD4DCF7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(message,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF4A5568))),
                  ),
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF667EEA)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, duration: 350.ms);
  }
}

// AI response chat bubble
class _AIBubble extends StatelessWidget {
  final String text;
  const _AIBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AIAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEEF2FF), Color(0xFFF5F0FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: const Color(0xFFD4DCF7)),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF2D3748),
                  height: 1.7,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.12, duration: 450.ms);
  }
}

// Purple gradient avatar for the AI companion
class _AIAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.psychology_rounded,
          color: Colors.white, size: 18),
    );
  }
}

// Yes / No choice buttons
class _ChoiceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ChoiceButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// Emoji reaction button
class _ReactionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _ReactionButton(
      {required this.emoji,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Animated breathing circle for the Breathing Exercise method card
class _BreathingCircle extends StatefulWidget {
  const _BreathingCircle();

  @override
  State<_BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<_BreathingCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  String _phase = 'Inhale';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4));
    _scale = Tween<double>(begin: 0.55, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _ctrl.addStatusListener((status) {
      if (!mounted) return;
      if (status == AnimationStatus.completed) {
        setState(() => _phase = 'Exhale');
        _ctrl.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() => _phase = 'Inhale');
        _ctrl.forward();
      }
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _scale,
            builder: (_, __) => Container(
              width: 110 * _scale.value,
              height: 110 * _scale.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF90CAF9),
                    const Color(0xFF42A5F5).withValues(alpha: 0.35),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF42A5F5)
                        .withValues(alpha: 0.25 * _scale.value),
                    blurRadius: 20,
                    spreadRadius: 4,
                  )
                ],
              ),
              child: Center(
                child: Text(
                  _phase,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '4 seconds each',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// Soft divider between the welcome bubble and the comfort bubble
class _StepDivider extends StatelessWidget {
  const _StepDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFFE8D5F5).withValues(alpha: 0.6),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('🌿', style: TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFFE8D5F5).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

// Warm amber→lavender comfort analysis bubble
class _ComfortBubble extends StatelessWidget {
  final String text;
  const _ComfortBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ComfortAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF8F0), Color(0xFFFAF0FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: const Color(0xFFE8D5F5)),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF3D2B52),
                  height: 1.75,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.12, duration: 500.ms);
  }
}

// Amber→purple heart avatar for the comfort bubble
class _ComfortAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFB347), Color(0xFFB266FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
    );
  }
}

// Data class for method cards — no logic, just labels
class _MethodData {
  final String id;
  final String emoji;
  final String title;
  final String description;
  const _MethodData(this.id, this.emoji, this.title, this.description);
}
