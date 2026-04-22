// chat_provider.dart
// Riverpod providers for immediate chat flow and real-time session state.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/chat_model.dart';
import '../../data/repositories/chat_repository.dart';

class ImmediateChatState {
  final String status; // 'idle' | 'creating' | 'waiting' | 'accepted' | 'error'
  final String? requestId;
  final String? sessionId;
  final String? therapistId;
  final String? errorMessage;

  const ImmediateChatState({
    this.status = 'idle',
    this.requestId,
    this.sessionId,
    this.therapistId,
    this.errorMessage,
  });

  ImmediateChatState copyWith({
    String? status,
    String? requestId,
    String? sessionId,
    String? therapistId,
    String? errorMessage,
  }) =>
      ImmediateChatState(
        status: status ?? this.status,
        requestId: requestId ?? this.requestId,
        sessionId: sessionId ?? this.sessionId,
        therapistId: therapistId ?? this.therapistId,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class ImmediateChatNotifier extends StateNotifier<ImmediateChatState> {
  final ChatRepository _repo;
  StreamSubscription<ImmediateRequest?>? _sub;

  ImmediateChatNotifier(this._repo) : super(const ImmediateChatState());

  Future<void> requestImmediate({
    required String patientId,
    required String patientName,
    required String patientSummary,
    required String clinicalReport,
  }) async {
    state = state.copyWith(status: 'creating');
    try {
      final available = await _repo.findAvailableTherapist();
      if (available != null) {
        final sessionId = await _repo.createSession(
          patientId: patientId,
          therapistId: available.uid,
          patientSummary: patientSummary,
          clinicalReport: clinicalReport,
        );
        state = state.copyWith(
          status: 'accepted',
          sessionId: sessionId,
          therapistId: available.uid,
        );
        return;
      }
      final requestId = await _repo.createImmediateRequest(
        patientId: patientId,
        patientName: patientName,
        patientSummary: patientSummary,
        clinicalReport: clinicalReport,
      );
      state = state.copyWith(status: 'waiting', requestId: requestId);
      _sub = _repo.watchRequest(requestId).listen((req) {
        if (req?.status == 'accepted' && req?.chatSessionId != null) {
          state = state.copyWith(
            status: 'accepted',
            sessionId: req!.chatSessionId,
            therapistId: req.acceptedByTherapistId,
          );
          _sub?.cancel();
        }
      });
    } catch (e) {
      state = state.copyWith(status: 'error', errorMessage: e.toString());
    }
  }

  void reset() {
    _sub?.cancel();
    state = const ImmediateChatState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final immediateChatProvider = StateNotifierProvider.autoDispose<
    ImmediateChatNotifier, ImmediateChatState>(
  (ref) => ImmediateChatNotifier(ref.read(chatRepositoryProvider)),
);

final chatSessionProvider =
    StreamProvider.autoDispose.family<ChatSession?, String>(
  (ref, sessionId) => ref.read(chatRepositoryProvider).watchSession(sessionId),
);

final chatMessagesProvider =
    StreamProvider.autoDispose.family<List<ChatMessage>, String>(
  (ref, sessionId) =>
      ref.read(chatRepositoryProvider).watchMessages(sessionId),
);

final pendingImmediateRequestsProvider =
    StreamProvider.autoDispose<List<ImmediateRequest>>(
  (ref) => ref.read(chatRepositoryProvider).streamPendingRequests(),
);
