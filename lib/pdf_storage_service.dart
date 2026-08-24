import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfStorageService {
  static const _key = 'saved_reports';

  static Future<void> saveReport(String filePath, String dominant) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = getReports(prefs);

    reports.add({
      'path': filePath,
      'date': DateTime.now().toIso8601String(),
      'dominant': dominant,
    });

    await prefs.setStringList(_key,
        reports.map((r) => jsonEncode(r)).toList()
    );
  }

  static List<Map<String, dynamic>> getReports(SharedPreferences prefs) {
    final reports = prefs.getStringList(_key) ?? [];
    return reports.map((r) => jsonDecode(r) as Map<String, dynamic>).toList();
  }

  static Future<List<Map<String, dynamic>>> loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    return getReports(prefs);
  }
  static Future<void> deleteReport(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('results')
          .doc(docId)
          .delete();
      print('Deleted document with ID: $docId');
    } catch (e) {
      print('Error deleting document: $e');
    }
  }
}