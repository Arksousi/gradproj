// chat_model.dart
// Data models for real-time chat sessions and immediate request queue.

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderRole; // 'patient' | 'therapist'
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) =>
      ChatMessage(
        id: id,
        senderId: map['senderId'] as String? ?? '',
        senderRole: map['senderRole'] as String? ?? 'patient',
        text: map['text'] as String? ?? '',
        timestamp:
            (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderRole': senderRole,
        'text': text,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}

class ChatSession {
  final String id;
  final String patientId;
  final String therapistId;
  final String status; // 'active' | 'ended'
  final DateTime createdAt;
  final String patientSummary;
  final String clinicalReport;

  const ChatSession({
    required this.id,
    required this.patientId,
    required this.therapistId,
    required this.status,
    required this.createdAt,
    required this.patientSummary,
    required this.clinicalReport,
  });

  factory ChatSession.fromMap(String id, Map<String, dynamic> map) =>
      ChatSession(
        id: id,
        patientId: map['patientId'] as String? ?? '',
        therapistId: map['therapistId'] as String? ?? '',
        status: map['status'] as String? ?? 'active',
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        patientSummary: map['patientSummary'] as String? ?? '',
        clinicalReport: map['clinicalReport'] as String? ?? '',
      );
}

class ImmediateRequest {
  final String id;
  final String patientId;
  final String patientName;
  final String patientSummary;
  final String clinicalReport;
  final String status; // 'pending' | 'accepted'
  final String? acceptedByTherapistId;
  final String? chatSessionId;
  final DateTime createdAt;

  const ImmediateRequest({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientSummary,
    required this.clinicalReport,
    required this.status,
    this.acceptedByTherapistId,
    this.chatSessionId,
    required this.createdAt,
  });

  factory ImmediateRequest.fromMap(String id, Map<String, dynamic> map) =>
      ImmediateRequest(
        id: id,
        patientId: map['patientId'] as String? ?? '',
        patientName: map['patientName'] as String? ?? '',
        patientSummary: map['patientSummary'] as String? ?? '',
        clinicalReport: map['clinicalReport'] as String? ?? '',
        status: map['status'] as String? ?? 'pending',
        acceptedByTherapistId: map['acceptedByTherapistId'] as String?,
        chatSessionId: map['chatSessionId'] as String?,
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
