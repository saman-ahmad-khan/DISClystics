import 'package:cloud_firestore/cloud_firestore.dart';

class DiscFirestoreService {
  final CollectionReference userResponses =
  FirebaseFirestore.instance.collection('user_responses');

  Future<void> saveUserResponse(String userId, Map<int, Map<int, bool>> selections) async {
    final List<Map<String, dynamic>> responses = [];

    selections.forEach((group, groupSelections) {
      int? mostIndex;
      int? leastIndex;

      groupSelections.forEach((index, isMost) {
        if (isMost == true) mostIndex = index;
        if (isMost == false) leastIndex = index;
      });

      if (mostIndex != null && leastIndex != null) {
        responses.add({
          'group': group,
          'most': mostIndex,
          'least': leastIndex,
        });
      }
    });

    await userResponses.add({
      'userId': userId,
      'submittedAt': Timestamp.now(),
      'responses': responses,
    });
  }
}
