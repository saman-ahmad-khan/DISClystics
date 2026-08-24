import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:DISClystics/pdf_loader.dart';
import 'package:DISClystics/pdf_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'disc_graphic_painter.dart';
import 'disc_model.dart';
import 'disc_service.dart';
import 'history_service.dart';
import 'insight_service.dart';
import 'shift_graphic_painter.dart';
import 'pdf_generator.dart';
import 'package:easy_localization/easy_localization.dart';

class ResultScreen extends StatefulWidget {
  final DiscResult result;
  final String userId;

  const ResultScreen({super.key, required this.result,   required this.userId,});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final GlobalKey _internalGraphKey = GlobalKey();
  final GlobalKey _externalGraphKey = GlobalKey();
  final GlobalKey _summaryGraphKey = GlobalKey();
  final GlobalKey _shiftGraphKey = GlobalKey();
  final GlobalKey _tensionBarKey = GlobalKey();
  final GlobalKey _adaptabilityKey = GlobalKey();
  final GlobalKey _comparisonKey = GlobalKey();
  final GlobalKey _internalTitleKey = GlobalKey();
  final GlobalKey _internalDescKey = GlobalKey();
  final GlobalKey _externalTitleKey = GlobalKey();
  final GlobalKey _externalDescKey = GlobalKey();
  final GlobalKey _summaryTitleKey = GlobalKey();
  final GlobalKey _summaryDescKey = GlobalKey();
  final GlobalKey _shiftTitleKey = GlobalKey();
  final GlobalKey _shiftDescKey = GlobalKey();
  final GlobalKey _internalLabelsKey = GlobalKey();
  final GlobalKey _externalLabelsKey = GlobalKey();
  final GlobalKey _summaryLabelsKey = GlobalKey();
  final GlobalKey _shiftLabelsKey = GlobalKey();
  final GlobalKey _primaryPersonalityKey = GlobalKey();


  bool get isRTL => context.locale.languageCode == 'ur';
  bool _isGenerating = false;
  bool _isSaving = false;

  // Cloudinary configuration
  final String _cloudinaryPdfUploadUrl =
      'https://api.cloudinary.com/v1_1/ddxwnqqbu/raw/upload';
  final String _pdfUploadPreset = 'flutter_unsigned_pdf';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }


  Widget _buildTensionSection() {
    double tension = DiscCalculator.calculateTensionFactor(widget.result);
    double tensionPercentage = (tension / 100) * 100;

    return RepaintBoundary(
      key: _tensionBarKey,
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'tension_level'.tr(),
                style: TextStyle(fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple),
              ),
              const SizedBox(height: 8),
              Text(
                'tension_para'.tr(),
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = constraints.maxWidth;
                  final filledWidth = (tensionPercentage / 100) * barWidth;

                  return Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: filledWidth,
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Center(
                          child: Text(
                            '${tensionPercentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (_) {
                  if (tensionPercentage < 20) {
                    return Text(
                        "low".tr(), style: TextStyle(color: Colors.green));
                  } else if (tensionPercentage < 50) {
                    return Text(
                        "mid".tr(), style: TextStyle(color: Colors.orange));
                  } else {
                    return Text(
                        "high".tr(), style: TextStyle(color: Colors.red));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildAdaptabilitySection() {
    double adaptability = DiscCalculator.calculateAdaptabilityFactor(
        widget.result.internal);


    return RepaintBoundary(
      key: _adaptabilityKey,
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('adap'.tr(), style: TextStyle(fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple)),
              const SizedBox(height: 8),
              Text('adap_para'.tr(), style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = constraints.maxWidth;
                  final filledWidth = (adaptability / 100) * barWidth;

                  return Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: filledWidth,
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Center(
                          child: Text(
                            '${adaptability.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Builder(builder: (_) {
                if (adaptability < 21) {
                  return Text(
                      "adaplow".tr(), style: TextStyle(color: Colors.red));
                } else {
                  return Text(
                      "adaphigh".tr(), style: TextStyle(color: Colors.green));
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTensionAdaptabilityComparison() {
    final comparison = DiscCalculator.calculateTensionAdaptabilityComparison(
        widget.result);

    return RepaintBoundary(
      key: _comparisonKey,
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tension_Adaptability_Comparison'.tr(),
                style: TextStyle(fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple),
              ),
              const SizedBox(height: 8),
              Text(
                'comp1'.tr(),
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _buildComparisonBar(
                comparison['tension']!,
                comparison['adaptability']!,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonBar(double tension, double adaptability) {
    double total = tension + adaptability;
    double remaining = 100 - total;

    // Clamp values to avoid overflow
    tension = tension.clamp(0, 100);
    adaptability = adaptability.clamp(0, 100 - tension);
    remaining = (100 - tension - adaptability).clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top labels
        Row(
          children: [
            Text('tension'.tr() + ': ${tension.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),

        // Combined bar
        Container(
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[300],
          ),
          child: Row(
            children: [
              Flexible(
                flex: (tension * 1000).toInt(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: isRTL
                        ? const BorderRadius.horizontal(
                        right: Radius.circular(8))
                        : const BorderRadius.horizontal(
                        left: Radius.circular(8)),
                  ),
                ),
              ),
              Flexible(
                flex: (adaptability * 1000).toInt(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: isRTL
                        ? const BorderRadius.horizontal(
                        left: Radius.circular(8))
                        : const BorderRadius.horizontal(
                        right: Radius.circular(8)),
                  ),
                ),
              ),
              Flexible(
                flex: (remaining * 1000).toInt(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: isRTL
                        ? const BorderRadius.horizontal(
                        left: Radius.circular(8))
                        : const BorderRadius.horizontal(
                        right: Radius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        // Top labels
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ad'.tr() + ': ${adaptability.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),


        // Legend below the bar
        Row(
          children: [
            _buildLegendItem(Colors.purple, 'tension'.tr()),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.deepOrange, 'ad'.tr()),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }

  Widget _buildFullContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionHeader(
            'in_profile'.tr(),
            'in_profile_com'.tr(),
            titleKey: _internalTitleKey,
            descKey: _internalDescKey,
          ),
          _buildProfileSection(
              "in_profile".tr(), "in_profile_com".tr(), widget.result.internal,
              key: _internalGraphKey),

          buildSectionHeader(
            'en_profile'.tr(),
            'en_profile_com'.tr(),
            titleKey: _externalTitleKey,
            descKey: _externalDescKey,
          ),
          _buildProfileSection(
              "en_profile".tr(), "en_profile_com".tr(), widget.result.external,
              key: _externalGraphKey),

          buildSectionHeader(
            'sm_profile'.tr(),
            'sm_profile_com'.tr(),
            titleKey: _summaryTitleKey,
            descKey: _summaryDescKey,
          ),
          _buildProfileSection(
              "sm_profile".tr(), "sm_profile_com".tr(), widget.result.summary,
              key: _summaryGraphKey),

          buildSectionHeader(
            'be_shift'.tr(),
            'be_shift_com'.tr(),
            titleKey: _shiftTitleKey,
            descKey: _shiftDescKey,
          ),
          _buildProfileSection(
              "shift_p".tr(), "be_shift_com".tr(), widget.result.shift,
              key: _shiftGraphKey),
          RepaintBoundary(
            key: _primaryPersonalityKey,
            child: _buildPersonalityDescription(),
          ),
          _buildTensionSection(),
          _buildAdaptabilitySection(),
          _buildTensionAdaptabilityComparison(),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String title, String description,
      Map<String, double> values, {Key? key}) {
    final double graphHeight = title == "shift_p".tr() ? 280 : 160;

    // Select correct labelsKey
    final labelsKey = title == "in_profile".tr()
        ? _internalLabelsKey
        : title == "en_profile".tr()
        ? _externalLabelsKey
        : title == "sm_profile".tr()
        ? _summaryLabelsKey
        : _shiftLabelsKey;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            RepaintBoundary(
              key: key,
              child: SizedBox(
                height: graphHeight,
                child: CustomPaint(
                  painter: title == "shift_p".tr()
                      ? ShiftGraphicPainter(values)
                      : DiscGraphicPainter(values),
                  child: Container(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            RepaintBoundary(
              key: labelsKey,
              child: Column(
                children: [
                  _buildLabelRow('d'.tr(), values['d']),
                  _buildLabelRow('i'.tr(), values['i']),
                  _buildLabelRow('s'.tr(), values['s']),
                  _buildLabelRow('c'.tr(), values['c']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelRow(String label, double? value) {
    final rawValue = value ?? 0;
    String percentageText;

    if (isRTL) {
      // Handle Urdu formatting: numbers stay Arabic but negative sign moves to end
      percentageText = rawValue.isNegative
          ? "${(rawValue.abs()).toStringAsFixed(0)}%- "
          : "${rawValue.toStringAsFixed(0)}%  ";
    } else {
      // Standard English formatting
      percentageText = "${rawValue.toStringAsFixed(0)}%";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label with proper RTL alignment
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
                fontSize: 16,
              ),
              textAlign: isRTL ? TextAlign.right : TextAlign.left,
            ),
          ),

          // Percentage value with locale-specific formatting
          Text(
            percentageText,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalityDescription() {
    final dominant = widget.result.summary.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('your_primary'.tr() + ' ${dominant.toUpperCase()}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Text(_getDescription(dominant)),
      ],
    );
  }

  Widget buildSectionHeader(String title, String description,
      {Key? titleKey, Key? descKey}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RepaintBoundary(
          key: titleKey,
          child: Container(
            width: double.infinity,
            color: const Color(0xFFFF5722),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        RepaintBoundary(
          key: descKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getDescription(String type) {
    final Map<String, String> descriptions = {
      'd': 'd_result'.tr(),
      'i': 'i_result'.tr(),
      's': 's_result'.tr(),
      'c': 'c_result'.tr(),
    };
    return descriptions[type.toLowerCase()] ?? 'No description available';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('result'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _isGenerating ? null : _generatePdfWithAllGraphs,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: _buildFullContent(),
      ),
    );
  }

  Future<Uint8List?> _captureGraphImage(GlobalKey key) async {
    try {
      final context = key.currentContext;
      if (context != null) {
        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }

      await Future.delayed(const Duration(milliseconds: 100));

      RenderRepaintBoundary boundary = key.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.5);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print("Capture failed: $e");
      return null;
    }
  }

  String _getDominantPersonality() {
    return widget.result.summary.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key
        .toUpperCase();
  }

  Future<String?> _uploadPdfToCloudinary(Uint8List pdfBytes) async {
    try {
      final uri = Uri.parse(_cloudinaryPdfUploadUrl);
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _pdfUploadPreset
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          pdfBytes,
          filename: 'disc_report_${DateTime
              .now()
              .millisecondsSinceEpoch}.pdf',
        ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        // Return original URL without any transformations
        return jsonResponse['secure_url'] as String;
      } else {
        print('Cloudinary upload failed: ${response.statusCode}');
        print('Response: $responseBody');
        return null;
      }
    } catch (e) {
      print('PDF upload error: $e');
      return null;
    }
  }

// Firestore saving to store original URL
  Future<void> _saveResultToFirestore(String pdfUrl) async {
    try {
      await FirebaseFirestore.instance.collection('results').add({
        'userId': widget.userId,
        'pdfUrl': pdfUrl, // Original Cloudinary URL
        'dominantPersonality': _getDominantPersonality(),
        'createdAt': Timestamp.now(),
        'resultData': {
          'internal': widget.result.internal,
          'external': widget.result.external,
          'summary': widget.result.summary,
          'shift': widget.result.shift,
        }
      });
    } catch (e) {
      print('Firestore save error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save results: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add these helper methods within the _ResultScreenState class

  Future<Map<String, Uint8List>> _captureAllGraphsImages() async {
    final images = <String, Uint8List>{};

    final sections = [
      {
        'titleKey': _internalTitleKey,
        'descKey': _internalDescKey,
        'graphKey': _internalGraphKey,
        'labelsKey': _internalLabelsKey,
        'type': 'internal'
      },
      {
        'titleKey': _externalTitleKey,
        'descKey': _externalDescKey,
        'graphKey': _externalGraphKey,
        'labelsKey': _externalLabelsKey,
        'type': 'external'
      },
      {
        'titleKey': _summaryTitleKey,
        'descKey': _summaryDescKey,
        'graphKey': _summaryGraphKey,
        'labelsKey': _summaryLabelsKey,
        'type': 'summary'
      },
      {
        'titleKey': _shiftTitleKey,
        'descKey': _shiftDescKey,
        'graphKey': _shiftGraphKey,
        'labelsKey': _shiftLabelsKey,
        'type': 'shift'
      },
      {
        'key': _primaryPersonalityKey,
        'type': 'primary_personality',
      },
      {'key': _tensionBarKey, 'type': 'tension'},
      {'key': _adaptabilityKey, 'type': 'adaptability'},
      {'key': _comparisonKey, 'type': 'comparison'},
    ];

    for (var section in sections) {
      if (section['titleKey'] != null) {
        final titleImage = await _captureGraphImage(
            section['titleKey'] as GlobalKey);
        if (titleImage != null) images['${section['type']}_title'] = titleImage;

        final descImage = await _captureGraphImage(
            section['descKey'] as GlobalKey);
        if (descImage != null) images['${section['type']}_desc'] = descImage;
      }

      if (section['graphKey'] != null) {
        final graphImage = await _captureGraphImage(
            section['graphKey'] as GlobalKey);
        if (graphImage != null) images['${section['type']}_graph'] = graphImage;
      }
      if (section['labelsKey'] != null) {
        final labelsImage = await _captureGraphImage(
            section['labelsKey'] as GlobalKey);
        if (labelsImage != null)
          images['${section['type']}_labels'] = labelsImage;
      }

      if (section['key'] != null) {
        final image = await _captureGraphImage(section['key'] as GlobalKey);
        if (image != null) images[section['type'] as String] = image;
      }
    }

    return images;
  }

  Future<Uint8List> _generatePdfBytes(Map<String, Uint8List> images) async {
    final sectionHeaders = [
      {
        'title': 'in_profile'.tr(),
        'description': 'para1'.tr(),
      },
      {
        'title': 'en_profile'.tr(),
        'description': 'para2'.tr(),
      },
      {
        'title': 'sm_profile'.tr(),
        'description': 'para3'.tr(),
      },
      {
        'title': 'be_shift'.tr(),
        'description': 'para4'.tr(),
      },
    ];
    final userName = await _fetchUserName(); // Fetch user name

    return await DiscPdfGenerator(widget.result, sectionHeaders, userName )
        .generatePdf(images.cast<String, Uint8List>());
  }

  Future<String?> _fetchUserName() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        return userDoc['name'] as String?;
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }
    return null;
  }

  String _monthName(int month) {
    const months = [
      '', // 0th index placeholder
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  Future<void> _saveAndShareReport(Uint8List pdfBytes) async {
    String? cloudinaryUrl;
    try {
      cloudinaryUrl = await _uploadPdfToCloudinary(pdfBytes);
      if (cloudinaryUrl != null) {
        await _saveResultToFirestore(cloudinaryUrl);
      }
    } catch (e) {
      print('Cloud/Firestore error: $e');
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final userName = await _fetchUserName() ?? 'User';
      final sanitizedUserName = userName.replaceAll(RegExp(r'[^\w\s]+'), '');
      final now = DateTime.now();
      final formattedDate = '${now.day.toString().padLeft(2, '0')} ${_monthName(
          now.month)} ${now.year}';

      final fileName = 'DISC Report ${sanitizedUserName}-${formattedDate}.pdf';

      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(pdfBytes);

      await Share.shareXFiles([XFile(tempFile.path)],
          text: 'My DISC Personality Report',
          subject: 'DISC Personality Assessment Results');

      await PdfStorageService.saveReport(
        tempFile.path,
        _getDominantPersonality(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('r_saved'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Local save/share error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'PDF generated but failed to save/share: ${e.toString()}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  final ValueNotifier<double> _progressNotifier = ValueNotifier(0.0);

  @override
  void dispose() {
    _progressNotifier.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
  }
  Future<void> _generatePdfWithAllGraphs() async {
    setState(() => _isGenerating = true);

    // Reset progress BEFORE showing the dialog
    _progressNotifier.value = 0.0;

    // Show loader once
    showPdfLoader(
      context,
      progressNotifier: _progressNotifier,
      customMessage: 'Exporting Report.....',
    );

    try {
      // Simulate steps (for example purpose)
      const totalSteps = 10;
      for (int i = 1; i <= totalSteps; i++) {
        await Future.delayed(const Duration(milliseconds: 150));
        _progressNotifier.value = i / totalSteps * 0.4; // Up to 40%
      }

      final images = await _captureAllGraphsImages();
      _progressNotifier.value = 0.6;

      final pdfBytes = await _generatePdfBytes(images);
      _progressNotifier.value = 0.8;

      await _saveAndShareReport(pdfBytes);
      _progressNotifier.value = 0.95;

      await Future.delayed(const Duration(milliseconds: 300));
      _progressNotifier.value = 1.0;

      await Future.delayed(
          const Duration(milliseconds: 500)); // small pause to show 100%
    } catch (e) {
      print('Unexpected error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_to_generate'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        hidePdfLoader(context);
        setState(() => _isGenerating = false);
        _progressNotifier.value = 0.0;
      }
    }
  }
}