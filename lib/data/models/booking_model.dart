// booking_model.dart
// Data model for a session booking request from a patient to a therapist.

import 'package:cloud_firestore/cloud_firestore.dart';

class BookingRequest {
  final String id;
  final String patientId;
  final String patientName;
  final String therapistId;
  final String therapistName;
  // status values: 'pending' | 'confirmed' | 'declined'
  //   | 'cancelled_by_patient' | 'cancelled_by_therapist' | 'reschedule_requested'
  final String status;
  final DateTime requestedAt;
  final String sessionType; // 'chat' | 'video' | 'in-person'
  final bool consentGiven;
  final String? cancelReason;
  final String? rescheduleNote;

  const BookingRequest({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.therapistId,
    this.therapistName = '',
    required this.status,
    required this.requestedAt,
    required this.sessionType,
    required this.consentGiven,
    this.cancelReason,
    this.rescheduleNote,
  });

  factory BookingRequest.fromMap(String id, Map<String, dynamic> map) =>
      BookingRequest(
        id: id,
        patientId: map['patientId'] as String? ?? '',
        patientName: map['patientName'] as String? ?? '',
        therapistId: map['therapistId'] as String? ?? '',
        therapistName: map['therapistName'] as String? ?? '',
        status: map['status'] as String? ?? 'pending',
        requestedAt:
            (map['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        sessionType: map['sessionType'] as String? ?? 'chat',
        consentGiven: map['consentGiven'] as bool? ?? false,
        cancelReason: map['cancelReason'] as String?,
        rescheduleNote: map['rescheduleNote'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'patientId': patientId,
        'patientName': patientName,
        'therapistId': therapistId,
        'therapistName': therapistName,
        'status': status,
        'requestedAt': Timestamp.fromDate(requestedAt),
        'sessionType': sessionType,
        'consentGiven': consentGiven,
        if (cancelReason != null) 'cancelReason': cancelReason,
        if (rescheduleNote != null) 'rescheduleNote': rescheduleNote,
      };
}
