// assessment_model.dart
// Defines the 30 mental health assessment questions and the AssessmentModel.

/// A single assessment question with a text and 4 answer options.
class AssessmentQuestion {
  final String question;
  final String category;
  final List<String> options; // Always 4 options (indices 0-3)

  const AssessmentQuestion({
    required this.question,
    required this.category,
    required this.options,
  });
}

/// Holds the full list of 30 MCQ assessment questions.
/// Covers: anxiety, depression, sleep, social life, energy levels, wellbeing.
class AssessmentModel {
  /// The 30 standard mental health questions used in the assessment form.
  static const List<AssessmentQuestion> questions = [
    // --- ANXIETY (6 questions) ---
    AssessmentQuestion(
      question: 'How often do you feel nervous, anxious, or on edge?',
      category: 'Anxiety',
      options: ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
    ),
    AssessmentQuestion(
      question: 'How often are you unable to stop or control worrying?',
      category: 'Anxiety',
      options: ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
    ),
    AssessmentQuestion(
      question: 'How often do you feel a sense of impending doom or danger?',
      category: 'Anxiety',
      options: ['Not at all', 'Rarely', 'Sometimes', 'Very often'],
    ),
    AssessmentQuestion(
      question: 'Do you experience physical symptoms of anxiety (racing heart, sweating)?',
      category: 'Anxiety',
      options: ['Never', 'Occasionally', 'Frequently', 'Always'],
    ),
    AssessmentQuestion(
      question: 'How often do you avoid situations because they make you anxious?',
      category: 'Anxiety',
      options: ['Never', 'Rarely', 'Sometimes', 'Often'],
    ),
    AssessmentQuestion(
      question: 'How difficult is it to relax when you want to?',
      category: 'Anxiety',
      options: ['Not difficult', 'Slightly difficult', 'Moderately difficult', 'Extremely difficult'],
    ),

    // --- DEPRESSION (6 questions) ---
    AssessmentQuestion(
      question: 'How often do you feel little interest or pleasure in doing things?',
      category: 'Depression',
      options: ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
    ),
    AssessmentQuestion(
      question: 'How often do you feel down, depressed, or hopeless?',
      category: 'Depression',
      options: ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
    ),
    AssessmentQuestion(
      question: 'How often do you feel bad about yourself or feel like a failure?',
      category: 'Depression',
      options: ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
    ),
    AssessmentQuestion(
      question: 'How often do you have trouble concentrating on tasks?',
      category: 'Depression',
      options: ['Not at all', 'Occasionally', 'Often', 'Almost always'],
    ),
    AssessmentQuestion(
      question: 'Have you had thoughts that you would be better off dead or of hurting yourself?',
      category: 'Depression',
      options: ['Not at all', 'Rarely', 'Sometimes', 'Often'],
    ),
    AssessmentQuestion(
      question: 'How often do you feel emotionally numb or disconnected?',
      category: 'Depression',
      options: ['Never', 'Sometimes', 'Often', 'Nearly always'],
    ),

    // --- SLEEP (5 questions) ---
    AssessmentQuestion(
      question: 'How would you rate your overall sleep quality?',
      category: 'Sleep',
      options: ['Very good', 'Fairly good', 'Fairly bad', 'Very bad'],
    ),
    AssessmentQuestion(
      question: 'How often do you have trouble falling asleep?',
      category: 'Sleep',
      options: ['Not at all', 'Less than once a week', 'Once or twice a week', '3+ nights a week'],
    ),
    AssessmentQuestion(
      question: 'How often do you wake up in the middle of the night?',
      category: 'Sleep',
      options: ['Not at all', 'Less than once a week', 'Once or twice a week', '3+ nights a week'],
    ),
    AssessmentQuestion(
      question: 'How many hours of sleep do you typically get per night?',
      category: 'Sleep',
      options: ['7-9 hours (ideal)', '6-7 hours', '5-6 hours', 'Less than 5 hours'],
    ),
    AssessmentQuestion(
      question: 'How often do you feel unrested even after a full night of sleep?',
      category: 'Sleep',
      options: ['Never', 'Occasionally', 'Often', 'Almost every day'],
    ),

    // --- SOCIAL LIFE (5 questions) ---
    AssessmentQuestion(
      question: 'How often do you engage in social activities with friends or family?',
      category: 'Social Life',
      options: ['Very often', 'Sometimes', 'Rarely', 'Almost never'],
    ),
    AssessmentQuestion(
      question: 'How comfortable do you feel in social situations?',
      category: 'Social Life',
      options: ['Very comfortable', 'Somewhat comfortable', 'Uncomfortable', 'Very uncomfortable'],
    ),
    AssessmentQuestion(
      question: 'How often do you feel lonely or isolated?',
      category: 'Social Life',
      options: ['Never', 'Occasionally', 'Often', 'Almost always'],
    ),
    AssessmentQuestion(
      question: 'How would you describe your relationships with close ones?',
      category: 'Social Life',
      options: ['Very supportive', 'Mostly supportive', 'Somewhat strained', 'Very strained'],
    ),
    AssessmentQuestion(
      question: 'How often do you withdraw from people when you are stressed?',
      category: 'Social Life',
      options: ['Never', 'Occasionally', 'Often', 'Always'],
    ),

    // --- ENERGY LEVELS (5 questions) ---
    AssessmentQuestion(
      question: 'How would you rate your overall energy level throughout the day?',
      category: 'Energy',
      options: ['Very high', 'Moderate', 'Low', 'Very low'],
    ),
    AssessmentQuestion(
      question: 'How often do you feel fatigued or exhausted without clear reason?',
      category: 'Energy',
      options: ['Rarely', 'Occasionally', 'Often', 'Almost always'],
    ),
    AssessmentQuestion(
      question: 'How often do you feel motivated to complete daily tasks?',
      category: 'Energy',
      options: ['Almost always', 'Often', 'Rarely', 'Almost never'],
    ),
    AssessmentQuestion(
      question: 'How often do you experience a mid-day energy crash?',
      category: 'Energy',
      options: ['Never', 'Occasionally', 'Often', 'Every day'],
    ),
    AssessmentQuestion(
      question: 'How well are you able to maintain focus throughout the day?',
      category: 'Energy',
      options: ['Very well', 'Moderately well', 'Poorly', 'Very poorly'],
    ),

    // --- GENERAL WELLBEING (3 questions) ---
    AssessmentQuestion(
      question: 'Overall, how satisfied are you with your quality of life?',
      category: 'Wellbeing',
      options: ['Very satisfied', 'Somewhat satisfied', 'Dissatisfied', 'Very dissatisfied'],
    ),
    AssessmentQuestion(
      question: 'How often do you engage in self-care activities (exercise, hobbies)?',
      category: 'Wellbeing',
      options: ['Regularly', 'Sometimes', 'Rarely', 'Never'],
    ),
    AssessmentQuestion(
      question: 'How would you rate your ability to cope with life\'s challenges?',
      category: 'Wellbeing',
      options: ['Very well', 'Fairly well', 'With difficulty', 'Very poorly'],
    ),
  ];

  /// Total number of questions in the assessment.
  static int get totalQuestions => questions.length;

  /// Formats answers as a readable text summary for the AI prompt.
  static String formatAnswersForAI(List<int> answers) {
    final buffer = StringBuffer();
    for (int i = 0; i < questions.length && i < answers.length; i++) {
      final q = questions[i];
      final answerIndex = answers[i];
      final answerText = answerIndex < q.options.length
          ? q.options[answerIndex]
          : 'No answer';
      buffer.writeln('[${q.category}] ${q.question}');
      buffer.writeln('  → $answerText');
      buffer.writeln();
    }
    return buffer.toString();
  }
}
