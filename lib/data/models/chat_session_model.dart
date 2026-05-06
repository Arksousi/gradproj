import 'package:cloud_firestore/cloud_firestore.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────
// Stored as strings in Firestore; use the typed getters below instead of
// comparing raw strings to avoid silent typo bugs.

enum ChatSessionStatus { active, ended, flagged }

enum MessageRole { patient, ai }

enum AlertSeverity { high, critical }

enum AlertStatus { unread, read }

// ── Models ────────────────────────────────────────────────────────────────────

class ChatSessionModel {
  final String sessionId;
  final String patientId;
  final String therapistId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int messageCount;
  final String status; // Firestore string — use sessionStatus getter
  final bool redFlagTriggered;

  const ChatSessionModel({
    required this.sessionId,
    required this.patientId,
    required this.therapistId,
    required this.startedAt,
    this.endedAt,
    required this.messageCount,
    required this.status,
    required this.redFlagTriggered,
  });

  ChatSessionStatus get sessionStatus => ChatSessionStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => ChatSessionStatus.active,
      );

  factory ChatSessionModel.fromMap(String id, Map<String, dynamic> map) =>
      ChatSessionModel(
        sessionId: id,
        patientId: map['patientId'] as String? ?? '',
        therapistId: map['therapistId'] as String? ?? '',
        startedAt:
            (map['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        endedAt: (map['endedAt'] as Timestamp?)?.toDate(),
        messageCount: map['messageCount'] as int? ?? 0,
        status: map['status'] as String? ?? ChatSessionStatus.active.name,
        redFlagTriggered: map['redFlagTriggered'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'patientId': patientId,
        'therapistId': therapistId,
        'startedAt': Timestamp.fromDate(startedAt),
        if (endedAt != null) 'endedAt': Timestamp.fromDate(endedAt!),
        'messageCount': messageCount,
        'status': status,
        'redFlagTriggered': redFlagTriggered,
      };

  ChatSessionModel copyWith({
    int? messageCount,
    String? status,
    bool? redFlagTriggered,
    DateTime? endedAt,
  }) =>
      ChatSessionModel(
        sessionId: sessionId,
        patientId: patientId,
        therapistId: therapistId,
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
        messageCount: messageCount ?? this.messageCount,
        status: status ?? this.status,
        redFlagTriggered: redFlagTriggered ?? this.redFlagTriggered,
      );
}

class ChatMessageModel {
  final String messageId;
  final String role; // Firestore string — use messageRole getter
  final String content;
  final DateTime timestamp;
  final bool isRedFlag;

  const ChatMessageModel({
    required this.messageId,
    required this.role,
    required this.content,
    required this.timestamp,
    required this.isRedFlag,
  });

  MessageRole get messageRole => MessageRole.values.firstWhere(
        (e) => e.name == role,
        orElse: () => MessageRole.ai,
      );

  factory ChatMessageModel.fromMap(String id, Map<String, dynamic> map) =>
      ChatMessageModel(
        messageId: id,
        role: map['role'] as String? ?? MessageRole.ai.name,
        content: map['content'] as String? ?? '',
        timestamp:
            (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isRedFlag: map['isRedFlag'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'role': role,
        'content': content,
        'timestamp': Timestamp.fromDate(timestamp),
        'isRedFlag': isRedFlag,
      };
}

class RedFlagAlertModel {
  final String alertId;
  final String patientId;
  final String patientName;
  final String therapistId;
  final String flaggedMessage;
  final String conversationContext;
  final String aiContextSummary;
  final DateTime triggeredAt;
  final String status;   // Firestore string — use alertStatus getter
  final String severity; // Firestore string — use alertSeverity getter

  const RedFlagAlertModel({
    required this.alertId,
    required this.patientId,
    required this.patientName,
    required this.therapistId,
    required this.flaggedMessage,
    required this.conversationContext,
    required this.aiContextSummary,
    required this.triggeredAt,
    required this.status,
    required this.severity,
  });

  AlertStatus get alertStatus => AlertStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => AlertStatus.unread,
      );

  AlertSeverity get alertSeverity => AlertSeverity.values.firstWhere(
        (e) => e.name == severity,
        orElse: () => AlertSeverity.high,
      );

  factory RedFlagAlertModel.fromMap(String id, Map<String, dynamic> map) =>
      RedFlagAlertModel(
        alertId: id,
        patientId: map['patientId'] as String? ?? '',
        patientName: map['patientName'] as String? ?? '',
        therapistId: map['therapistId'] as String? ?? '',
        flaggedMessage: map['flaggedMessage'] as String? ?? '',
        conversationContext: map['conversationContext'] as String? ?? '',
        aiContextSummary: map['aiContextSummary'] as String? ?? '',
        triggeredAt:
            (map['triggeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: map['status'] as String? ?? AlertStatus.unread.name,
        severity: map['severity'] as String? ?? AlertSeverity.high.name,
      );

  Map<String, dynamic> toMap() => {
        'patientId': patientId,
        'patientName': patientName,
        'therapistId': therapistId,
        'flaggedMessage': flaggedMessage,
        'conversationContext': conversationContext,
        'aiContextSummary': aiContextSummary,
        'triggeredAt': Timestamp.fromDate(triggeredAt),
        'status': status,
        'severity': severity,
      };
}
