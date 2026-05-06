// chatbot_provider.dart
// Riverpod providers for the AI chatbot feature.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/chatbot_service.dart';
import '../../data/models/chat_session_model.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final chatbotServiceProvider = Provider<ChatbotService>(
  (_) => ChatbotService.instance,
);

// ── Messages stream ───────────────────────────────────────────────────────────

final chatMessagesProvider =
    StreamProvider.autoDispose.family<List<ChatMessageModel>, String>(
  (ref, sessionId) =>
      ref.read(chatbotServiceProvider).getMessages(sessionId),
);

// ── Active session stream ─────────────────────────────────────────────────────

final activeChatSessionProvider =
    StreamProvider.autoDispose.family<ChatSessionModel?, String>(
  (ref, sessionId) =>
      ref.read(chatbotServiceProvider).watchSession(sessionId),
);

// ── Red flag alerts stream (therapist) ───────────────────────────────────────

final redFlagAlertsProvider =
    StreamProvider.autoDispose.family<List<RedFlagAlertModel>, String>(
  (ref, therapistId) =>
      ref.read(chatbotServiceProvider).streamRedFlagAlerts(therapistId),
);

// ── Unread alert count (therapist badge) ─────────────────────────────────────

final unreadAlertsCountProvider =
    StreamProvider.autoDispose.family<int, String>(
  (ref, therapistId) =>
      ref.read(chatbotServiceProvider).streamUnreadAlertsCount(therapistId),
);
