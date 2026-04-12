import 'package:flutter/material.dart';

/// Simple sparkline chart widget that visualizes a trend line for 7-day data
class SparklineChart extends StatelessWidget {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;
  final double height;
  final double width;

  const SparklineChart({
    super.key,
    required this.data,
    this.lineColor = Colors.blue,
    this.fillColor = Colors.blue,
    this.height = 24,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.length < 2) {
      return SizedBox(height: height, width: width);
    }

    return CustomPaint(
      painter: _SparklinePainter(
        data: data,
        lineColor: lineColor,
        fillColor: fillColor,
      ),
      size: Size(width, height),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;

  _SparklinePainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = fillColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Find min and max values for scaling
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;

    // Prevent division by zero
    if (range == 0) {
      final y = size.height / 2;
      final path = Path()
        ..moveTo(0, y)
        ..lineTo(size.width, y);
      canvas.drawPath(path, paint);
      return;
    }

    // Calculate points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalized = (data[i] - minVal) / range;
      final y = size.height - (normalized * size.height);
      points.add(Offset(x, y));
    }

    // Draw filled area
    if (points.isNotEmpty) {
      final path = Path()
        ..moveTo(points.first.dx, size.height)
        ..lineTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      path.lineTo(points.last.dx, size.height);
      path.close();

      canvas.drawPath(path, fillPaint);
    }

    // Draw line
    if (points.isNotEmpty) {
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }

      // Draw end point indicator
      if (points.isNotEmpty) {
        canvas.drawCircle(points.last, 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}

/// Get mock 7-day trend data for a parameter
List<double> getMockTrendData(String parameterId) {
  final trends = {
    'temperature': [27.5, 28.1, 28.9, 29.2, 29.4, 28.8, 29.1],
    'pH': [6.5, 6.62, 6.71, 6.78, 6.81, 6.79, 6.80],
    'ammonia': [0.018, 0.017, 0.016, 0.015, 0.016, 0.017, 0.016],
    'turbidity': [22.1, 20.5, 19.8, 18.9, 18.4, 19.2, 18.4],
  };

  return trends[parameterId] ?? [0, 0, 0, 0, 0, 0, 0];
}

/// Get trend direction indicator (up/down/stable)
String getTrendIndicator(List<double> data) {
  if (data.length < 2) return '→';
  
  final first = data.first;
  final last = data.last;
  final diff = last - first;

  if (diff > 0.1) return '↑'; // Going up
  if (diff < -0.1) return '↓'; // Going down
  return '→'; // Stable
}

/// Get trend color (green for good, orange for warning)
Color getTrendColor(String parameterId, List<double> data) {
  final indicator = getTrendIndicator(data);
  
  // For most parameters, up/down depends on context
  // This is a simplified version - should be customized per parameter
  if (indicator == '↑') return Colors.orange;
  if (indicator == '↓') return Colors.blue;
  return Colors.green;
}
