import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'history_service.dart';
import 'insight_service.dart';

class HistoricalAnalysisScreen extends StatefulWidget {
  final String userId;

  const HistoricalAnalysisScreen({super.key, required this.userId});

  @override
  State<HistoricalAnalysisScreen> createState() => _HistoricalAnalysisScreenState();
}

class _HistoricalAnalysisScreenState extends State<HistoricalAnalysisScreen> {
  List<Map<String, dynamic>> _historicalData = [];
  bool _isLoading = false;
  bool _isGeneratingInsights = false;
  String _aiInsights = '';
  String _apiError = '';
  bool _usingRuleBasedFallback = false;
  bool _insightsExpanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistoricalData();
  }
  @override
  void dispose() {
    _scrollController.dispose();
    _insightScrollController.dispose();
    super.dispose();
  }


  Future<void> _loadHistoricalData() async {
    setState(() => _isLoading = true);
    try {
      _historicalData = await HistoryService.fetchUserHistory(widget.userId);
      if (_historicalData.isNotEmpty) {
        _preloadInsights();
      }
    } catch (e) {
      print("Error loading historical data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _preloadInsights() {
    if (_historicalData.length > 1) {
      _generateAiInsights();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('historical_analysis'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistoricalData,
            tooltip: 'refresh_data'.tr(),
          )
        ],
      ),
      body: _buildBody(),
    );
  }
  Widget _buildBody() {
    return Stack(
      children: [
        // Scrollable main content with scrollbar
        Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Scrollbar(
            thumbVisibility: true,
            thickness: 6,
            radius: const Radius.circular(8),
            child: RefreshIndicator(
              onRefresh: _loadHistoricalData,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'personality_evolution'.tr(),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildTrendChart()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        'assessment_history'.tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  _isLoading
                      ? _buildHistoryShimmer()
                      : _historicalData.isEmpty
                      ? SliverFillRemaining(
                    child: Center(child: Text('no_historical_data'.tr())),
                  )
                      : _buildHistoryList(),
                  const SliverToBoxAdapter(child: SizedBox(height: 280)), // Spacer for fixed insights panel
                ],
              ),
            ),
          ),
        ),

        // Fixed Personality Insights Panel
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildInsightsPanel(),
        ),
      ],
    );
  }

  Widget _buildTrendChart() {
    if (_historicalData.isEmpty) return Container();

    // Prepare chart data
    final List<ChartData> dData = [];
    final List<ChartData> iData = [];
    final List<ChartData> sData = [];
    final List<ChartData> cData = [];

    for (var i = _historicalData.length - 1; i >= 0; i--) {
      final assessment = _historicalData[i];
      final summary = Map<String, double>.from(assessment['summary']);
      final date = assessment['date'] as DateTime;

      dData.add(ChartData(date, summary['d'] ?? 0, 'D'));
      iData.add(ChartData(date, summary['i'] ?? 0, 'I'));
      sData.add(ChartData(date, summary['s'] ?? 0, 'S'));
      cData.add(ChartData(date, summary['c'] ?? 0, 'C'));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'trait_trends'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(
                  dateFormat: DateFormat.MMMd(),
                  intervalType: DateTimeIntervalType.days,
                  majorGridLines: const MajorGridLines(width: 0),
                  edgeLabelPlacement: EdgeLabelPlacement.shift,
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
                  maximum: 100,
                  interval: 20,
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                ),
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  overflowMode: LegendItemOverflowMode.wrap,
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: [
                  LineSeries<ChartData, DateTime>(
                    dataSource: dData,
                    xValueMapper: (ChartData data, _) => data.date,
                    yValueMapper: (ChartData data, _) => data.value,
                    name: 'Dominance',
                    color: _getTraitColor('d'),
                    markerSettings: const MarkerSettings(isVisible: true),
                    width: 2.5,
                  ),
                  LineSeries<ChartData, DateTime>(
                    dataSource: iData,
                    xValueMapper: (ChartData data, _) => data.date,
                    yValueMapper: (ChartData data, _) => data.value,
                    name: 'Influence',
                    color: _getTraitColor('i'),
                    markerSettings: const MarkerSettings(isVisible: true),
                    width: 2.5,
                  ),
                  LineSeries<ChartData, DateTime>(
                    dataSource: sData,
                    xValueMapper: (ChartData data, _) => data.date,
                    yValueMapper: (ChartData data, _) => data.value,
                    name: 'Steadiness',
                    color: _getTraitColor('s'),
                    markerSettings: const MarkerSettings(isVisible: true),
                    width: 2.5,
                  ),
                  LineSeries<ChartData, DateTime>(
                    dataSource: cData,
                    xValueMapper: (ChartData data, _) => data.date,
                    yValueMapper: (ChartData data, _) => data.value,
                    name: 'Compliance',
                    color: _getTraitColor('c'),
                    markerSettings: const MarkerSettings(isVisible: true),
                    width: 2.5,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryShimmer() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ShimmerHistoryItem(),
        ),
        childCount: 3,
      ),
    );
  }

  Widget _buildHistoryList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final assessment = _historicalData[index];
          final date = assessment['date'] as DateTime;
          final dominant = assessment['dominant'] as String;
          final summary = Map<String, double>.from(assessment['summary']);
          final dominantColor = _getTraitColor(dominant);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildDominantBadge(dominant, dominantColor),
                        const Spacer(),
                        Text(
                          DateFormat.yMMMd().format(date),
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTraitSummary(summary, dominant),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: _historicalData.length,
      ),
    );
  }

  Widget _buildDominantBadge(String dominant, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            '${'dominant_trait'.tr()}: ${dominant.toUpperCase()}',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 13
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraitSummary(Map<String, double> summary, String dominant) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTraitSummaryItem('D', summary['d'] ?? 0, dominant == 'D'),
        _buildTraitSummaryItem('I', summary['i'] ?? 0, dominant == 'I'),
        _buildTraitSummaryItem('S', summary['s'] ?? 0, dominant == 'S'),
        _buildTraitSummaryItem('C', summary['c'] ?? 0, dominant == 'C'),
      ],
    );
  }

  Widget _buildTraitSummaryItem(String trait, double value, bool isDominant) {
    final color = _getTraitColor(trait);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 46,
              height: 46,
              child: CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 4,
                backgroundColor: Colors.grey.shade200,
                color: color.withOpacity(0.3),
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDominant ? color.withOpacity(0.15) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                    color: isDominant ? color : Colors.transparent,
                    width: 1.5
                ),
              ),
              child: Center(
                child: Text(
                  trait,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${value.toStringAsFixed(0)}%',
          style: TextStyle(
              fontWeight: isDominant ? FontWeight.bold : FontWeight.normal,
              color: isDominant ? color : Colors.grey.shade700,
              fontSize: 13
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Column(
        children: [
          // Panel header
          InkWell(
            onTap: () => setState(() => _insightsExpanded = !_insightsExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                children: [
                  Icon(
                    _insightsExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'personality_insights'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (_historicalData.length > 1)
                    IconButton(
                      icon: _isGeneratingInsights
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
                      onPressed: _generateAiInsights,
                      tooltip: 'generate_insights'.tr(),
                    ),
                ],
              ),
            ),
          ),

          // Content area
          if (_insightsExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_apiError.isNotEmpty) _buildErrorSection(),

                  if (_aiInsights.isEmpty && !_isGeneratingInsights)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'insights_placeholder'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else if (_isGeneratingInsights)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Container(
                      height: MediaQuery.of(context).size.height * 0.4, // 40% of screen height
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Scrollbar(
                        controller: _insightScrollController,
                        thumbVisibility: true,
                        thickness: 6,
                        radius: const Radius.circular(8),
                        child: SingleChildScrollView(
                          controller: _insightScrollController,
                          child: Text(
                            _aiInsights,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  if (_usingRuleBasedFallback)
                    Text(
                      'rule_based_fallback'.tr(),
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  final ScrollController _insightScrollController = ScrollController();


  Widget _buildErrorSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'api_error'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _apiError,
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
        ],
      ),
    );
  }
  Future<void> _generateAiInsights() async {
    if (_historicalData.isEmpty || _isGeneratingInsights) return;

    setState(() {
      _isGeneratingInsights = true;
      _apiError = '';
      _usingRuleBasedFallback = false;
    });

    try {
      final current = Map<String, double>.from(_historicalData.first['summary']);
      final previous = _historicalData.length > 1
          ? Map<String, double>.from(_historicalData[1]['summary'])
          : current;

      final currentDominant = _historicalData.first['dominant'] as String;
      final previousDominant = _historicalData.length > 1
          ? _historicalData[1]['dominant'] as String
          : currentDominant;

      // Attempt to get AI insights
      _aiInsights = await InsightService.generateInsights(
        "User",
        currentDominant,
        previousDominant,
        current,
        previous,
        context.locale,
      );

      // Check if we got rule-based fallback
      if (_aiInsights.contains("Your profile shows") ||
          _aiInsights.contains("Combined Increase") ||
          _aiInsights.contains("Your primary personality")) {
        _usingRuleBasedFallback = true;
        _apiError = 'AI insights unavailable (fallback triggered)';
      }
    } catch (e) {
      _handleInsightError(e);
    } finally {
      setState(() => _isGeneratingInsights = false);
    }
  }

  void _handleInsightError(dynamic error) {
    final errorStr = error.toString();
    print('AI Insight Generation Error: $errorStr');

    // Calculate changes for rule-based fallback
    final current = Map<String, double>.from(_historicalData.first['summary']);
    final previous = _historicalData.length > 1
        ? Map<String, double>.from(_historicalData[1]['summary'])
        : current;

    final changes = {
      'd': current['d']! - (previous['d'] ?? 0),
      'i': current['i']! - (previous['i'] ?? 0),
      's': current['s']! - (previous['s'] ?? 0),
      'c': current['c']! - (previous['c'] ?? 0),
    };

    final currentDominant = _historicalData.first['dominant'] as String;
    final previousDominant = _historicalData.length > 1
        ? _historicalData[1]['dominant'] as String
        : currentDominant;

    // Use rule-based as fallback
    _aiInsights = InsightService.ruleBasedInsights(
      currentDominant,
      previousDominant,
      changes,
    );

    _usingRuleBasedFallback = true;

    // Parse specific error conditions
    if (errorStr.contains('model not found')) {
      _apiError = 'API Error: Invalid model configuration\n'
          'Reason: The model "gemini-pro" is deprecated\n'
          'Solution: Update to "gemini-2.5-flash-preview-05-20" in InsightService';
    }
    else if (errorStr.contains('quota')) {
      _apiError = 'API Error: Quota exceeded\n'
          'Reason: You\'ve exceeded your Gemini API quota\n'
          'Solution: Check usage in Google Cloud Console';
    }
    else if (errorStr.contains('network')) {
      _apiError = 'Network Error: Connection failed\n'
          'Reason: No internet connection or blocked API\n'
          'Solution: Check your network connection';
    }
    else if (errorStr.contains('API key')) {
      _apiError = 'Authentication Error: Invalid API key\n'
          'Reason: The provided API key is invalid or restricted\n'
          'Solution: Verify API key in Google Cloud Console';
    }
    else if (errorStr.contains('safety')) {
      _apiError = 'Content Safety Error: Blocked response\n'
          'Reason: Prompt triggered safety filters\n'
          'Solution: Adjust prompt content';
    }
    else {
      _apiError = 'API Error: $errorStr\n'
          'Reason: Unexpected error with Gemini API\n'
          'Solution: Check error logs for details';
    }

    // Add troubleshooting tips
    _apiError += '\n\nTroubleshooting:';
    _apiError += '\n• Verify model name in InsightService';
    _apiError += '\n• Check API key permissions';
    _apiError += '\n• Test API connection with curl command';
    _apiError += '\n• Review Google Cloud error logs';
  }
}
Color _getTraitColor(String trait) {
  switch (trait.toLowerCase()) {
    case 'd': return const Color(0xFFE53935); // Red
    case 'i': return const Color(0xFFFFB300); // Amber
    case 's': return const Color(0xFF43A047); // Green
    case 'c': return const Color(0xFF1E88E5); // Blue
    default: return Colors.grey;
  }
}

class ChartData {
  final DateTime date;
  final double value;
  final String trait;

  ChartData(this.date, this.value, this.trait);
}

class ShimmerHistoryItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBox(width: 120, height: 24),
                Spacer(),
                ShimmerBox(width: 80, height: 16),
              ],
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerCircle(size: 48),
                ShimmerCircle(size: 48),
                ShimmerCircle(size: 48),
                ShimmerCircle(size: 48),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerBox({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }
}