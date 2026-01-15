import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  final String apiKey;
  final String modelName;
  late final GenerativeModel _model;

  GeminiService({required this.apiKey, required this.modelName}) {
    _model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
      ],
    );
  }

  Future<String?> solveQuestion(String question, List<String> options) async {
    try {
      final prompt =
          '''
      Logic Puzzle Solver.
      Question: $question
      Options: ${options.join(', ')}

      Task: Identify the correct option.
      Output format: Just the single letter representing the correct index (A for 0, B for 1, etc).
      Example: If index 1 is correct, output B.
      no yapping.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      final text = response.text?.trim().toUpperCase() ?? '';

      // Clean up response if it contains extra text (fallback)
      final RegExp letterRegex = RegExp(r'[A-D]');
      final match = letterRegex.firstMatch(text);

      return match?.group(0);
    } catch (e) {
      if (kDebugMode) print('Gemini Error: $e');
      return null;
    }
  }
}
