import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/language_service.dart';
import '../services/firebase_service.dart';

class TrendsViewEnhanced extends StatefulWidget {
  const TrendsViewEnhanced({super.key});

  @override
  State<TrendsViewEnhanced> createState() => _TrendsViewEnhancedState();
}

class _TrendsViewEnhancedState extends State<TrendsViewEnhanced> {
  String _range = '24h';
  String _selectedParam = 'temperature';
  late FirebaseService _firebaseService;
  final languageService = LanguageService();

  String t(String key) => languageService.t(key);

  @override
  void initState() {
    super.initState();
    languageService.addListener(_onLanguageChanged);
    _firebaseService = FirebaseService();
  }

  void _onLanguageChanged() => setState(() {});

  @override
  void dispose() {
    languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  DateTime _getRangeStart() {
    final now = DateTime.now();
    switch (_range) {
      case '24h':
        return now.subtract(const Duration(hours: 24));
      case '7d':
        return now.subtract(const Duration(days: 7));
      case '30d':
        return now.subtract(const Duration(days: 30));
      case '90d':
        return now.subtract(const Duration(days: 90));
      default:
        return now.subtract(const Duration(hours: 24));
    }
  }

  Color _getParameterColor(String param) {
    switch (param) {
      case 'temperature':
        return const Color(0xFFF59E0B);
      case 'ph':
        return const Color(0xFF8B5CF6);
      case 'turbidity':
        return const Color(0xFF3B82F6);
      case 'nh3':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getParamDisplayName(String param) {
    switch (param) {
      case 'temperature':
        return t('temperature');
      case 'ph':
        return t('ph_level');
      case 'turbidity':
        return t('turbidity');
      case 'nh3':
        return t('ammonia');
      default:
        return param;
    }
  }

  String _getParamUnit(String param) {
    switch (param) {
      case 'temperature':
        return '°C';
      case 'ph':
        return '';
      case 'turbidity':
        return 'NTU';
      case 'nh3':
        return 'mg/L';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rangeStart = _getRangeStart();
    final rangeEnd = DateTime.now();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parameter selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Parameter',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['temperature', 'ph', 'nh3', 'turbidity']
                        .map((param) {
                      final isSelected = _selectedParam == param;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedParam = param),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _getParameterColor(param)
                                  : (isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getParamDisplayName(param),
                              style: TextStyle(
                                color: isSelected ? Colors.white : null,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Time range selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time Range',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: ['24h', '7d', '30d', '90d'].map((range) {
                    final isSelected = _range == range;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _range = range),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _getParameterColor(_selectedParam)
                                : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              range,
                              style: TextStyle(
                                color: isSelected ? Colors.white : null,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Chart
          FutureBuilder<Map<String, dynamic>>(
            future: _firebaseService.getTrendStats(
              _selectedParam,
              rangeStart,
              rangeEnd,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: 250,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData) {
                return Container(
                  height: 250,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Center(child: Text('No data available')),
                );
              }

              final stats = snapshot.data!;
              final List<double> data = stats['data'] ?? [];

              if (data.isEmpty) {
                return Container(
                  height: 250,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Center(child: Text('No data available')),
                );
              }

              final minVal = (stats['min'] as double?) ?? 0;
              final maxVal = (stats['max'] as double?) ?? 0;
              final avgVal = (stats['avg'] as double?) ?? 0;
              final trend = (stats['trend'] as double?) ?? 0;

              // Create line chart spots
              final spots = <FlSpot>[];
              for (int i = 0; i < data.length; i++) {
                spots.add(FlSpot(i.toDouble(), data[i]));
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Line chart
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: (maxVal - minVal) / 4,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[300],
                                strokeWidth: 0.5,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toInt()}',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toStringAsFixed(1)}',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                                reservedSize: 40,
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          minX: 0,
                          maxX: (data.length - 1).toDouble(),
                          minY: minVal - (maxVal - minVal) * 0.1,
                          maxY: maxVal + (maxVal - minVal) * 0.1,
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: _getParameterColor(_selectedParam),
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: data.length <= 12,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 3,
                                    color: _getParameterColor(_selectedParam),
                                    strokeWidth: 0,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: _getParameterColor(_selectedParam)
                                    .withOpacity(0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Statistics cards
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard(
                          'Min',
                          '${minVal.toStringAsFixed(2)}${_getParamUnit(_selectedParam)}',
                          Colors.blue,
                          isDark,
                        ),
                        _buildStatCard(
                          'Max',
                          '${maxVal.toStringAsFixed(2)}${_getParamUnit(_selectedParam)}',
                          Colors.red,
                          isDark,
                        ),
                        _buildStatCard(
                          'Average',
                          '${avgVal.toStringAsFixed(2)}${_getParamUnit(_selectedParam)}',
                          Colors.green,
                          isDark,
                        ),
                        _buildStatCard(
                          'Trend',
                          '${trend.toStringAsFixed(1)}%',
                          trend > 0 ? Colors.orange : Colors.purple,
                          isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

