import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Utility functions for consistent chart styling and data
class ChartUtils {
  /// Get default line chart styling for a parameter
  static LineChartData buildLineChartData(
    List<double> dataPoints, {
    required Color lineColor,
    required Color gradientStartColor,
    Color? gradientEndColor,
    double? minY,
    double? maxY,
    bool showDots = true,
    bool showGrid = true,
  }) {
    if (dataPoints.isEmpty) {
      return LineChartData(
        lineBarsData: [],
        titlesData: FlTitlesData(show: false),
      );
    }

    final spots = List.generate(
      dataPoints.length,
      (index) => FlSpot(index.toDouble(), dataPoints[index]),
    );

    final calculatedMinY = minY ?? (dataPoints.reduce((a, b) => a < b ? a : b) * 0.9);
    final calculatedMaxY = maxY ?? (dataPoints.reduce((a, b) => a > b ? a : b) * 1.1);

    return LineChartData(
      gridData: GridData(
        show: showGrid,
        drawVerticalLine: false,
        horizontalInterval: (calculatedMaxY - calculatedMinY) / 5,
        getDrawingHorizontalLine: () {
          return FlLine(
            color: Colors.grey.withValues(alpha: 0.1),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (calculatedMaxY - calculatedMinY) / 5,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: lineColor,
          barWidth: 2,
          dotData: FlDotData(
            show: showDots,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: lineColor,
                strokeWidth: 1,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                gradientStartColor.withValues(alpha: 0.4),
                gradientEndColor?.withValues(alpha: 0.1) ?? gradientStartColor.withValues(alpha: 0.01),
              ],
            ),
          ),
        ),
      ],
      minY: calculatedMinY,
      maxY: calculatedMaxY,
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
        ),
      ),
    );
  }

  /// Get threshold lines for chart
  static List<HorizontalLine> getThresholdLines({
    required double minSafe,
    required double maxSafe,
    double? warningMin,
    double? warningMax,
  }) {
    final lines = <HorizontalLine>[
      HorizontalLine(
        y: minSafe,
        color: Colors.green.withValues(alpha: 0.3),
        strokeWidth: 1.5,
        dashArray: [5, 5],
      ),
      HorizontalLine(
        y: maxSafe,
        color: Colors.green.withValues(alpha: 0.3),
        strokeWidth: 1.5,
        dashArray: [5, 5],
      ),
    ];

    if (warningMin != null) {
      lines.add(
        HorizontalLine(
          y: warningMin,
          color: Colors.orange.withValues(alpha: 0.3),
          strokeWidth: 1,
          dashArray: [3, 3],
        ),
      );
    }

    if (warningMax != null) {
      lines.add(
        HorizontalLine(
          y: warningMax,
          color: Colors.orange.withValues(alpha: 0.3),
          strokeWidth: 1,
          dashArray: [3, 3],
        ),
      );
    }

    return lines;
  }

  /// Calculate chart statistics
  static Map<String, double> calculateStats(List<double> dataPoints) {
    if (dataPoints.isEmpty) {
      return {
        'min': 0,
        'max': 0,
        'avg': 0,
        'latest': 0,
      };
    }

    final min = dataPoints.reduce((a, b) => a < b ? a : b);
    final max = dataPoints.reduce((a, b) => a > b ? a : b);
    final avg = dataPoints.reduce((a, b) => a + b) / dataPoints.length;
    final latest = dataPoints.last;

    return {
      'min': min,
      'max': max,
      'avg': avg,
      'latest': latest,
    };
  }

  /// Calculate trend percentage (change from first to last value)
  static double calculateTrendPercentage(List<double> dataPoints) {
    if (dataPoints.length < 2) return 0;
    final first = dataPoints.first;
    final last = dataPoints.last;
    if (first == 0) return 0;
    return ((last - first) / first) * 100;
  }

  /// Get trend direction icon
  static String getTrendIcon(double trendPercent) {
    if (trendPercent > 2) return '↑'; // Increasing
    if (trendPercent < -2) return '↓'; // Decreasing
    return '→'; // Stable
  }

  /// Get trend color
  static Color getTrendColor(double trendPercent, bool isDark) {
    if (trendPercent > 5) {
      return isDark ? Colors.red.shade300 : Colors.red;
    } else if (trendPercent < -5) {
      return isDark ? Colors.blue.shade300 : Colors.blue;
    } else {
      return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    }
  }
}

FlGridData? GridData({required bool show, required bool drawVerticalLine, required double horizontalInterval, required FlLine Function() getDrawingHorizontalLine}) {
  return null;

}
