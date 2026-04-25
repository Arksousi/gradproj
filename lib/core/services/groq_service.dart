import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

/// Service class responsible for calling the Groq AI API.
class GroqService {
  GroqService._();

  static final GroqService instance = GroqService._();

  static const String _apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';
  static const String _emotionalModel = 'llama-3.3-70b-versatile';

  static const String _systemPrompt =
      'You are a professional psychotherapist assistant. '
      'Summarize the patient\'s mental health assessment and description clearly and professionally. '
      'Highlight: main issue, symptoms, and recommendations. '
      'Keep the summary concise (3-5 paragraphs) and use plain language.';

  static const String _welcomeSystemPrompt =
      'You are a warm emotional companion in PsyCare. '
      'The patient just shared their feelings with you. '
      'Write a short, warm opening paragraph. '
      '2-3 sentences only. '
      'Make them feel immediately heard and safe. '
      'Acknowledge specifically what they shared. '
      'Do not analyse yet. Do not give advice yet. '
      'Just make them feel seen and not alone. '
      'End with a gentle sentence showing you want to understand more. '
      'Use 1 emoji maximum. '
      'Respond in the same language the patient used.';


  Future<String> summarizePatient({
    required String apiKey,
    required String assessmentText,
    required String description,
  }) async {
    final userMessage =
        'Patient Assessment Results:\n$assessmentText\n\nPatient Description:\n$description';
    return _callGroq(
      apiKey: apiKey,
      model: _model,
      systemPrompt: _systemPrompt,
      userMessage: userMessage,
      maxTokens: 1024,
    );
  }

  /// Sends the patient's text to get a warm welcoming response.
  Future<String> getEmotionalSupportWelcome({
    required String apiKey,
    required String patientText,
  }) async {
    return _callGroq(
      apiKey: apiKey,
      model: _emotionalModel,
      systemPrompt: _welcomeSystemPrompt,
      userMessage: patientText,
      maxTokens: 300,
    );
  }

  /// Sends both patient messages to get a structured bullet-point comfort response.
  Future<String> getEmotionalComfort({
    required String apiKey,
    required String firstMessage,
    required String secondMessage,
  }) async {
    final systemPrompt =
        'You are an empathetic and insightful companion in PsyCare.\n'
        'The patient shared two messages with you:\n'
        'First: $firstMessage\n'
        'Second: $secondMessage\n\n'
        'Write your response in this exact structure:\n\n'
        'First: one sentence acknowledging what they just shared in their second message.\n\n'
        'Then a short list of 3-4 bullet points.\n'
        'Each bullet point must do ONE of these things:\n'
        '- Reflect back what you understand they are going through\n'
        '- Name the emotion beneath their words\n'
        '- Offer a gentle reframe of how to see their situation differently\n'
        '- Give one small, practical perspective shift\n\n'
        'Each bullet point: 1-2 sentences maximum.\n'
        'Warm, specific, never generic.\n'
        'No clinical language.\n'
        'No long explanations.\n\n'
        'After the bullet points, write one short closing sentence that leads naturally '
        'into asking if they want more help.\n'
        "Example: 'There are a few things that might help you with what you are feeling "
        "right now, if you would like. 🌿'\n\n"
        'Use 1-2 emojis total.\n'
        'Respond in same language as patient.';

    return _callGroq(
      apiKey: apiKey,
      model: _emotionalModel,
      systemPrompt: systemPrompt,
      userMessage: 'Please respond based on both messages I shared.',
      maxTokens: 500,
    );
  }

  /// Closing message when the patient declines further help techniques.
  Future<String> getNoHelpClosing({
    required String apiKey,
    required String patientText,
  }) async {
    const prompt =
        'The patient chose not to receive help techniques. '
        'Write 2-3 warm sentences. '
        'Tell them that is completely okay. '
        'Tell them their therapist will have full context from everything they shared. '
        'End with one encouraging sentence. '
        'Respond in same language as patient.';
    return _callGroq(
      apiKey: apiKey,
      model: _emotionalModel,
      systemPrompt: prompt,
      userMessage: patientText,
      maxTokens: 200,
    );
  }

  /// Compassionate closing for when the patient still feels bad after a technique.
  Future<String> getStrugglingResponse({
    required String apiKey,
    required String patientText,
  }) async {
    const prompt =
        'The patient just finished the emotional support section and still feels bad. '
        'Write them a deeply compassionate closing message. 5-6 sentences. '
        'Acknowledge that healing is not instant. '
        'Tell them that what they did today — showing up, writing their feelings, '
        'going through this — was incredibly brave. '
        'Remind them their therapist will see everything. '
        'End with the most encouraging, hopeful sentence you can write '
        'that speaks directly to what they originally shared. '
        'Make them feel less alone in this exact moment. '
        'Use gentle emojis 💙🌿✨\n'
        'Respond in the same language as the patient.';
    return _callGroq(
      apiKey: apiKey,
      model: _emotionalModel,
      systemPrompt: prompt,
      userMessage: patientText,
      maxTokens: 450,
    );
  }

  /// Returns tailored guidance based on the selected [method].
  /// method: 'breathing' | 'meditation' | 'reframing' | 'quotes'
  Future<String> getMethodGuidance({
    required String apiKey,
    required String patientText,
    required String method,
  }) async {
    return _callGroq(
      apiKey: apiKey,
      model: _emotionalModel,
      systemPrompt: _buildMethodPrompt(patientText, method),
      userMessage: _methodUserMessage(method),
      maxTokens: 600,
    );
  }

  Future<String> _callGroq({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userMessage,
    required int maxTokens,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.7,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>;
        if (choices.isEmpty) throw Exception('No response from Groq API');
        return (choices[0]['message']['content'] as String).trim();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            'Groq API error ${response.statusCode}: ${error['error']?['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('[GroqService] error: $e');
      rethrow;
    }
  }

  static const String _methodWarmthRule =
      'Be generous with your words. '
      'Do not rush through the technique. '
      'Walk them through it slowly and warmly. '
      'Between each step, add an encouraging sentence. '
      'Make them feel accompanied, not instructed. '
      'Write as if you are sitting right next to them. '
      'Total response: 8 to 12 sentences. '
      'Respond in the same language as the patient.';

  static String _buildMethodPrompt(String patientText, String method) {
    switch (method) {
      case 'breathing':
        return 'You are a calming wellness guide in PsyCare app.\n'
            'The patient is feeling: $patientText\n'
            'Deliver a simple, trusted breathing exercise.\n'
            'Format:\n'
            '- One warm opening sentence acknowledging their choice\n'
            '- Name of the technique (e.g. Box Breathing, 4-7-8)\n'
            '- Why it works (1 sentence, simple language)\n'
            '- Step by step instructions with an encouraging sentence between each step\n'
            '- One closing encouraging sentence\n'
            'Use gentle emojis.\n'
            '$_methodWarmthRule';
      case 'meditation':
        return 'You are a calming wellness guide in PsyCare app.\n'
            'The patient is feeling: $patientText\n'
            'Deliver a short guided meditation or grounding exercise.\n'
            'Format:\n'
            '- One warm opening sentence\n'
            '- Name of the technique (e.g. 5-4-3-2-1 Grounding)\n'
            '- Why it helps (1 sentence)\n'
            '- Step by step guide with an encouraging sentence between each step\n'
            '- One closing sentence with hope\n'
            'Use gentle emojis.\n'
            '$_methodWarmthRule';
      case 'reframing':
        return 'You are a compassionate cognitive support guide in PsyCare.\n'
            'The patient is feeling: $patientText\n'
            'Help them gently reframe their thinking.\n'
            'Format:\n'
            '- Acknowledge their current thought pattern warmly\n'
            '- Introduce the reframe gently (e.g. "What if we looked at it this way...")\n'
            '- Give 2-3 reframing perspectives, each in simple conversational language, '
            'with an encouraging sentence between each\n'
            '- End with an empowering sentence\n'
            'No clinical terms.\n'
            '$_methodWarmthRule';
      case 'quotes':
      default:
        return 'You are a thoughtful emotional companion in PsyCare.\n'
            'The patient is feeling: $patientText\n'
            'Share 3 meaningful quotes or sayings that speak directly to their emotion.\n'
            'Format for each quote:\n'
            '- The quote itself (from real thinkers, poets, or wisdom traditions)\n'
            '- Two sentences explaining why this speaks to their situation specifically\n'
            'End with one original warm sentence from you.\n'
            '$_methodWarmthRule';
    }
  }

  static String _methodUserMessage(String method) {
    switch (method) {
      case 'breathing':
        return 'Please provide the breathing exercise guidance.';
      case 'meditation':
        return 'Please provide the meditation or grounding guidance.';
      case 'reframing':
        return 'Please help me reframe my thoughts.';
      case 'quotes':
      default:
        return 'Please share the healing words or quotes.';
    }
  }
}
