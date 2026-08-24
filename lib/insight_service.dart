import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class InsightService {
  static const String apiKey = 'AIzaSyDkVohSvUOnRxZLRSoVhINX89vKqhBx3Lg';

  static final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash-latest',  // Updated to latest stable model
    apiKey: apiKey,
  );

  static String createPrompt({
    required String userName,
    required Map<String, double> current,
    required Map<String, double> previous,
    required String currentDominant,
    required String previousDominant,
    required bool isUrdu,
  }){
    if (isUrdu) {
      return '''
صارف: $userName

مندرجہ ذیل DISC شخصیت کی تشخیص کے نتائج کا موازنہ کریں:

**موجودہ تشخیص**
- تاریخ: ${DateFormat.yMMMd('ur_PK').format(DateTime.now())}
- غلبہ (D): ${current['d']?.toStringAsFixed(1)}%
- اثر (I): ${current['i']?.toStringAsFixed(1)}%
- استحکام (S): ${current['s']?.toStringAsFixed(1)}%
- تعمیل (C): ${current['c']?.toStringAsFixed(1)}%
- غالب خصوصیت: $currentDominant

**پچھلی تشخیص**
- تاریخ: ${previous.containsKey('date') ? DateFormat.yMMMd('ur_PK').format(previous['date'] as DateTime) : 'پچھلی'}
- غلبہ (D): ${previous['d']?.toStringAsFixed(1)}%
- اثر (I): ${previous['i']?.toStringAsFixed(1)}%
- استحکام (S): ${previous['s']?.toStringAsFixed(1)}%
- تعمیل (C): ${previous['c']?.toStringAsFixed(1)}%
- غالب خصوصیت: $previousDominant

**تجزیہ کی درخواست:**
1. وہ نمایاں تبدیلیاں بتائیں جن میں 3% سے زیادہ فرق ہو
2. اگر غالب خصوصیت میں تبدیلی ہوئی ہے تو اس کی وضاحت کریں
3. بہتری کے لیے عملی تجاویز دیں
4. حوصلہ افزا اور پیشہ ورانہ انداز برقرار رکھیں
5. آسان زبان میں واضح پیراگراف میں جواب دیں
''';
    }

    // 🔵 Fallback to English prompt if not Urdu
    return '''
User: $userName

Compare these DISC personality assessment results:

**Current Assessment**
- Date: ${DateFormat.yMMMd().format(DateTime.now())}
- Dominance (D): ${current['d']?.toStringAsFixed(1)}%
- Influence (I): ${current['i']?.toStringAsFixed(1)}%
- Steadiness (S): ${current['s']?.toStringAsFixed(1)}%
- Compliance (C): ${current['c']?.toStringAsFixed(1)}%
- Dominant Trait: $currentDominant

**Previous Assessment**
- Date: ${previous.containsKey('date') ? DateFormat.yMMMd().format(previous['date'] as DateTime) : 'Previous'}
- Dominance (D): ${previous['d']?.toStringAsFixed(1)}%
- Influence (I): ${previous['i']?.toStringAsFixed(1)}%
- Steadiness (S): ${previous['s']?.toStringAsFixed(1)}%
- Compliance (C): ${previous['c']?.toStringAsFixed(1)}%
- Dominant Trait: $previousDominant

**Analysis Request:**
1. Highlight significant changes (>3% difference) between current and previous scores
2. Explain implications of the dominant trait shift (if any)
3. Provide practical growth suggestions based on changes
4. Maintain encouraging, professional tone
5. Format response in clear paragraphs with simple language
''';
  }
  static Future<String> generateInsights(
      String userName,
      String currentDominant,
      String previousDominant,
      Map<String, double> currentSummary,
      Map<String, double> previousSummary,
      Locale locale,
      ) async {
    final isUrdu = locale.languageCode == 'ur';
    final prompt = createPrompt(
      userName: userName,
      current: currentSummary,
      previous: previousSummary,
      currentDominant: currentDominant,
      previousDominant: previousDominant,
      isUrdu: isUrdu,
    );

    print("Sending prompt to Gemini:\n$prompt");

    try {
      final response = await _model.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 1500,
        ),
      );

      // Properly handle content parts
      final content = response.text;
      if (content == null || content.isEmpty) {
        throw GenerativeAIException(
          'Empty response from Gemini API',
          //statusCode: 500,
        );
      }

      print("✅ Gemini insight received:\n$content");
      return content;
    } on GenerativeAIException catch (e) {
      print('❌ Gemini API Error: ${e.message}');
      return _handleApiError(
        e,
        currentDominant,
        previousDominant,
        currentSummary,
        previousSummary,
      );
    } catch (e, stacktrace) {
      print('❌ Unexpected Error: $e\n$stacktrace');
      return _fallbackToRuleBased(
        currentDominant,
        previousDominant,
        currentSummary,
        previousSummary,
      );
    }
  }

  static String _handleApiError(
      GenerativeAIException e,
      String currentDominant,
      String previousDominant,
      Map<String, double> current,
      Map<String, double> previous,
      ) {
    final errorMessage = StringBuffer("⚠️ AI insights unavailable\n\n");

    final msg = e.message.toLowerCase();

    if (msg.contains('invalid argument') || msg.contains('400')) {
      errorMessage.writeln("• Invalid request parameters");
    } else if (msg.contains('quota') || msg.contains('rate limit') || msg.contains('429')) {
      errorMessage.writeln("• API quota exceeded");
    } else if (msg.contains('unavailable') || msg.contains('503')) {
      errorMessage.writeln("• Service unavailable");
    } else {
      errorMessage.writeln("• Technical error: ${e.message}");
    }

    errorMessage.writeln("\nUsing rule-based insights:");

    return errorMessage.toString() +
        _fallbackToRuleBased(currentDominant, previousDominant, current, previous);
  }

  static String _fallbackToRuleBased(
      String currentDominant,
      String previousDominant,
      Map<String, double> current,
      Map<String, double> previous,
      ) {
    final changes = {
      'd': (current['d'] ?? 0) - (previous['d'] ?? 0),
      'i': (current['i'] ?? 0) - (previous['i'] ?? 0),
      's': (current['s'] ?? 0) - (previous['s'] ?? 0),
      'c': (current['c'] ?? 0) - (previous['c'] ?? 0),
    };

    return ruleBasedInsights(currentDominant, previousDominant, changes);
  }

  static String ruleBasedInsights(
      String currentDominant,
      String previousDominant,
      Map<String, double> changes,
      ) {
    final insights = StringBuffer();
    bool hasSignificantChanges = false;
    const threshold = 3.0;

    const traits = {
      'd': 'Dominance',
      'i': 'Influence',
      's': 'Steadiness',
      'c': 'Compliance'
    };

    traits.forEach((trait, name) {
      final change = changes[trait] ?? 0;
      final absChange = change.abs();

      if (absChange > threshold) {
        hasSignificantChanges = true;
        final direction = change > 0 ? 'increased' : 'decreased';
        final implication = _getTraitChangeImplication(trait, change > 0);

        insights.writeln(
          "- Your $name has $direction by ${absChange.toStringAsFixed(1)}%, suggesting $implication.",
        );
      }
    });

    if (currentDominant != previousDominant) {
      insights.writeln(
        "\n🌟 Your primary personality has shifted from $previousDominant to $currentDominant. "
            "This indicates ${_getDominantShiftImplication(previousDominant, currentDominant)}.",
      );
    } else if (hasSignificantChanges) {
      insights.writeln(
        "\n🔍 Your primary $currentDominant personality remains consistent, but these changes show "
            "${_getDominantConsistencyContext(currentDominant, changes)}.",
      );
    } else {
      insights.writeln(
        "\n🧘 Your profile shows remarkable stability. Your consistent $currentDominant personality suggests "
            "${_getStabilityImplication(currentDominant)}.",
      );
    }

    _addCombinationInsights(insights, changes);

    return insights.toString();
  }

  static String _getTraitChangeImplication(String trait, bool isIncrease) {
    switch (trait) {
      case 'd':
        return isIncrease ? "more assertive decision-making" : "a more collaborative approach";
      case 'i':
        return isIncrease ? "greater social engagement" : "more focused interactions";
      case 's':
        return isIncrease ? "increased consistency and stability" : "greater adaptability to change";
      case 'c':
        return isIncrease ? "more attention to detail" : "a more flexible attitude toward rules";
      default:
        return "behavioral adjustments";
    }
  }

  static String _getDominantShiftImplication(String from, String to) {
    final combinations = {
      'd_to_i': "a shift from direct leadership to influential motivation",
      'i_to_d': "moving from social connection to decisive action",
      's_to_c': "transitioning from steady support to precise analysis",
      'c_to_s': "changing from careful scrutiny to reliable support",
    };
    return combinations['${from}_to_$to'] ?? "significant personal growth";
  }

  static String _getDominantConsistencyContext(String dominant, Map<String, double> changes) {
    switch (dominant.toLowerCase()) {
      case 'd':
        return "your leadership style is evolving while maintaining its core assertive nature";
      case 'i':
        return "your social approach is adapting while keeping its engaging core";
      case 's':
        return "your reliability is being refined while maintaining its steady foundation";
      case 'c':
        return "your precision-focused approach is being adjusted while keeping its analytical core";
      default:
        return "your core personality remains stable while other aspects evolve";
    }
  }

  static String _getStabilityImplication(String dominant) {
    switch (dominant.toLowerCase()) {
      case 'd':
        return "you're comfortable with your current leadership approach";
      case 'i':
        return "you're satisfied with your social engagement style";
      case 's':
        return "you've found a comfortable balance of reliability";
      case 'c':
        return "you're content with your current precision-focused approach";
      default:
        return "you've established a stable behavioral pattern";
    }
  }

  static void _addCombinationInsights(StringBuffer insights, Map<String, double> changes) {
    if (changes['d']! > 3 && changes['i']! > 3) {
      insights.writeln("\n💡 Combined Increase: Your growing Dominance and Influence suggest "
          "you're taking more leadership roles while maintaining strong social connections.");
    }

    if (changes['s']! < -3 && changes['d']! > 3) {
      insights.writeln("\n💡 Interesting Pattern: Decreased Steadiness with increased Dominance "
          "indicates you're becoming more decisive while adapting quicker to change.");
    }

    if (changes['c']! > 3 && changes['i']! < -3) {
      insights.writeln("\n💡 Notable Shift: Increased Compliance with decreased Influence suggests "
          "you're focusing more on precision while reducing social engagement.");
    }
  }
}
