// summarize_usecase.dart
// Orchestrates calling the Groq AI API to generate a patient summary.

import '../../core/services/groq_service.dart';
import '../../data/models/assessment_model.dart';

/// Input parameters for the AI summarization use case.
class SummarizeParams {
  final String groqApiKey;
  final List<int> assessmentAnswers;
  final String patientDescription;

  const SummarizeParams({
    required this.groqApiKey,
    required this.assessmentAnswers,
    required this.patientDescription,
  });
}

/// Use case that builds the prompt and calls [GroqService] to summarize
/// a patient's mental health assessment.
class SummarizeUseCase {
  final GroqService _groqService;

  SummarizeUseCase({GroqService? groqService})
      : _groqService = groqService ?? GroqService.instance;

  /// Calls the Groq API and returns the AI-generated summary string.
  Future<String> call(SummarizeParams params) async {
    // Build human-readable assessment text from raw answer indices
    final assessmentText =
        AssessmentModel.formatAnswersForAI(params.assessmentAnswers);

    return _groqService.summarizePatient(
      apiKey: params.groqApiKey,
      assessmentText: assessmentText,
      description: params.patientDescription,
    );
  }
}
