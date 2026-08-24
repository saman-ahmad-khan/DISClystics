import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:DISClystics/result_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'disc_data.dart';
import 'disc_model.dart';
import 'disc_service.dart';
import 'question_response_firebase.dart';
import 'package:easy_localization/easy_localization.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  _QuestionScreenState createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final Map<int, Map<int, bool>> _selections = {};
  int _currentGroup = 1;

  @override
  Widget build(BuildContext context) {
    final groupQuestions = discQuestions.where((q) => q.group == _currentGroup).toList();
    final groupSelections = _selections[_currentGroup] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text("Question".tr() + " $_currentGroup"),
            Text(
              _getProgressPercentageText(),
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            tooltip: 'Switch Language',
            onPressed: () {
              if (context.locale == Locale('en')) {
                context.setLocale( Locale('ur'));
              } else {
                context.setLocale(Locale('en'));
              }
            },
          ),
        ],
      ),

      body: Column(
        children: [
          _buildProgressHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: groupQuestions.length,
              itemBuilder: (context, index) => _buildQuestionCard(groupQuestions[index], index),
            ),
          ),
          _buildNavigationControls(groupSelections),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    final isUrdu = context.locale.languageCode == 'ur';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        children: [
          Container(
            height: 8,
            child: Row(
              children: List.generate(24, (index) {
                final group = index + 1;
                final values = _selections[group]?.values ?? [];
                final isCompleted =
                    values.where((v) => v == true).length == 1 &&
                        values.where((v) => v == false).length == 1;

                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.deepOrange : Colors.grey[300],
                      borderRadius: _getBorderRadius(index, isUrdu),
                    ),
                    margin: const EdgeInsets.only(right: 2),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select one Most and one Least for this group".tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  BorderRadius _getBorderRadius(int index, bool isUrdu) {
    if (index == 0) {
      return isUrdu
          ? const BorderRadius.horizontal(right: Radius.circular(4))
          : const BorderRadius.horizontal(left: Radius.circular(4));
    } else if (index == 23) {
      return isUrdu
          ? const BorderRadius.horizontal(left: Radius.circular(4))
          : const BorderRadius.horizontal(right: Radius.circular(4));
    }
    return BorderRadius.zero;
  }

  Widget _buildQuestionCard(DiscQuestion question, int index) {
    final groupSelection = _selections[_currentGroup] ?? {};
    final isMost = groupSelection[index] == true;
    final isLeast = groupSelection[index] == false;

    Color? cardColor;
    if (isMost) {
      cardColor = Colors.purple[100];
    } else if (isLeast) {
      cardColor = Colors.orange[100];
    }

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(question.text), style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSelectionButton('most'.tr(), index, isMost),
                _buildSelectionButton('least'.tr(), index, isLeast),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionButton(String label, int index, bool isSelected) {
    final backgroundColor = label == 'most'.tr() ? Colors.purple : Colors.orange;
    final textColor = isSelected ? Colors.white : Colors.black;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? backgroundColor : Colors.grey[300],
        foregroundColor: textColor,
        textStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
      onPressed: () => _handleSelection(index, label == 'most'.tr()),
      child: Text(label),
    );
  }

  void _handleSelection(int index, bool isMost) {
    setState(() {
      final currentSelections = _selections[_currentGroup] ?? {};
      final currentSelection = currentSelections[index];

      if (currentSelection == isMost) {
        // Toggle off if clicking the same selection type again
        currentSelections.remove(index);
      } else {
        // Remove existing selection of the same type (Most/Least)
        final typeToRemove = isMost ? true : false;
        currentSelections.removeWhere((key, value) => value == typeToRemove);

        // Set new selection
        currentSelections[index] = isMost;
      }

      _selections[_currentGroup] = currentSelections;
    });
  }

  Widget _buildNavigationControls(Map<int, bool> groupSelections) {
    final mostCount = groupSelections.values.where((v) => v == true).length;
    final leastCount = groupSelections.values.where((v) => v == false).length;
    final isCurrentGroupComplete = mostCount == 1 && leastCount == 1;
    final isLastGroup = _currentGroup == 24;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: (_currentGroup == 1)
            ? MainAxisAlignment.end
            : MainAxisAlignment.spaceBetween,
        children: [
          if (_currentGroup > 1)
            ElevatedButton(
              onPressed: () => _changeGroup(-1),
              child: Text('previous'.tr()),
            ),
          if (!isLastGroup)
            ElevatedButton(
              onPressed: isCurrentGroupComplete ? () => _changeGroup(1) : null,
              child: Text('next'.tr()),
            ),
          if (isLastGroup)
            ElevatedButton(
              onPressed: _validateAllGroups() ? _showResults : null,
              child: Text('sub'.tr()),
            ),
        ],
      ),
    );
  }

  bool _validateAllGroups() {
    for (int i = 1; i <= 24; i++) {
      final values = _selections[i]?.values ?? [];
      final mostCount = values.where((v) => v == true).length;
      final leastCount = values.where((v) => v == false).length;
      if (mostCount != 1 || leastCount != 1) return false;
    }
    return true;
  }

  void _changeGroup(int delta) {
    setState(() => _currentGroup += delta);
  }
  Future<void> _storeResultsInFirebase(Map<int, Map<int, bool>> selections) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "guest";

    final List<Map<String, dynamic>> responses = [];

    for (int group = 1; group <= 24; group++) {
      final groupSelections = selections[group];
      if (groupSelections == null) continue;

      final groupQuestions = discQuestions.where((q) => q.group == group).toList();

      Map<String, dynamic>? most;
      Map<String, dynamic>? least;

      groupSelections.forEach((index, isMost) {
        final question = groupQuestions[index];
        final questionMap = {
          "question": question.text,
          "index": index,
        };

        if (isMost == true) {
          most = questionMap;
        } else if (isMost == false) {
          least = questionMap;
        }
      });

      responses.add({
        "group": group,
        "most": most,
        "least": least,
      });
    }

    await FirebaseFirestore.instance.collection('disc_responses').doc(userId).set({
      "userId": userId,
      "responses": responses,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }


  void _showResults() async {
    final result = DiscCalculator.calculateResults(_selections);

    // 🔐 Fetch userId from Firebase Auth
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "guest";

    // 🔐 Store results in Firebase first
    await _storeResultsInFirebase(_selections);

    // ✅ Pass result and userId to ResultScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(result: result, userId: userId),
      ),
    );
  }


  double _calculateOverallProgress() {
    int totalAnswered = 0;
    for (var group in _selections.values) {
      final most = group.values.where((v) => v == true).length;
      final least = group.values.where((v) => v == false).length;
      if (most == 1 && least == 1) totalAnswered++;
    }
    return totalAnswered / 24;
  }

  String _getProgressPercentageText() {
    return "${(_calculateOverallProgress() * 100).toStringAsFixed(0)}% Completed";
  }
}