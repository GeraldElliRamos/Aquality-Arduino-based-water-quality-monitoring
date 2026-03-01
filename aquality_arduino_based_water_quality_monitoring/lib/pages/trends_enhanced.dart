import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'dart:async';
import '../utils/chart_utils.dart';
import '../utils/format_utils.dart';

class TrendsViewEnhanced extends StatefulWidget {
  const TrendsViewEnhanced({super.key});

  @override
  State<TrendsViewEnhanced> createState() => _TrendsViewEnhancedState();
}

class _TrendsViewEnhancedState extends State<TrendsViewEnhanced>
    with SingleTickerProviderStateMixin {
  String _range = '24h';
  String _selectedParam = 'pH Level';
  List<double> _currentData = [];
  Timer? _updateTimer;

  final Map<String, List<double>> sampleData = {
    'Temperature': [
      25.2,
      25.8,
      26.5,
      27.1,
      27.8,
      28.5,
      29.1,
      29.4,
      28.9,
      28.2,
      27.5,
      26.8
    ],
    'pH Level': [
      6.8,
      6.75,
      6.82,
      6.88,
      6.92,
      6.98,
      7.02,
      7.05,
      7.08,
      7.04,
      7.0,
      6.98
    ],
    'Chlorine': [
      0.012,
      0.011,
      0.013,
      0.014,
      0.015,
      0.016,
      0.015,
      0.014,
      0.013,
      0.012,
      0.011,
      0.010
    ],
    'Dissolved Oxygen': [
      6.5,
      6.4,
      6.6,
      6.8,
      7.0,
      7.2,
      7.3,
      7.5,
      7.4,
      7.2,
      7.0,
      6.8
    ],
    'Ammonia': [
      0.1,
      0.12,
      0.11,
      0.13,
      0.15,
      0.14,
      0.13,
      0.12,
      0.11,
      0.10,
      0.09,
      0.08
    ],
  };

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    _currentData = List.from(sampleData[_selectedParam] ?? []);
    
    // Simulate real-time data updates
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          // Add new value and remove oldest
          final random = (sampleData[_selectedParam]?.last ?? 0);
          final newValue = random + (Random().nextDouble() - 0.5) * 0.3;
          _currentData.add(newValue);
          if (_currentData.length > 12) {
            _currentData.removeAt(0);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = ChartUtils.calculateStats(_currentData);
    final trendPercent = ChartUtils.calculateTrendPercentage(_currentData);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Parameter Trends',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _range,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Time Range Selector
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['24h', '7d', '30d', '90d'].map((range) {
                final isSelected = range == _range;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(range),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _range = range);
                      _animationController
                        ..reset()
                        ..forward();
                    },
                    backgroundColor:
                        isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    selectedColor: Colors.blue.withOpacity(0.2),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.blue
                          : (isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Parameter Selector
          const Text(
            'Select Parameter',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  sampleData.keys.map((paramName) {
                final isSelected = paramName == _selectedParam;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(paramName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedParam = paramName;
                        _currentData = sampleData[paramName] ?? [];
                      });
                      _animationController
                        ..reset()
                        ..forward();
                    },
                    backgroundColor:
                        isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    selectedColor: Colors.purple.withOpacity(0.2),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.purple
                          : (isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'Min',
                  value: FormatUtils.formatParamValue(stats['min'] ?? 0),
                  color: Colors.blue,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  label: 'Max',
                  value: FormatUtils.formatParamValue(stats['max'] ?? 0),
                  color: Colors.orange,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  label: 'Avg',
                  value: FormatUtils.formatParamValue(stats['avg'] ?? 0),
                  color: Colors.green,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Trend Indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trend (24h)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Icon(
                      trendPercent > 0
                          ? Icons.trending_up
                          : (trendPercent < 0
                              ? Icons.trending_down
                              : Icons.trending_flat),
                      color: ChartUtils.getTrendColor(trendPercent, isDark),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${trendPercent.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ChartUtils.getTrendColor(trendPercent, isDark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Chart
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedParam,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 250,
                  child: LineChart(
                    ChartUtils.buildLineChartData(
                      _currentData,
                      lineColor: Colors.purple,
                      gradientStartColor: Colors.purple,
                      gradientEndColor: Colors.purple.shade100,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Data Table
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Time')),
                  DataColumn(label: Text('Value')),
                  DataColumn(label: Text('Change')),
                ],
                rows: List.generate(
                  min(5, _currentData.length),
                  (index) {
                    final value = _currentData[index];
                    final prevValue = index > 0 ? _currentData[index - 1] : value;
                    final change = value - prevValue;

                    return DataRow(
                      cells: [
                        DataCell(
                          Text('${index * 2}h ago'),
                        ),
                        DataCell(
                          Text(FormatUtils.formatParamValue(value)),
                        ),
                        DataCell(
                          Row(
                            children: [
                              Icon(
                                change > 0
                                    ? Icons.arrow_upward
                                    : (change < 0
                                        ? Icons.arrow_downward
                                        : Icons.remove),
                                size: 14,
                                color: change > 0
                                    ? Colors.red
                                    : (change < 0
                                        ? Colors.green
                                        : Colors.grey),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                FormatUtils.formatParamValue(change.abs()),
                                style: TextStyle(
                                  color: change > 0
                                      ? Colors.red
                                      : (change < 0
                                          ? Colors.green
                                          : Colors.grey),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
