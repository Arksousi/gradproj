// chatbot_screen.dart
// Private AI chatbot replacing the old "Describe Your Feelings" screen.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/chatbot_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/models/chat_session_model.dart';
import '../../../data/models/user_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/chatbot_provider.dart';
import '../../../domain/providers/patient_provider.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  String? _sessionId;
  bool _isLoading = false; // AI is typing
  bool _sessionEnded = false;
  bool _showLimitCard = false;
  bool _initError = false;
  bool _backendOffline = false; // backend unreachable banner
  String? _lastFailedMessage; // stored so user can retry
  int _messageCount = 0;
  String _locale = 'en';

  // Conversation history sent to backend (role/content pairs)
  final List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Initialise session ────────────────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locale = Localizations.localeOf(context).languageCode;
  }

  Future<void> _init() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _initError = false;
      _backendOffline = false;
    });

    // Check backend reachability first so we can warn the user early.
    final backendOk = await ChatbotService.instance.isBackendAvailable();
    if (!mounted) return;
    if (!backendOk) {
      setState(() {
        _backendOffline = true;
        _isLoading = false;
        _initError = false; // session can still load from Firestore
      });
    }

    try {
      // Wait for auth — retry up to 3s if user not yet loaded
      UserModel? user;
      for (var i = 0; i < 6; i++) {
        user = ref.read(currentUserProvider);
        if (user != null) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }
      if (user == null) throw Exception('Not signed in');

      final patient = ref.read(currentPatientProvider).value;

      final session = await ChatbotService.instance.getOrCreateTodaySession(
        patientId: user.uid,
        therapistId: patient?.therapistId ?? '',
      );

      if (!mounted) return;
      _sessionId = session.sessionId;
      _messageCount = session.messageCount;

      // Load existing history for backend context
      final existingMessages =
          await ChatbotService.instance.getMessages(session.sessionId).first;

      for (final msg in existingMessages) {
        _history.add({
          'role': msg.messageRole == MessageRole.patient ? 'user' : 'assistant',
          'content': msg.content,
        });
      }

      // Fresh session + backend available → send opening AI message
      if (existingMessages.isEmpty && patient != null && backendOk) {
        final opening = await ChatbotService.instance.sendOpeningMessage(
          sessionId: session.sessionId,
          patient: patient,
          locale: _locale,
        );
        _history.add({'role': 'assistant', 'content': opening});
      }
    } catch (e) {
      debugPrint('[ChatbotScreen] init error: $e');
      if (mounted) setState(() => _initError = true);
    }

    if (mounted) setState(() => _isLoading = false);
    _scrollToBottom();
  }

  // ── Send message ──────────────────────────────────────────────────────────

  Future<void> _sendMessage([String? retryText]) async {
    final text = retryText ?? _textController.text.trim();
    if (text.isEmpty || _isLoading || _sessionEnded || _sessionId == null) {
      return;
    }

    final patient = ref.read(currentPatientProvider).value;
    final user = ref.read(currentUserProvider);
    if (patient == null || user == null) return;

    if (retryText == null) _textController.clear();
    setState(() {
      _isLoading = true;
      _lastFailedMessage = null;
      _backendOffline = false;
    });

    // Send only the last 20 messages to keep payload bounded
    final historySnapshot = _history.length > 20
        ? _history.sublist(_history.length - 20)
        : List<Map<String, dynamic>>.from(_history);

    try {
      final result = await ChatbotService.instance.sendMessage(
        sessionId: _sessionId!,
        patientMessage: text,
        history: historySnapshot,
        messageCount: _messageCount,
        patient: patient,
        locale: _locale,
      );

      if (!result.success) {
        // Backend was reachable but Groq failed — show offline banner + retry
        setState(() {
          _backendOffline = true;
          _lastFailedMessage = text;
        });
        if (mounted) setState(() => _isLoading = false);
        _scrollToBottom();
        return;
      }

      _messageCount += 1;

      // Update local history
      _history.add({'role': 'user', 'content': text});
      _history.add({'role': 'assistant', 'content': result.aiResponse});

      // Handle red flag
      if (result.isRedFlag) {
        await _handleRedFlag(
          flaggedMessage: text,
          severity: result.severity,
          patient: patient,
          therapistId: patient.therapistId,
        );
      }

      // Check 20-message limit
      if (_messageCount >= 20) {
        setState(() {
          _sessionEnded = true;
          _showLimitCard = true;
        });
      }
    } catch (e) {
      debugPrint('[ChatbotScreen] sendMessage error: $e');
      setState(() {
        _backendOffline = true;
        _lastFailedMessage = text;
      });
    }

    if (mounted) setState(() => _isLoading = false);
    _scrollToBottom();
  }

  // ── Red flag handling ─────────────────────────────────────────────────────

  Future<void> _handleRedFlag({
    required String flaggedMessage,
    required String severity,
    required dynamic patient,
    required String therapistId,
  }) async {
    // Take last 4 messages from history for context
    final lastFour = _history.length >= 4
        ? _history.sublist(_history.length - 4)
        : List<Map<String, dynamic>>.from(_history);

    // Create alert in Firestore and generate AI summary
    await ChatbotService.instance.createRedFlagAlert(
      sessionId: _sessionId!,
      patientId: patient.uid as String,
      patientName: patient.name as String,
      therapistId: therapistId,
      flaggedMessage: flaggedMessage,
      lastFourMessages: lastFour,
      severity: severity,
    );

    // Push notification to therapist
    if (therapistId.isNotEmpty) {
      final token = await _getTherapistToken(therapistId);
      if (token != null) {
        await NotificationService.instance.sendRedFlagNotification(
          token: token,
          patientName: patient.name as String,
        );
      }
    }
  }

  Future<String?> _getTherapistToken(String therapistId) =>
      ChatbotService.instance.getTherapistFcmToken(therapistId);

  // ── Scroll ────────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Confirm exit ──────────────────────────────────────────────────────────

  Future<bool> _confirmExit() async {
    if (_sessionEnded) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('endChatTitle')),
        content: Text(context.tr('endChatBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('stayHere')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('endChat')),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_sessionId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: _initError
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        color: AppColors.textHint, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('chatbotInitError'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _init,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(context.tr('retry')),
                    ),
                  ],
                )
              : const CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final messagesAsync =
        ref.watch(chatMessagesProvider(_sessionId!));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmExit()) {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 1,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('chatbotTitle'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    context.tr('chatbotSubtitle'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            if (_messageCount >= 10)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Center(
                  child: Text(
                    '$_messageCount/20',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: AppColors.textSecondary),
              onPressed: () async {
                if (await _confirmExit()) {
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Backend offline banner
            if (_backendOffline)
              _OfflineBanner(
                onRetry: _lastFailedMessage != null
                    ? () => _sendMessage(_lastFailedMessage)
                    : _init,
                hasFailedMessage: _lastFailedMessage != null,
              ),

            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isNotEmpty) _scrollToBottom();
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == messages.length && _isLoading) {
                        return const _TypingIndicator();
                      }
                      return _MessageBubble(message: messages[i]);
                    },
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
                error: (e, _) =>
                    Center(child: Text(e.toString())),
              ),
            ),

            // 20-message limit card
            if (_showLimitCard)
              _LimitCard(
                onOpenTherapistChat: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.patientDashboard,
                    (_) => false,
                  );
                },
                onOkay: () async {
                  if (_sessionId != null) {
                    await ChatbotService.instance.endSession(_sessionId!);
                  }
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.patientDashboard,
                      (_) => false,
                    );
                  }
                },
              ),

            // Input bar (hidden when session ended)
            if (!_sessionEnded)
              _InputBar(
                controller: _textController,
                onSend: _sendMessage,
                isLoading: _isLoading,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isPatient = message.messageRole == MessageRole.patient;
    return Align(
      alignment:
          isPatient ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isPatient) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded,
                  color: Colors.white, size: 14),
            ),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: isPatient ? AppColors.primaryGradient : null,
                color: isPatient ? null : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isPatient ? 18 : 4),
                  bottomRight: Radius.circular(isPatient ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isPatient
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04, end: 0);
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded,
                color: Colors.white, size: 14),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => Container(
                    width: 7,
                    height: 7,
                    margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                          alpha: ((i * 0.2 + 0.3) * _anim.value)
                              .clamp(0.0, 1.0)),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: context.tr('chatbotInputHint'),
                hintStyle: const TextStyle(
                    color: AppColors.textHint, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: isLoading ? null : AppColors.primaryGradient,
              color: isLoading ? AppColors.border : null,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: isLoading ? null : onSend,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 20-message limit card ─────────────────────────────────────────────────────

class _LimitCard extends StatelessWidget {
  final VoidCallback onOpenTherapistChat;
  final VoidCallback onOkay;

  const _LimitCard({
    required this.onOpenTherapistChat,
    required this.onOkay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.favorite_rounded,
              color: AppColors.primary, size: 36),
          const SizedBox(height: 12),
          Text(
            context.tr('chatbotLimitTitle'),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('chatbotLimitBody'),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpenTherapistChat,
              icon: const Icon(Icons.chat_rounded, size: 16),
              label: Text(context.tr('chatbotLimitYes')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onOkay,
            child: Text(
              context.tr('chatbotLimitNo'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _OfflineBanner extends StatelessWidget {
  final VoidCallback onRetry;
  final bool hasFailedMessage;

  const _OfflineBanner({required this.onRetry, required this.hasFailedMessage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.error.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasFailedMessage
                  ? 'AI is unavailable. Tap retry to resend.'
                  : 'Could not reach AI server. Check your connection.',
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              context.tr('retry'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
