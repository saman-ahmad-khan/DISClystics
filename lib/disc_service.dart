import 'disc_data.dart';
import 'disc_model.dart';
import 'package:easy_localization/easy_localization.dart';
class DiscCalculator {

  static late final Map<String, Map<String, int>> _totals = _calculateTotals();

  static DiscResult calculateResults(Map<int, Map<int, bool>> selections) {
    // Validate selections
    selections.forEach((group, groupSelections) {
      if (groupSelections.length != 2 ||
          groupSelections.values.where((v) => v).length != 1) {
        throw Exception('${'Group $group must have exactly 1 selection'.tr()}');
      }
    });

    Map<String, int> mostScores = {'d': 0, 'i': 0, 's': 0, 'c': 0};
    Map<String, int> leastScores = {'d': 0, 'i': 0, 's': 0, 'c': 0};

    selections.forEach((group, groupSelections) {
      final groupQuestions = discQuestions.where((q) => q.group == group).toList();

      groupSelections.forEach((index, isMost) {
        final question = groupQuestions[index];

        if (isMost) {
          question.most.forEach((key, value) {
            mostScores[key] = mostScores[key]! + value;
          });
        } else {
          question.least.forEach((key, value) {
            leastScores[key] = leastScores[key]! + value;
          });
        }
      });
    });

    return _calculateGraphs(mostScores, leastScores);
  }

  static DiscResult _calculateGraphs(
      Map<String, int> most, Map<String, int> least) {
    final revMap = {'d': 'c', 'i': 's', 's': 'i', 'c': 'd'};

    Map<String, int> internal = {};
    Map<String, int> external = {};

    // Calculate internal graph values
    most.forEach((key, value) {
      final percentage = ((value / _totals['most']![key]!) * 100).round();
      internal[key] = _calculateAdjustedValue(percentage);
    });

    // Calculate external graph values
    least.forEach((key, value) {
      final percentage = ((value / _totals['least']![key]!) * 100).round();
      external[revMap[key]!] = _calculateAdjustedValue(percentage);
    });

    // Calculate summary graph
    Map<String, int> summary = {
      'd': ((internal['d']! + external['d']!) ~/ 2),
      'i': ((internal['i']! + external['i']!) ~/ 2),
      's': ((internal['s']! + external['s']!) ~/ 2),
      'c': ((internal['c']! + external['c']!) ~/ 2),
    };

    // Calculate shift graph
    Map<String, int> shift = {
      'd': external['d']! - internal['d']!,
      'i': external['i']! - internal['i']!,
      's': external['s']! - internal['s']!,
      'c': external['c']! - internal['c']!,
    };

    return DiscResult.fromIntegerMaps(internal, external, summary, shift);
  }

  static double calculateTensionFactor(DiscResult result) {
    double maxShift = 0.0;
    result.shift.forEach((_, value) {
      final absValue = value.abs();
      if (absValue > maxShift) maxShift = absValue;
    });
    return maxShift;
  }

  static double calculateAdaptabilityFactor(Map<String, double> internal) {
    return 100.0 - internal['s']!;
  }


  static int _calculateAdjustedValue(int percentage) {
    int num = 30;
    while (percentage + num > 90) {
      num -= 15;
    }
    return percentage + num;
  }
  static Map<String, dynamic> calculateTensionAdaptabilityComparison(
      DiscResult result) {
    final tension = calculateTensionFactor(result);
    final adaptability = calculateAdaptabilityFactor(result.internal);

    return {
      'tension': tension,
      'adaptability': adaptability,
      'tensionLevel': _getTensionLevel(tension),
      'adaptabilityLevel': _getAdaptabilityLevel(adaptability),
    };
  }

  static String _getTensionLevel(double tension) {
    if (tension < 20) {
      return 'Low';
    } else if (tension < 50) {
      return 'Moderate';
    } else {
      return 'High';
    }
  }

  static String _getAdaptabilityLevel(double adaptability) {
    if (adaptability < 30) {
      return 'Low';
    } else if (adaptability < 60) {
      return 'Moderate';
    } else {
      return 'High';
    }
  }
  static Map<String, Map<String, int>> _calculateTotals() {
    Map<String, int> mostTotals = {'d': 0, 'i': 0, 's': 0, 'c': 0};
    Map<String, int> leastTotals = {'d': 0, 'i': 0, 's': 0, 'c': 0};

    for (final question in discQuestions) {
      question.most.forEach((key, value) {
        mostTotals[key] = mostTotals[key]! + value;
      });
      question.least.forEach((key, value) {
        leastTotals[key] = leastTotals[key]! + value;
      });
    }

    return {'most': mostTotals, 'least': leastTotals};
  }

  static String getQuestionText(int group, int index) {
    final groupQuestions = discQuestions.where((q) => q.group == group).toList();
    return groupQuestions[index].text;
  }
}