import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'disc_model.dart';
import 'package:easy_localization/easy_localization.dart';

class DiscPdfGenerator {
  final DiscResult result;
  final List<Map<String, String>> sectionHeaders;
  final String? userName;
  final List<Map<String, dynamic>> historicalData;

  DiscPdfGenerator(this.result, this.sectionHeaders, this.userName,  {this.historicalData = const []} );

  void _addHistoricalComparisonSection(
      pw.Document pdf,
      Map<String, Uint8List> images,
      ) {
    final historicalImage = images['historical_comparison'];
    if (historicalImage == null) return;

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Historical Comparison',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.purple,
                ),
              ),
              pw.SizedBox(height: 20),

              // Image Centered
              pw.Center(
                child: pw.Container(
                  width: 400,
                  child: pw.Image(pw.MemoryImage(historicalImage)),
                ),
              ),

              pw.SizedBox(height: 20),

              // Disclaimer if historical data is limited
              if (historicalData.length < 2)
                pw.Text(
                  '* Based on limited historical data',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }


  pw.Widget _buildDiscValueRow(String label, double? value) {
    return pw.Container(
      width: 180,
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple)),
            pw.Text('${value?.toStringAsFixed(0) ?? "0"} %',
                style: pw.TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildPdfHeader() {
    return pw.Container(
      color: PdfColors.purple,
      padding: const pw.EdgeInsets.all(5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'DISC Assessment Report',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 2),
          if (userName != null)
            pw.Text(
              'Personality Profile Analysis: $userName',
              style: pw.TextStyle(
                fontSize: 14,
                color: PdfColors.grey300,
              ),
            ),
          pw.SizedBox(height: 5),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
        ],
      ),
    );
  }

  pw.Widget _buildProfileCard(Map<String, dynamic> data) {
    final imageBytes = data['image'] as Uint8List?;
    final labelsBytes = data['labels'] as Uint8List?;

    if (data['title']?.toString().toLowerCase() == 'historical comparison' && imageBytes != null) {
      return pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(bottom: 20),
        child: pw.Image(pw.MemoryImage(imageBytes)),
      );
    }


    if (imageBytes == null) return pw.SizedBox();

    return pw.Container(
      width: 240,
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Image(pw.MemoryImage(imageBytes)),
          pw.SizedBox(height: 12),
          if (labelsBytes != null)
            pw.Image(pw.MemoryImage(labelsBytes))
          else ...[
            _buildDiscValueRow("d".tr(), (data['values'] as Map)['d']),
            _buildDiscValueRow("i".tr(), (data['values'] as Map)['i']),
            _buildDiscValueRow("s".tr(), (data['values'] as Map)['s']),
            _buildDiscValueRow("c".tr(), (data['values'] as Map)['c']),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildSectionHeaderImage(
      Uint8List? titleImage, Uint8List? descriptionImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (titleImage != null)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: pw.BoxDecoration(
              color: PdfColors.deepOrange,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(4),
                topRight: pw.Radius.circular(4),
              ),
            ),
            child: pw.Image(pw.MemoryImage(titleImage)),
          ),
        if (descriptionImage != null)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(4),
                bottomRight: pw.Radius.circular(4),
              ),
            ),
            child: pw.Image(pw.MemoryImage(descriptionImage)),
          ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  Future<Uint8List> generatePdf(Map<String, Uint8List> images) async {
    final pdf = pw.Document();
    final sectionTypes = ['internal', 'external', 'summary', 'shift'];

    // Prepare data for the profile cards
    final graphData = [
      {
        'title': 'in_profile'.tr(),
        'values': result.internal,
        'image': images['internal_graph'],
        'labels': images['internal_labels'],
      },
      {
        'title': 'en_profile'.tr(),
        'values': result.external,
        'image': images['external_graph'],
        'labels': images['external_labels'],
      },
      {
        'title': 'sm_profile'.tr(),
        'values': result.summary,
        'image': images['summary_graph'],
        'labels': images['summary_labels'],
      },
      {
        'title': 'shift_p'.tr(),
        'values': result.shift,
        'image': images['shift_graph'],
        'labels': images['shift_labels'],
      },
    ];

    // Create pages with two profiles each
    for (int i = 0; i < graphData.length; i += 2) {
      final first = graphData[i];
      final second = i + 1 < graphData.length ? graphData[i + 1] : null;

      // Get section headers by index
      final firstType = i < sectionTypes.length ? sectionTypes[i] : null;
      final secondType = i + 1 < sectionTypes.length
          ? sectionTypes[i + 1]
          : null;

      // Get title and description images by section type
      final firstTitleImage = firstType != null
          ? images['${firstType}_title']
          : null;
      final firstDescImage = firstType != null
          ? images['${firstType}_desc']
          : null;
      final secondTitleImage = secondType != null
          ? images['${secondType}_title']
          : null;
      final secondDescImage = secondType != null
          ? images['${secondType}_desc']
          : null;

      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(20),
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPdfHeader(),
                pw.SizedBox(height: 30),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Profile cards column
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          _buildProfileCard(first),
                          if (second != null) pw.SizedBox(height: 30),
                          if (second != null) _buildProfileCard(second),
                        ],
                      ),
                    ),

                    pw.SizedBox(width: 20),

                    // Section headers column
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          _buildSectionHeaderImage(
                              firstTitleImage, firstDescImage),
                          if (second != null && secondTitleImage != null &&
                              secondDescImage != null)
                            pw.SizedBox(height: 120),
                          _buildSectionHeaderImage(
                              secondTitleImage, secondDescImage),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    // Add personality description and tension
    final dominant = result.summary.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    final description = _getDescription(dominant);
    final tensionImage = images['tension'];
    final adaptabilityImage = images['adaptability'];
    final comparisonImage = images['comparison'];

// Create a page for tension and adaptability (without comparisonImage)
    if (tensionImage != null || adaptabilityImage != null) {
      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(20),
          build: (context) =>
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildPdfHeader(),
                  pw.SizedBox(height: 10),
                  if (images['primary_personality'] != null)
                    pw.Center(
                      child: pw.Image(pw.MemoryImage(images['primary_personality']!)),
                    )
                  else ...[
                    pw.Text('your_primary'.tr() + ': ${dominant.toUpperCase()}',
                        style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black)),
                    pw.SizedBox(height: 8),
                    pw.Text(description,
                        style: const pw.TextStyle(fontSize: 14),
                        textAlign: pw.TextAlign.justify),
                  ],
                  pw.SizedBox(height: 20),
                  if (tensionImage != null)
                    pw.Center(
                      child: pw.Container(
                        width: 400,
                        child: pw.Image(pw.MemoryImage(tensionImage)),
                      ),
                    ),
                  if (adaptabilityImage != null)
                    pw.Center(
                      child: pw.Container(
                        width: 400,
                        margin: const pw.EdgeInsets.only(top: 20),
                        child: pw.Image(pw.MemoryImage(adaptabilityImage)),
                      ),
                    ),
                ],
              ),
        ),
      );
    }

// Create a separate page for the comparison image
    if (comparisonImage != null) {
      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(20),
          build: (context) =>
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildPdfHeader(),
                  pw.SizedBox(height: 30),
                  pw.Center(
                    child: pw.Container(
                      width: 400,
                      child: pw.Image(pw.MemoryImage(comparisonImage)),
                    ),
                  ),
                ],
              ),
        ),
      );
    }
    if (images.containsKey('historical_comparison')) {
      _addHistoricalComparisonSection(pdf, images);
    }

    return pdf.save();
  }
    String _getDescription(String type) {
    final descriptions = {
      'd': 'd_result'.tr(),
      'i': 'i_result'.tr(),
      's': 's_result'.tr(),
      'c': 'c_result'.tr(),
    };
    return descriptions[type.toLowerCase()] ?? 'No description available';
  }
}