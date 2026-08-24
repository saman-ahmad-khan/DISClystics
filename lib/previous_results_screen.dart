import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'historical_analysis_screen.dart';
import 'pdf_storage_service.dart';
import 'package:easy_localization/easy_localization.dart';

class PreviousResultsScreen extends StatefulWidget {
  final String userId;
  const PreviousResultsScreen({super.key, required this.userId,});

  @override
  State<PreviousResultsScreen> createState() => _PreviousResultsScreenState();
}

class _PreviousResultsScreenState extends State<PreviousResultsScreen> {
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _filteredReports = [];
  bool _isLoading = true;
  String? _activeFilter;
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('results')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .get();

      final reports = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _reports = reports;
        _filteredReports = List.from(_reports);
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackbar('load_reports_error'.tr());
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadAndOpenPdf(String url) async {
    if (url.isEmpty) {
      _showErrorSnackbar('invalid_url_error'.tr());
      return;
    }

    try {
      setState(() => _isLoading = true);
      final dir = await getTemporaryDirectory();
      final fileName = 'DISC_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${dir.path}/$fileName';

      await Dio().download(url, filePath);
      await OpenFile.open(filePath);
    } catch (e) {
      _showErrorSnackbar('pdf_open_error'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReport(String docId) async {
    try {
      setState(() => _isLoading = true);
      await PdfStorageService.deleteReport(docId);
      await _loadReports();
    } catch (e) {
      _showErrorSnackbar('delete_error'.tr());
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = List.from(_reports);

    // Apply factor filter
    if (_activeFilter != null) {
      result = result.where((r) => r['dominantPersonality'] == _activeFilter).toList();
    }

    // Apply date sorting
    result.sort((a, b) {
      final dateA = (a['createdAt'] as Timestamp).toDate();
      final dateB = (b['createdAt'] as Timestamp).toDate();
      return _sortDescending ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });

    setState(() => _filteredReports = result);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Reports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption(),
            const SizedBox(height: 16),
            _buildFactorFilter(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sort By Date', style: const TextStyle(fontWeight: FontWeight.bold)),
        RadioListTile<bool>(
          title: Text('Newest First'),
          value: true,
          groupValue: _sortDescending,
          onChanged: (value) => setState(() {
            _sortDescending = value!;
            _applyFilters();
            Navigator.pop(context);
          }),
        ),
        RadioListTile<bool>(
          title: Text('Oldest First'),
          value: false,
          groupValue: _sortDescending,
          onChanged: (value) => setState(() {
            _sortDescending = value!;
            _applyFilters();
            Navigator.pop(context);
          }),
        ),
      ],
    );
  }

  Widget _buildFactorFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filter By Factor', style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: ['D', 'I', 'S', 'C'].map((factor) => FilterChip(
            label: Text(factor),
            selected: _activeFilter == factor,
            onSelected: (selected) => setState(() {
              _activeFilter = selected ? factor : null;
              _applyFilters();
              Navigator.pop(context);
            }),
          )).toList(),
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _activeFilter = null;
      _sortDescending = true;
      _filteredReports = List.from(_reports);
      Navigator.pop(context);
    });
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('previous_result'.tr()),
        actions: [
          if (_activeFilter != null)
            Chip(
              label: Text('${'filter'.tr()}: $_activeFilter'),
              backgroundColor: Colors.purple.withOpacity(0.2),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: _clearFilters,
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'filter'.tr(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredReports.isEmpty
          ? Center(child: Text('no_reports'.tr()))
          : ListView.builder(
        itemCount: _filteredReports.length,
        itemBuilder: (context, index) {
          final report = _filteredReports[index];
          final dominant = report['dominantPersonality'] ?? 'N/A';
          final createdAt = (report['createdAt'] as Timestamp).toDate();
          final pdfUrl = report['pdfUrl'] ?? '';
          final docId = report['id'];

          return _buildReportCard(
            dominant: dominant,
            createdAt: createdAt,
            pdfUrl: pdfUrl,
            docId: docId,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_filteredReports.length < 2) {
            _showErrorSnackbar('At least two reports are required for analysis');
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HistoricalAnalysisScreen(
                userId: widget.userId,
              ),
            ),
          );
        },
        backgroundColor: Colors.purple,
        tooltip: 'historical_analysis'.tr(),
        child: const Icon(Icons.analytics, color: Colors.white),
      ),
    );
  }

  Widget _buildReportCard({
    required String dominant,
    required DateTime createdAt,
    required String pdfUrl,
    required String docId,
  }) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getFactorColor(dominant),
          child: Text(dominant, style: const TextStyle(color: Colors.white)),
        ),
        title: Text('${'DISC Report'} - $dominant'),
        subtitle: Text(DateFormat.yMMMd().add_jm().format(createdAt)),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDelete(docId),
        ),
        onTap: () => _downloadAndOpenPdf(pdfUrl),
      ),
    );
  }

  Color _getFactorColor(String factor) {
    const colors = {
      'D': Colors.red,
      'I': Colors.amberAccent,
      'S': Colors.green,
      'C': Colors.blue,
    };
    return colors[factor] ?? Colors.grey;
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_report'.tr()),
        content: Text('delete_report_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteReport(docId);
            },
            child: Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}