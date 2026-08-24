import 'package:flutter/material.dart';

class DiscGraphicPainter extends CustomPainter {
  final Map<String, double> values;
  final List<String> labels = ['D', 'I', 'S', 'C'];

  DiscGraphicPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Margin for Y-axis labels
    final double leftMargin = 28;
    final double bottomMargin = 24;
    final double topMargin = 12;

    final usableWidth = width - leftMargin;
    final usableHeight = height - bottomMargin - topMargin;

    final backgroundPaint = Paint()
      ..color = Colors.blue.shade50
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.purple.shade100
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw background
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);

    // Draw horizontal grid lines and Y-axis labels
    final textStyle = TextStyle(color: Colors.purple[800], fontSize: 12);
    for (int i = 0; i <= 4; i++) {
      double percent = i / 4;
      double y = topMargin + usableHeight * percent;

      // Draw line
      canvas.drawLine(Offset(leftMargin, y), Offset(width, y), gridPaint);

      // Draw label (from 100 at top to 0 at bottom)
      int labelValue = (100 - (percent * 100)).round();
      final textSpan = TextSpan(text: '$labelValue', style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftMargin - textPainter.width - 4, y - textPainter.height / 2));
    }

    // Prepare DISC points
    List<Offset> points = [];
    final spacing = usableWidth / (labels.length + 1);

    for (int i = 0; i < labels.length; i++) {
      String label = labels[i].toLowerCase();
      double x = leftMargin + spacing * (i + 1);
      double rawValue = values[label] ?? 0;
      double clampedValue = rawValue.clamp(0, 100);
      double y = topMargin + usableHeight * (1 - clampedValue / 100);

      points.add(Offset(x, y));
    }

    // Draw lines between points
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }

    // Draw points and DISC labels
    final labelTextStyle = TextStyle(color: Colors.purple[800], fontSize: 16);
    for (int i = 0; i < points.length; i++) {
      Offset point = points[i];

      // Circle
      canvas.drawCircle(point, 6, dotPaint);
      canvas.drawCircle(point, 6, linePaint);

      // DISC letter
      final textSpan = TextSpan(text: labels[i], style: labelTextStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final labelOffset = Offset(
        point.dx - textPainter.width / 2,
        height - textPainter.height,
      );
      textPainter.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
