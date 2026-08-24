import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class HistoryService {
  static Future<List<Map<String, dynamic>>> fetchUserHistory(String userId) async {
    try {
      debugPrint("Fetching history for user: $userId");

      final querySnapshot = await FirebaseFirestore.instance
          .collection('results')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      debugPrint("Found ${querySnapshot.docs.length} documents");

      final results = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint("Processing document: ${doc.id}");

        // Ensure we have all required fields
        if (data['createdAt'] == null ||
            data['resultData'] == null ||
            data['dominantPersonality'] == null) {
          debugPrint("Skipping invalid document: ${doc.id}");
          return null;
        }

        return {
          'id': doc.id,
          'date': (data['createdAt'] as Timestamp).toDate(),
          'summary': (data['resultData']['summary'] as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, (v as num).toDouble())),
          'dominant': data['dominantPersonality'] as String,
        };
      }).where((item) => item != null).toList();

      debugPrint("Returning ${results.length} valid historical assessments");
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching history: $e');
      return [];
    }
  }
}