import 'package:google_generative_ai/google_generative_ai.dart';

class AiApiService {
  final String _apiKey = 'AIzaSyDkVohSvUOnRxZLRSoVhINX89vKqhBx3Lg';
  late final GenerativeModel _model;

  AiApiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-preview-05-20', // Updated to valid model name
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.4, // More focused responses
        maxOutputTokens: 1000, // Longer insights
      ),
    );
  }

  Future<String> generateInsights(String prompt) async {
    try {
      final response = await _model.generateContent([
        Content.text(prompt),
      ]);

      // Handle empty responses
      return response.text?.trim() ?? 'No insights generated. Please try again.';
    } catch (e) {
      print('Error generating insights: $e');

      // Handle specific API errors
      if (e.toString().contains('model not found')) {
        return 'Configuration error: Please contact support';
      } else if (e.toString().contains('quota')) {
        return 'Service limit reached: Try again later';
      } else if (e.toString().contains('network')) {
        return 'Connection error: Check your internet';
      }

      return 'Temporary service issue: Please retry';
    }
  }
}