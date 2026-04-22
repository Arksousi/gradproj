// chat_repository.dart
// Handles Firestore operations for immediate chat requests and sessions.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/firebase_service.dart';
import '../models/chat_model.dart';

class ChatRepository {
  final FirebaseService _firebase;

  ChatRepository({FirebaseService? firebase})
      : _firebase = firebase ?? FirebaseService.instance;

  Future<String> createImmediateRequest({
    required String patientId,
    required String patientName,
    required String patientSummary,
    required String clinicalReport,
  }) async {
    final doc = _firebase.firestore.collection('immediate_requests').doc();
    await doc.set({
      'patientId': patientId,
      'patientName': patientName,
      'patientSummary': patientSummary,
      'clinicalReport': clinicalReport,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<ImmediateRequest?> watchRequest(String requestId) {
    return _firebase.firestore
        .collection('immediate_requests')
        .doc(requestId)
        .snapshots()
        .map((doc) =>
            doc.exists ? ImmediateRequest.fromMap(doc.id, doc.data()!) : null);
  }

  Stream<List<ImmediateRequest>> streamPendingRequests() {
    return _firebase.firestore
        .collection('immediate_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
      final requests =
          snap.docs.map((d) => ImmediateRequest.fromMap(d.id, d.data())).toList();
      requests.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return requests;
    });
  }

  Future<TherapistAvailability?> findAvailableTherapist() async {
    final snap = await _firebase.firestore
        .collection('therapists')
        .where('isOnShift', isEqualTo: true)
        .where('isAvailableForImmediate', isEqualTo: true)
        .get();
    if (snap.docs.isEmpty) return null;
    return TherapistAvailability(uid: snap.docs.first.id);
  }

  Future<String> createSession({
    required String patientId,
    required String therapistId,
    required String patientSummary,
    required String clinicalReport,
  }) async {
    final doc = _firebase.firestore.collection('chat_sessions').doc();
    await doc.set({
      'patientId': patientId,
      'therapistId': therapistId,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'patientSummary': patientSummary,
      'clinicalReport': clinicalReport,
    });
    return doc.id;
  }

  Future<String> acceptRequest({
    required String requestId,
    required String therapistId,
    required String patientId,
    required String patientSummary,
    required String clinicalReport,
  }) async {
    final sessionId = await createSession(
      patientId: patientId,
      therapistId: therapistId,
      patientSummary: patientSummary,
      clinicalReport: clinicalReport,
    );
    await _firebase.firestore
        .collection('immediate_requests')
        .doc(requestId)
        .update({
      'status': 'accepted',
      'acceptedByTherapistId': therapistId,
      'chatSessionId': sessionId,
    });
    return sessionId;
  }

  Stream<ChatSession?> watchSession(String sessionId) {
    return _firebase.firestore
        .collection('chat_sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) =>
            doc.exists ? ChatSession.fromMap(doc.id, doc.data()!) : null);
  }

  Future<void> endSession(String sessionId) async {
    await _firebase.firestore
        .collection('chat_sessions')
        .doc(sessionId)
        .update({'status': 'ended'});
  }

  Stream<List<ChatMessage>> watchMessages(String sessionId) {
    return _firebase.firestore
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .snapshots()
        .map((snap) {
      final msgs =
          snap.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList();
      msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return msgs;
    });
  }

  Future<void> sendMessage({
    required String sessionId,
    required String senderId,
    required String senderRole,
    required String text,
  }) async {
    await _firebase.firestore
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

class TherapistAvailability {
  final String uid;
  const TherapistAvailability({required this.uid});
}

final chatRepositoryProvider =
    Provider<ChatRepository>((ref) => ChatRepository());
