import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'dart:async';
import '../services/language_service.dart';
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
  final languageService = LanguageService();

  String t(String key) => languageService.t(key);

  /// Helper function to translate parameter names
  String getTranslatedParamName(String paramName) {
    final translations = {
      'Temperature': t('temperature'),
      'pH Level': t('ph_level'),
      'Turbidity': t('turbidity'),
      'Ammonia': t('ammonia'),
    };
    return translations[paramName] ?? paramName;
  }

  /// Helper function to get color for each parameter
  Map<String, Color> getParameterColors(String paramName) {
    switch (paramName) {
      case 'Temperature':
        return {
          'primary': const Color(0xFFF59E0B), // Orange
          'light': const Color(0xFFFCD34D),  // Light Orange
        };
      case 'pH Level':
        return {
          'primary': const Color(0xFF8B5CF6), // Purple
          'light': const Color(0xFFDDD6FE),  // Light Purple
        };
      case 'Turbidity':
        return {
          'primary': const Color(0xFF3B82F6), // Blue
          'light': const Color(0xFFBFDBFE),  // Light Blue
        };
      case 'Ammonia':
        return {
          'primary': const Color(0xFF10B981), // Green
          'light': const Color(0xFFD1FAE5),  // Light Green
        };
      default:
        return {
          'primary': const Color(0xFF6B7280), // Gray
          'light': const Color(0xFFE5E7EB),  // Light Gray
        };
    }
  }

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
    'Turbidity': [
      18.0,
      19.2,
      17.8,
      20.1,
      22.5,
      24.0,
      23.2,
      25.4,
      24.8,
      22.9,
      21.7,
      20.3
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
    languageService.addListener(_onLanguageChanged);
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

  void _onLanguageChanged() => setState(() {});

  @override
  void dispose() {
    languageService.removeListener(_onLanguageChanged);
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
              Text(
                t('parameter_trends'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
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
                    selectedColor: Colors.blue.withValues(alpha: 0.2),
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
          Text(
            t('select_parameter'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  sampleData.keys.map((paramName) {
                final isSelected = paramName == _selectedParam;
                final paramColor = getParameterColors(paramName)['primary'] ?? Colors.purple;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(getTranslatedParamName(paramName)),
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
                    selectedColor: paramColor.withValues(alpha: 0.2),
                    side: BorderSide(
                      color: isSelected
                          ? paramColor
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
                  label: t('min'),
                  value: FormatUtils.formatParamValue(stats['min'] ?? 0),
                  color: getParameterColors(_selectedParam)['primary']!,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  label: t('max'),
                  value: FormatUtils.formatParamValue(stats['max'] ?? 0),
                  color: getParameterColors(_selectedParam)['primary']!.withOpacity(0.7),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  label: t('avg'),
                  value: FormatUtils.formatParamValue(stats['avg'] ?? 0),
                  color: getParameterColors(_selectedParam)['primary']!.withOpacity(0.4),
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
                Text(
                  t('trend_24h'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
                      lineColor: getParameterColors(_selectedParam)['primary']!,
                      gradientStartColor: getParameterColors(_selectedParam)['primary']!,
                      gradientEndColor: getParameterColors(_selectedParam)['light']!,
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
                columns: [
                  DataColumn(label: Text(t('time'))),
                  DataColumn(label: Text(t('value'))),
                  DataColumn(label: Text(t('change'))),
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
                          Text('${index * 2} ${t('hours_ago')}'),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
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

