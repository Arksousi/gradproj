import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service class responsible for calling the Groq AI API.
/// Returns a structured AI summary of a patient's assessment data.
class GroqService {
  GroqService._();

  static final GroqService instance = GroqService._();

  static const String _apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3';

  // System prompt for the therapist-assistant role
  static const String _systemPrompt =
      'You are a professional psychotherapist assistant. '
      'Summarize the patient\'s mental health assessment and description clearly and professionally. '
      'Highlight: main issue, symptoms, and recommendations. '
      'Keep the summary concise (3-5 paragraphs) and use plain language.';

  /// Calls the Groq API with the patient [assessmentText] and [description].
  /// [apiKey] must be a valid Groq API key (stored securely, passed at runtime).
  ///
  /// Returns the AI-generated summary string, or throws an [Exception] on failure.
  Future<String> summarizePatient({
    required String apiKey,
    required String assessmentText,
    required String description,
  }) async {
    final userMessage =
        'Patient Assessment Results:\n$assessmentText\n\nPatient Description:\n$description';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>;
        if (choices.isEmpty) throw Exception('No response from Groq API');
        final content = choices[0]['message']['content'] as String;
        return content.trim();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            'Groq API error ${response.statusCode}: ${error['error']?['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
