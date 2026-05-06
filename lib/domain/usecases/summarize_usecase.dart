// summarize_usecase.dart
// Calls the Python backend (via GroqService) to generate a patient summary.
// The Groq API key lives on the server — never in the Flutter client.

import '../../core/services/groq_service.dart';
import '../../data/models/assessment_model.dart';

class SummarizeParams {
  final List<int> assessmentAnswers;
  final String patientDescription;
  // apiKey kept for legacy call-site compatibility but is ignored.
  final String groqApiKey;

  const SummarizeParams({
    required this.assessmentAnswers,
    required this.patientDescription,
    this.groqApiKey = '',
  });
}

class SummarizeUseCase {
  final GroqService _groqService;

  SummarizeUseCase({GroqService? groqService})
      : _groqService = groqService ?? GroqService.instance;

  Future<String> call(SummarizeParams params) async {
    final assessmentText =
        AssessmentModel.formatAnswersForAI(params.assessmentAnswers);
    return _groqService.summarizePatient(
      assessmentText: assessmentText,
      description: params.patientDescription,
    );
  }
}
