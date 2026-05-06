// groq_service.dart
// All AI calls go through the Python FastAPI backend — the Groq API key
// is NEVER sent from the Flutter client. This service is a thin HTTP wrapper.

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class GroqService {
  GroqService._();
  static final GroqService instance = GroqService._();

  // ── Patient summary (therapist view) ─────────────────────────────────────

  Future<String> summarizePatient({
    String apiKey = '',   // kept for API compatibility but ignored — key is server-side
    required String assessmentText,
    required String description,
  }) async {
    return _callBackend('/patient-summary', {
      'assessmentText': assessmentText,
      'description': description,
    }, responseKey: 'summary');
  }

  // ── Emotional support flow ───────────────────────────────────────────────

  Future<String> getEmotionalSupportWelcome({
    String apiKey = '',
    required String patientText,
  }) async {
    return _callBackend('/emotional-support', {
      'type': 'welcome',
      'patientText': patientText,
    });
  }

  Future<String> getEmotionalComfort({
    String apiKey = '',
    required String firstMessage,
    required String secondMessage,
  }) async {
    return _callBackend('/emotional-support', {
      'type': 'comfort',
      'patientText': firstMessage,
      'firstMessage': firstMessage,
      'secondMessage': secondMessage,
    });
  }

  Future<String> getNoHelpClosing({
    String apiKey = '',
    required String patientText,
  }) async {
    return _callBackend('/emotional-support', {
      'type': 'no_help',
      'patientText': patientText,
    });
  }

  Future<String> getStrugglingResponse({
    String apiKey = '',
    required String patientText,
  }) async {
    return _callBackend('/emotional-support', {
      'type': 'struggling',
      'patientText': patientText,
    });
  }

  Future<String> getMethodGuidance({
    String apiKey = '',
    required String patientText,
    required String method,
  }) async {
    return _callBackend('/emotional-support', {
      'type': 'method_guidance',
      'patientText': patientText,
      'method': method,
    });
  }

  // ── HTTP helper ──────────────────────────────────────────────────────────

  Future<String> _callBackend(
    String endpoint,
    Map<String, dynamic> body, {
    String responseKey = 'response',
  }) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final resp = await http
            .post(
              Uri.parse('${AppConstants.backendUrl}$endpoint'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(AppConstants.httpTimeout);

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          if (data['error'] != null) {
            debugPrint('[GroqService] $endpoint backend error: ${data['error']}');
            if (attempt == 0) {
              await Future<void>.delayed(const Duration(seconds: 1));
              continue;
            }
            throw Exception('AI service temporarily unavailable.');
          }
          return data[responseKey] as String? ?? '';
        }
        debugPrint('[GroqService] $endpoint HTTP ${resp.statusCode} attempt $attempt');
      } catch (e) {
        debugPrint('[GroqService] $endpoint error attempt $attempt: $e');
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(seconds: 1));
          continue;
        }
        rethrow;
      }
    }
    throw Exception('AI service temporarily unavailable.');
  }
}
