// chatbot_service.dart
// All AI chatbot logic. Flutter NEVER calls Groq directly —
// every call goes through the Python FastAPI backend.

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';
import '../../data/models/chat_session_model.dart';
import '../../data/models/patient_model.dart';
import '../constants/app_constants.dart';

// Backend URL and timeout come from AppConstants (configurable via --dart-define).
const String kPythonBackendUrl = AppConstants.backendUrl;
const Duration _kTimeout = AppConstants.httpTimeout;

class ChatbotService {
  ChatbotService._();
  static final ChatbotService instance = ChatbotService._();

  final FirebaseFirestore _db = FirebaseService.instance.firestore;
  final _uuid = const Uuid();

  // ── Session management ────────────────────────────────────────────────────

  Future<ChatSessionModel> createSession({
    required String patientId,
    required String therapistId,
  }) async {
    final id = _uuid.v4();
    final session = ChatSessionModel(
      sessionId: id,
      patientId: patientId,
      therapistId: therapistId,
      startedAt: DateTime.now(),
      messageCount: 0,
      status: 'active',
      redFlagTriggered: false,
    );
    await _db.collection('chatSessions').doc(id).set(session.toMap());
    return session;
  }

  /// Returns today's active session for the patient, or creates a new one.
  /// Single-field query only — no composite index required.
  Future<ChatSessionModel> getOrCreateTodaySession({
    required String patientId,
    required String therapistId,
  }) async {
    final today = DateTime.now();

    // Single equality filter — works without any composite index.
    final snap = await _db
        .collection('chatSessions')
        .where('patientId', isEqualTo: patientId)
        .limit(10)
        .get();

    // Filter client-side for active + today
    for (final doc in snap.docs) {
      final session = ChatSessionModel.fromMap(doc.id, doc.data());
      if (session.sessionStatus == ChatSessionStatus.active &&
          session.startedAt.year == today.year &&
          session.startedAt.month == today.month &&
          session.startedAt.day == today.day) {
        return session;
      }
    }

    return createSession(patientId: patientId, therapistId: therapistId);
  }

  Future<void> endSession(String sessionId) async {
    await _db.collection('chatSessions').doc(sessionId).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<ChatSessionModel?> watchSession(String sessionId) {
    return _db
        .collection('chatSessions')
        .doc(sessionId)
        .snapshots()
        .map((snap) => snap.exists
            ? ChatSessionModel.fromMap(snap.id, snap.data()!)
            : null);
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  Stream<List<ChatMessageModel>> getMessages(String sessionId) {
    return _db
        .collection('chatSessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessageModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<String> _saveMessage({
    required String sessionId,
    required String role,
    required String content,
    bool isRedFlag = false,
  }) async {
    final id = _uuid.v4();
    final msg = ChatMessageModel(
      messageId: id,
      role: role,
      content: content,
      timestamp: DateTime.now(),
      isRedFlag: isRedFlag,
    );
    await _db
        .collection('chatSessions')
        .doc(sessionId)
        .collection('messages')
        .doc(id)
        .set(msg.toMap());
    return id;
  }

  Future<void> _incrementMessageCount(
      String sessionId, int newCount) async {
    await _db
        .collection('chatSessions')
        .doc(sessionId)
        .update({'messageCount': newCount});
  }

  // ── Send message (main flow) ──────────────────────────────────────────────

  /// Returns true if the backend is reachable.
  Future<bool> isBackendAvailable() async {
    try {
      final resp = await http
          .get(Uri.parse('$kPythonBackendUrl/health'))
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Sends a patient message, calls the backend for an AI reply,
  /// and runs red-flag detection in parallel.
  /// [success] is false when the backend was unreachable.
  Future<({String aiResponse, bool isRedFlag, String severity, bool success})> sendMessage({
    required String sessionId,
    required String patientMessage,
    required List<Map<String, dynamic>> history,
    required int messageCount,
    required PatientModel patient,
    String locale = 'en',
  }) async {
    // Save patient message
    await _saveMessage(
      sessionId: sessionId,
      role: 'patient',
      content: patientMessage,
    );

    final newCount = messageCount + 1;
    await _incrementMessageCount(sessionId, newCount);

    // Build patient context
    final patientContext = _buildPatientContext(patient, locale: locale);

    // Fire chat + red-flag in parallel
    final results = await Future.wait([
      _callChat(
        patientMessage: patientMessage,
        history: history,
        messageCount: newCount,
        patientContext: patientContext,
        sessionId: sessionId,
      ),
      _callRedFlag(
        patientMessage: patientMessage,
        history: history,
        sessionId: sessionId,
      ),
    ]);

    final aiResponse = results[0] as String;
    final redFlagResult = results[1] as Map<String, dynamic>;
    final isRedFlag = redFlagResult['isRedFlag'] as bool? ?? false;
    final severity = redFlagResult['severity'] as String? ?? 'none';
    final success = aiResponse != _fallbackMsg;

    // Save AI reply
    await _saveMessage(
      sessionId: sessionId,
      role: 'ai',
      content: aiResponse,
      isRedFlag: isRedFlag,
    );

    return (aiResponse: aiResponse, isRedFlag: isRedFlag, severity: severity, success: success);
  }

  /// Sends the opening message (empty patient input, messageCount = 0).
  Future<String> sendOpeningMessage({
    required String sessionId,
    required PatientModel patient,
    String locale = 'en',
  }) async {
    final patientContext = _buildPatientContext(patient, locale: locale);
    const openingMessage =
        'Hello, I just opened the chat and would like to talk.';

    final aiResponse = await _callChat(
      patientMessage: openingMessage,
      history: const [],
      messageCount: 0,
      patientContext: patientContext,
      sessionId: sessionId,
    );

    await _saveMessage(sessionId: sessionId, role: 'ai', content: aiResponse);
    return aiResponse;
  }

  // ── Red flag alert ────────────────────────────────────────────────────────

  Future<void> createRedFlagAlert({
    required String sessionId,
    required String patientId,
    required String patientName,
    required String therapistId,
    required String flaggedMessage,
    required List<Map<String, dynamic>> lastFourMessages,
    required String severity,
  }) async {
    // Generate context summary from Python backend
    final summary = await generateContextSummary(
      flaggedMessage: flaggedMessage,
      lastFourMessages: lastFourMessages,
      patientName: patientName,
    );

    final context = lastFourMessages
        .map((m) =>
            '${(m['role'] as String).toUpperCase()}: ${m['content'] as String}')
        .join('\n');

    final alertId = _uuid.v4();
    final alert = RedFlagAlertModel(
      alertId: alertId,
      patientId: patientId,
      patientName: patientName,
      therapistId: therapistId,
      flaggedMessage: flaggedMessage,
      conversationContext: context,
      aiContextSummary: summary,
      triggeredAt: DateTime.now(),
      status: 'unread',
      severity: severity,
    );

    await Future.wait([
      _db
          .collection('redFlagAlerts')
          .doc(alertId)
          .set(alert.toMap()),
      _db
          .collection('chatSessions')
          .doc(sessionId)
          .update({'status': 'flagged', 'redFlagTriggered': true}),
    ]);
  }

  Stream<List<RedFlagAlertModel>> streamRedFlagAlerts(String therapistId) {
    return _db
        .collection('redFlagAlerts')
        .where('therapistId', isEqualTo: therapistId)
        .orderBy('triggeredAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RedFlagAlertModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<String?> getTherapistFcmToken(String therapistId) async {
    try {
      final snap =
          await _db.collection('users').doc(therapistId).get();
      return snap.data()?['fcmToken'] as String?;
    } catch (_) {
      return null;
    }
  }

  Stream<int> streamUnreadAlertsCount(String therapistId) {
    return _db
        .collection('redFlagAlerts')
        .where('therapistId', isEqualTo: therapistId)
        .where('status', isEqualTo: 'unread')
        .snapshots()
        .map((snap) => snap.size);
  }

  Future<void> markAlertRead(String alertId) async {
    await _db
        .collection('redFlagAlerts')
        .doc(alertId)
        .update({'status': 'read'});
  }

  // ── HTTP helpers ──────────────────────────────────────────────────────────

  static const String _fallbackMsg =
      "I'm having a moment. Give me a second and try again. 💙";

  Future<String> _callChat({
    required String patientMessage,
    required List<Map<String, dynamic>> history,
    required int messageCount,
    required Map<String, dynamic> patientContext,
    required String sessionId,
  }) async {
    final body = jsonEncode({
      'patientMessage': patientMessage,
      'conversationHistory': history,
      'messageCount': messageCount,
      'patientContext': patientContext,
      'sessionId': sessionId,
    });

    // One automatic retry on transient failure.
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final resp = await http
            .post(
              Uri.parse('$kPythonBackendUrl/chat'),
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(_kTimeout);

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          // Backend signals groq_unavailable via null response field.
          if (data['error'] == 'groq_unavailable' || data['response'] == null) {
            debugPrint('[ChatbotService] /chat: backend groq_unavailable');
            return _fallbackMsg;
          }
          return data['response'] as String;
        }
        debugPrint('[ChatbotService] /chat HTTP ${resp.statusCode} attempt $attempt');
      } catch (e) {
        debugPrint('[ChatbotService] /chat error attempt $attempt: $e');
        if (attempt == 0) await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    return _fallbackMsg;
  }

  Future<Map<String, dynamic>> _callRedFlag({
    required String patientMessage,
    required List<Map<String, dynamic>> history,
    required String sessionId,
  }) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$kPythonBackendUrl/red-flag'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'patientMessage': patientMessage,
              'conversationHistory': history,
              'sessionId': sessionId,
            }),
          )
          .timeout(_kTimeout);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data['serviceError'] == true) {
          debugPrint('[ChatbotService] /red-flag: backend reported serviceError — crisis check unreliable for this message');
        }
        return data;
      }
      debugPrint('[ChatbotService] /red-flag HTTP ${resp.statusCode}');
      return {'isRedFlag': false, 'severity': 'none', 'serviceError': true};
    } catch (e) {
      debugPrint('[ChatbotService] /red-flag network error: $e');
      return {'isRedFlag': false, 'severity': 'none', 'serviceError': true};
    }
  }

  Future<String> generateContextSummary({
    required String flaggedMessage,
    required List<Map<String, dynamic>> lastFourMessages,
    required String patientName,
  }) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$kPythonBackendUrl/context-summary'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'flaggedMessage': flaggedMessage,
              'lastFourMessages': lastFourMessages,
              'patientName': patientName,
            }),
          )
          .timeout(_kTimeout);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data['summary'] as String? ?? '';
      }
      return '';
    } catch (e) {
      debugPrint('[ChatbotService] /context-summary error: $e');
      return '';
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _buildPatientContext(PatientModel patient,
      {String locale = 'en'}) {
    final dsm5Flags = _deriveDsm5Flags(patient.assessment);
    return {
      'goals': dsm5Flags,
      'dsm5Flags': dsm5Flags,
      'language': locale == 'ar' ? 'Arabic' : 'English',
    };
  }

  List<String> _deriveDsm5Flags(List<int> assessment) {
    if (assessment.isEmpty) return [];
    const domainMap = {
      'Anxiety & Worry': [0, 1, 2, 3, 4],
      'Depression & Low Mood': [5, 6, 7, 8, 9],
      'Sleep Problems': [10, 11, 12, 13, 14],
      'Trauma & Stress': [15, 16, 17, 18, 19],
      'Anger & Irritability': [20, 21, 22, 23, 24],
      'Concentration & Memory': [25, 26, 27, 28, 29],
    };
    const threshold = 6;
    final flags = <String>[];
    domainMap.forEach((domain, indices) {
      final score = indices
          .where((i) => i < assessment.length)
          .fold<int>(0, (acc, i) => acc + assessment[i]);
      if (score >= threshold) flags.add(domain);
    });
    return flags;
  }
}
