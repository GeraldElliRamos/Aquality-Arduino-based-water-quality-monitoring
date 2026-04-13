import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firebase_service.dart';
import '../widgets/info_tooltip.dart';

class ParameterDetailView extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String range;
  final IconData icon;
  final Color color;

  const ParameterDetailView({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.range,
    required this.icon,
    required this.color,
  });

  String get _parameterKey {
    final normalized = title.toLowerCase();
    if (normalized.contains('temp')) return 'temperature';
    if (normalized.contains('ph')) return 'ph';
    if (normalized.contains('ammonia')) return 'ammonia';
    if (normalized.contains('turbidity')) return 'turbidity';
    return 'temperature';
  }

  int get _decimals {
    switch (_parameterKey) {
      case 'ammonia':
        return 3;
      case 'turbidity':
        return 1;
      default:
        return 2;
    }
  }

  double _extractValue(WaterQualityReading reading) {
    switch (_parameterKey) {
      case 'temperature':
        return reading.temperature;
      case 'ph':
        return reading.ph;
      case 'ammonia':
        return reading.ammonia;
      case 'turbidity':
        return reading.turbidity;
      default:
        return reading.temperature;
    }
  }

  Future<List<_TimedReading>> _loadReadings() async {
    final history = await FirebaseService.instance.fetchHistory(hours: 24);
    final rows = history
        .map((r) => _TimedReading(timestamp: r.timestamp, value: _extractValue(r)))
        .where((r) => r.value.isFinite)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return rows;
  }

  bool _isInNormalRange(double current) {
    final matches = RegExp(r'-?\d+(?:\.\d+)?').allMatches(range).toList();
    if (matches.length < 2) return true;
    final min = double.tryParse(matches[0].group(0) ?? '');
    final max = double.tryParse(matches[1].group(0) ?? '');
    if (min == null || max == null) return true;
    return current >= min && current <= max;
  }

  @override
  Widget build(BuildContext context) {
    final baseValue = double.tryParse(value) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<_TimedReading>>(
        future: _loadReadings(),
        builder: (context, snapshot) {
          final liveReadings = snapshot.data ?? const <_TimedReading>[];
          final hasLiveData = liveReadings.isNotEmpty;
          final data = hasLiveData
              ? liveReadings
              : <_TimedReading>[
                  _TimedReading(timestamp: DateTime.now(), value: baseValue),
                ];

          final values = data.map((e) => e.value).toList();
          final currentValue = values.last;
          final minValue = values.reduce((a, b) => a < b ? a : b);
          final maxValue = values.reduce((a, b) => a > b ? a : b);
          final avgValue = values.reduce((a, b) => a + b) / values.length;
          final recent = data.reversed.take(10).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Hero(
                  tag: 'parameter_$title',
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(icon, size: 64, color: Colors.white),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currentValue.toStringAsFixed(_decimals),
                                style: const TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Text(
                                  unit,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Normal Range: $range',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InfoTooltip(
                                  message: _getRangeExplanation(title),
                                  icon: Icons.help_outline,
                                  iconColor: Colors.white70,
                                  iconSize: 16,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: (_isInNormalRange(currentValue)
                                      ? Colors.green
                                      : Colors.orange)
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isInNormalRange(currentValue)
                                      ? Icons.check_circle
                                      : Icons.warning_amber_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isInNormalRange(currentValue)
                                      ? 'Optimal'
                                      : 'Warning',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildStatCard(
                        'Current',
                        currentValue.toStringAsFixed(_decimals),
                        unit,
                        Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Average',
                        avgValue.toStringAsFixed(_decimals),
                        unit,
                        Colors.grey,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildStatCard(
                        'Minimum',
                        minValue.toStringAsFixed(_decimals),
                        unit,
                        Colors.cyan,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Maximum',
                        maxValue.toStringAsFixed(_decimals),
                        unit,
                        Colors.orange,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Last 24 Hours',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${values.length} readings',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            _buildChartData(values, color),
                          ),
                        ),
                        if (!hasLiveData)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'No 24h history found yet. Showing current value only.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Recent Readings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        ...List.generate(
                          recent.length,
                          (index) {
                            final row = recent[index];
                            final time = row.timestamp;
                            final timeStr =
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                            final readingValue = row.value;
                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(icon, color: color, size: 20),
                              ),
                              title: Text(
                                '${readingValue.toStringAsFixed(_decimals)} $unit',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(timeStr),
                              trailing: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData(List<double> data, Color lineColor) {
    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    final minY = data.reduce((a, b) => a < b ? a : b);
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: data.length > 10 ? (data.length / 5).floorToDouble() : 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= data.length || value < 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${value.toInt()}h',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(_decimals),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade200),
      ),
      minX: 0,
      maxX: (data.length - 1).toDouble(),
      minY: minY - padding,
      maxY: maxY + padding,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: lineColor,
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: lineColor,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                lineColor.withValues(alpha: 0.15),
                lineColor.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  String _getRangeExplanation(String parameterTitle) {
    switch (parameterTitle.toLowerCase()) {
      case 'temperature':
        return 'Optimal water temperature for tilapia is 26-30°C. Temperatures outside this range can stress fish and affect their growth rate.';
      case 'ph level':
        return 'pH measures acidity/alkalinity. Tilapia thrive in slightly alkaline water (7-9). Values outside this range can harm fish health.';
      case 'turbidity':
        return 'Turbidity indicates water clarity. Keep turbidity at or below 30 NTU for safer pond conditions; 30-50 NTU is warning level and above 50 NTU is dangerous.';
      case 'ammonia':
        return 'Ammonia is toxic waste from fish metabolism. Keep NH₃ below 0.02 mg/L to prevent fish stress and disease.';
      default:
        return 'This parameter should be kept within the normal range for optimal fish health and water quality.';
    }
  }
}

class _TimedReading {
  final DateTime timestamp;
  final double value;

  const _TimedReading({required this.timestamp, required this.value});
}

