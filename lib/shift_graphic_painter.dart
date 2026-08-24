import 'package:flutter/material.dart';

class ShiftGraphicPainter extends CustomPainter {
  final Map<String, double> values;
  final List<String> labels = ['D', 'I', 'S', 'C'];

  ShiftGraphicPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Margins
    final double leftMargin = 36;
    final double rightMargin = 16;
    final double topMargin = 24;
    final double bottomMargin = 36;

    final usableWidth = width - leftMargin - rightMargin;
    final usableHeight = height - topMargin - bottomMargin;
    final zeroY = topMargin + usableHeight / 2;  // Zero line position

    // Background (matches other graphs)
    final backgroundPaint = Paint()
      ..color = Colors.blue.shade50
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);

    // Grid line paint (matches other graphs)
    final gridPaint = Paint()
      ..color = Colors.purple.shade100
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal grid lines at 25 unit intervals
    for (int i = -4; i <= 4; i++) {
      double value = i * 25;
      double y = zeroY - (usableHeight / 2) * (value / 100);

      // Draw line
      canvas.drawLine(Offset(leftMargin, y), Offset(width, y), gridPaint);
    }

    // Bar paints (positive matches DISC line color, negative is amber)
    final positiveBarPaint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.fill;

    final negativeBarPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;

    // Bar parameters
    final barSpacing = usableWidth / (labels.length + 1);
    final barWidth = barSpacing * 0.5;

    // Draw bars
    for (int i = 0; i < labels.length; i++) {
      String label = labels[i].toLowerCase();
      double value = values[label] ?? 0;

      // Calculate bar position
      double x = leftMargin + barSpacing * (i + 1) - barWidth / 2;
      double barTop, barBottom;
      Paint barPaint;

      if (value >= 0) {
        // Positive bar (above zero line)
        barTop = zeroY - (usableHeight / 2) * (value / 100);
        barBottom = zeroY;
        barPaint = positiveBarPaint;
      } else {
        // Negative bar (below zero line)
        barTop = zeroY;
        barBottom = zeroY + (usableHeight / 2) * (value.abs() / 100);
        barPaint = negativeBarPaint;
      }

      // Draw bar
      Rect barRect = Rect.fromLTRB(x, barTop, x + barWidth, barBottom);
      canvas.drawRect(barRect, barPaint);
    }

    // Draw DISC letters at bottom (matches other graphs)
    final labelTextStyle = TextStyle(
      color: Colors.purple[800],
      fontSize: 16,
    );

    for (int i = 0; i < labels.length; i++) {
      final labelTextPainter = TextPainter(
        text: TextSpan(text: labels[i], style: labelTextStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      labelTextPainter.layout();

      double x = leftMargin + barSpacing * (i + 1) - barWidth / 2;
      labelTextPainter.paint(
        canvas,
        Offset(
            x + barWidth / 2 - labelTextPainter.width / 2,
            height - bottomMargin + 8
        ),
      );
    }

    // Draw Y-axis labels and markers (matches other graphs)
    final axisTextStyle = TextStyle(
        color: Colors.purple[800],
        fontSize: 12
    );
    final markerPaint = Paint()
      ..color = Colors.purple.shade100
      ..strokeWidth = 1.0;

    for (int i = -4; i <= 4; i++) {
      double value = i * 25;
      double y = zeroY - (usableHeight / 2) * (value / 100);

      // Draw tick mark
      canvas.drawLine(
          Offset(leftMargin - 5, y),
          Offset(leftMargin, y),
          markerPaint
      );

      // Draw value label
      final textSpan = TextSpan(
          text: value.toInt().toString(),
          style: axisTextStyle
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftMargin - textPainter.width - 10, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}