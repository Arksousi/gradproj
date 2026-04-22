// chat_screen.dart
// Real-time chat screen between patient and therapist.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/therapist_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _sessionId;
  late String _therapistId;
  bool _sessionEndedHandled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    _sessionId = args?['sessionId'] ?? '';
    _therapistId = args?['therapistId'] ?? '';
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(currentUserProvider);
    _textController.clear();
    ref.read(chatRepositoryProvider).sendMessage(
          sessionId: _sessionId,
          senderId: user?.uid ?? '',
          senderRole: 'patient',
          text: text,
        );
    _scrollToBottom();
  }

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

  void _endSession() {
    ref.read(chatRepositoryProvider).endSession(_sessionId);
  }

  void _showPostSessionSheet(TherapistModel? therapist) {
    if (_sessionEndedHandled) return;
    _sessionEndedHandled = true;
    // _therapistId is available here for future therapist profile lookup
    debugPrint('Session ended for therapist: $_therapistId');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PostSessionSheet(
        therapist: therapist,
        onBook: () {
          Navigator.pop(ctx);
          if (therapist != null) {
            Navigator.pushNamed(
              context,
              AppRoutes.bookingConsent,
              arguments: therapist,
            );
          }
        },
        onDecideLater: () {
          Navigator.pop(ctx);
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.patientDashboard, (_) => false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(chatSessionProvider(_sessionId));
    final messagesAsync = ref.watch(chatMessagesProvider(_sessionId));
    final user = ref.watch(currentUserProvider);

    return sessionAsync.when(
      data: (session) {
        final isEnded = session?.status == 'ended';

        if (isEnded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPostSessionSheet(null);
          });
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('yourTherapist'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  isEnded
                      ? context.tr('sessionEnded')
                      : context.tr('sessionActive'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isEnded ? AppColors.error : AppColors.success,
                  ),
                ),
              ],
            ),
            actions: [
              if (!isEnded)
                TextButton(
                  onPressed: _endSession,
                  child: Text(
                    context.tr('endSession'),
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              if (isEnded) _EndedBanner(context: context),
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isNotEmpty) {
                      _scrollToBottom();
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (ctx, i) => _MessageBubble(
                        message: messages[i],
                        isMe: messages[i].senderId == user?.uid,
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text(e.toString())),
                ),
              ),
              if (!isEnded) _InputBar(
                controller: _textController,
                onSend: _sendMessage,
                hint: context.tr('typeMessage'),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text(e.toString())),
      ),
    );
  }
}

class _EndedBanner extends StatelessWidget {
  final BuildContext context;
  const _EndedBanner({required this.context});

  @override
  Widget build(BuildContext outerContext) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.error.withValues(alpha: 0.08),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              outerContext.tr('sessionEnded'),
              style: const TextStyle(
                  color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isMe ? Colors.white : AppColors.textPrimary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0);
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final String hint;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.hint,
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
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                    color: AppColors.textHint, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostSessionSheet extends StatelessWidget {
  final TherapistModel? therapist;
  final VoidCallback onBook;
  final VoidCallback onDecideLater;

  const _PostSessionSheet({
    required this.therapist,
    required this.onBook,
    required this.onDecideLater,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.favorite_rounded,
                color: AppColors.primary, size: 48),
            const SizedBox(height: 16),
            Text(
              context.tr('howDidItFeel'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('bookFollowUp'),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBook,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.tr('yesBook'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onDecideLater,
              child: Text(
                context.tr('noDecideLater'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
