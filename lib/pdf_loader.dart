import 'package:flutter/material.dart';
import 'dart:math' as math;

class DisclysticsLoader extends StatefulWidget {
  final String message;
  final ValueNotifier<double> progressNotifier;

  const DisclysticsLoader({
    super.key,
    required this.message,
    required this.progressNotifier,
  });

  @override
  State<DisclysticsLoader> createState() => _DisclysticsLoaderState();
}

class _DisclysticsLoaderState extends State<DisclysticsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: ValueListenableBuilder<double>(
                valueListenable: widget.progressNotifier,
                builder: (_, progress, __) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(60, 60),
                        painter: _ProgressRingPainter(
                          progress.clamp(0.0, 1.0),
                          color: theme.primaryColor,
                        ),
                      ),
                      RotationTransition(
                        turns: _rotationController,
                        child: CustomPaint(
                          size: const Size(60, 60),
                          painter: _RotatingArcPainter(
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                      Text(
                        "${(progress * 100).toInt()}%",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Please wait', // ignore: avoid_hard_coded_text
              style: TextStyle(
                fontSize: 12,
                color: theme.hintColor,
                decoration: TextDecoration.none, // 🚫 Remove underline if present
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressRingPainter(this.progress, {required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 5.0;
    final radius = (size.width / 2) - strokeWidth;

    final bgPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _RotatingArcPainter extends CustomPainter {
  final Color color;

  _RotatingArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 5.0;
    final radius = (size.width / 2) - strokeWidth;

    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final startAngle = -math.pi / 2;
    final sweepAngle = math.pi / 3;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Show loader
void showPdfLoader(
    BuildContext context, {
      required ValueNotifier<double> progressNotifier,
      String? customMessage,
    }) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (_) => DisclysticsLoader(
      message: customMessage ?? 'Generating Report...',
      progressNotifier: progressNotifier,
    ),
  );
}

// Hide loader
void hidePdfLoader(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}
