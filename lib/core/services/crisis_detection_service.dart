// crisis_detection_service.dart
// Routes through the Python FastAPI backend — no Groq API key in the client.
// Always fails safe: returns false on any error so the patient is never blocked.

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class CrisisDetectionService {
  CrisisDetectionService._();
  static final CrisisDetectionService instance = CrisisDetectionService._();

  /// Returns [true] if [text] indicates a crisis. Never throws.
  Future<bool> isCrisis(String text) async {
    if (text.trim().length < 8) return false;
    try {
      final resp = await http
          .post(
            Uri.parse('${AppConstants.backendUrl}/red-flag'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'patientMessage': text,
              'conversationHistory': <Map<String, dynamic>>[],
              'sessionId': 'crisis_check',
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data['isRedFlag'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('[CrisisDetection] check failed (safe fallback): $e');
      return false;
    }
  }
}
