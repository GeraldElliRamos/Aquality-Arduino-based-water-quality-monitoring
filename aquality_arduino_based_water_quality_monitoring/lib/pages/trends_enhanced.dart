import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'dart:async';
import '../services/language_service.dart';
import '../services/firebase_service.dart';
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
  List<WaterQualityReading> _historyData = [];
  List<WaterQualityReading> _displayReadings = [];
  List<double> _rawCurrentData = [];
  List<double> _currentData = [];
  Timer? _updateTimer;
  StreamSubscription? _sensorSubscription;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isConnected = false;
  bool _hasError = false;
  DateTime _lastRefreshedAt = DateTime.now();
  final languageService = LanguageService();
  static const List<String> _ranges = ['6h', '24h', '7d', '30d', '90d'];

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
          'light': const Color(0xFFFCD34D), // Light Orange
        };
      case 'pH Level':
        return {
          'primary': const Color(0xFF8B5CF6), // Purple
          'light': const Color(0xFFDDD6FE), // Light Purple
        };
      case 'Turbidity':
        return {
          'primary': const Color(0xFF3B82F6), // Blue
          'light': const Color(0xFFBFDBFE), // Light Blue
        };
      case 'Ammonia':
        return {
          'primary': const Color(0xFF10B981), // Green
          'light': const Color(0xFFD1FAE5), // Light Green
        };
      default:
        return {
          'primary': const Color(0xFF6B7280), // Gray
          'light': const Color(0xFFE5E7EB), // Light Gray
        };
    }
  }

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

    _loadHistoryData();
    _subscribeToLiveUpdates();
  }

  void _onLanguageChanged() => setState(() {});

  /// Load historical data from Firebase
  Future<void> _loadHistoryData() async {
    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
      _isLoading = _historyData.isEmpty; // Only show loading if no data yet
    });

    try {
      debugPrint('[TrendsView] Loading history data for range: $_range');
      final hours = _getHoursFromRange(_range);
      final readings = await FirebaseService.instance.fetchHistory(
        hours: hours,
      );

      if (mounted) {
        setState(() {
          _historyData = readings;
          _updateCurrentData();
          _isLoading = false;
          _isRefreshing = false;
          _hasError = false;
          _isConnected = readings.isNotEmpty;
          _lastRefreshedAt = DateTime.now();
          debugPrint(
            '[TrendsView] Loaded ${readings.length} readings from Firestore',
          );
        });
      }
    } catch (e) {
      debugPrint('[TrendsView] Error loading history: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isConnected = false;
          _isRefreshing = false;
          _isLoading = false;
          _displayReadings = [];
          _rawCurrentData = [];
          _currentData = [];
        });
      }
    }
  }

  /// Subscribe to live sensor updates
  void _subscribeToLiveUpdates() {
    debugPrint('[TrendsView] Starting sensor stream listener');
    _sensorSubscription = FirebaseService.instance.sensorStream.listen(
      (reading) {
        if (mounted && !_isLoading) {
          // Only add if it's a new reading (not placeholder)
          if (reading.temperature != 0 || reading.ph != 0) {
            debugPrint(
              '[TrendsView] Received live update: temp=${reading.temperature}',
            );
            setState(() {
              // Add new reading to history
              _historyData.add(reading);

              // Keep only relevant time range
              final cutoff = DateTime.now().subtract(
                Duration(hours: _getHoursFromRange(_range)),
              );
              _historyData.removeWhere((r) => r.timestamp.isBefore(cutoff));

              _updateCurrentData();
              _isConnected = true;
              _hasError = false;
            });
          }
        }
      },
      onError: (e) {
        debugPrint('[TrendsView] Stream error: $e');
        if (mounted) {
          setState(() {
            _hasError = true;
            _isConnected = false;
          });
        }
      },
    );
  }

  /// Extract values for the selected parameter from history
  void _updateCurrentData() {
    if (_historyData.isEmpty) {
      _displayReadings = [];
      _rawCurrentData = [];
      _currentData = [];
      return;
    }

    _displayReadings = _aggregateReadings(
      _historyData,
      _bucketDurationForRange(_range),
    );

    final rawSource = _historyData;
    final source = _displayReadings;

    switch (_selectedParam) {
      case 'Temperature':
        _rawCurrentData = rawSource.map((r) => r.temperature).toList();
        _currentData = source.map((r) => r.temperature).toList();
        break;
      case 'pH Level':
        _rawCurrentData = rawSource.map((r) => r.ph).toList();
        _currentData = source.map((r) => r.ph).toList();
        break;
      case 'Turbidity':
        _rawCurrentData = rawSource.map((r) => r.turbidity).toList();
        _currentData = source.map((r) => r.turbidity).toList();
        break;
      case 'Ammonia':
        _rawCurrentData = rawSource.map((r) => r.ammonia).toList();
        _currentData = source.map((r) => r.ammonia).toList();
        break;
    }
  }

  int _getHoursFromRange(String range) {
    switch (range) {
      case '6h':
        return 6;
      case '24h':
        return 24;
      case '7d':
        return 168;
      case '30d':
        return 720;
      case '90d':
        return 2160;
      default:
        return 24;
    }
  }

  Duration _bucketDurationForRange(String range) {
    switch (range) {
      case '6h':
        return const Duration(minutes: 5);
      case '24h':
        return const Duration(minutes: 15);
      case '7d':
        return const Duration(hours: 2);
      case '30d':
        return const Duration(hours: 6);
      case '90d':
        return const Duration(hours: 24);
      default:
        return const Duration(minutes: 15);
    }
  }

  String _intervalLabel() {
    final bucket = _bucketDurationForRange(_range);
    if (bucket.inMinutes < 60) {
      return '${bucket.inMinutes}m interval';
    }
    if (bucket.inHours < 24) {
      return '${bucket.inHours}h interval';
    }
    return '${bucket.inDays}d interval';
  }

  List<WaterQualityReading> _aggregateReadings(
    List<WaterQualityReading> source,
    Duration bucket,
  ) {
    if (source.isEmpty) return const [];

    final bucketMs = bucket.inMilliseconds;
    final grouped = <int, List<WaterQualityReading>>{};

    for (final reading in source) {
      final ts = reading.timestamp.millisecondsSinceEpoch;
      final key = (ts ~/ bucketMs) * bucketMs;
      grouped.putIfAbsent(key, () => []).add(reading);
    }

    final keys = grouped.keys.toList()..sort();
    final aggregated = <WaterQualityReading>[];

    for (final key in keys) {
      final items = grouped[key]!;
      final count = items.length;

      double avg(double Function(WaterQualityReading) pick) {
        var sum = 0.0;
        for (final item in items) {
          sum += pick(item);
        }
        return sum / count;
      }

      aggregated.add(
        WaterQualityReading(
          temperature: avg((r) => r.temperature),
          ph: avg((r) => r.ph),
          ammonia: avg((r) => r.ammonia),
          turbidity: avg((r) => r.turbidity),
          timestamp: DateTime.fromMillisecondsSinceEpoch(key),
        ),
      );
    }

    return aggregated;
  }

  @override
  void dispose() {
    languageService.removeListener(_onLanguageChanged);
    _animationController.dispose();
    _updateTimer?.cancel();
    _sensorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statsData = _rawCurrentData.isEmpty ? _currentData : _rawCurrentData;
    final stats = ChartUtils.calculateStats(statsData);
    final trendPercent = ChartUtils.calculateTrendPercentage(statsData);

    return RefreshIndicator(
      onRefresh: _loadHistoryData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t('parameter_trends'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Refreshing indicator
                    if (_isRefreshing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    const SizedBox(width: 8),
                    // Connection status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _hasError
                            ? Colors.red.withValues(alpha: 0.1)
                            : (_isConnected
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _hasError
                              ? Colors.red.withValues(alpha: 0.3)
                              : (_isConnected
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.grey.withValues(alpha: 0.3)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _hasError
                                ? Icons.cloud_off
                                : (_isConnected
                                      ? Icons.cloud_done
                                      : Icons.cloud_queue),
                            size: 14,
                            color: _hasError
                                ? Colors.red
                                : (_isConnected ? Colors.green : Colors.grey),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _range,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _hasError
                                  ? Colors.red
                                  : (_isConnected ? Colors.green : Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Error message
            if (_hasError && _historyData.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Failed to load trend data',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Check Firestore connection in Settings → Diagnostics',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Firebase data indicator
            if (_historyData.isEmpty && !_isLoading && !_hasError)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No history data yet. Waiting for Firebase history at /Aquality_history.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Time Range Selector
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _ranges.map((range) {
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
                        _loadHistoryData();
                      },
                      backgroundColor: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade200,
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
                children: ['Temperature', 'pH Level', 'Turbidity', 'Ammonia']
                    .map((param) {
                      final isSelected = param == _selectedParam;
                      final paramColor = getParameterColors(param)['primary']!;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(getTranslatedParamName(param)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedParam = param;
                              _updateCurrentData();
                            });
                            _animationController
                              ..reset()
                              ..forward();
                          },
                          backgroundColor: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade200,
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
                    })
                    .toList(),
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
                    color: getParameterColors(
                      _selectedParam,
                    )['primary']!.withValues(alpha: 0.7),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    label: t('avg'),
                    value: FormatUtils.formatParamValue(stats['avg'] ?? 0),
                    color: getParameterColors(
                      _selectedParam,
                    )['primary']!.withValues(alpha: 0.4),
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
                    '${t('trend_24h')} (${statsData.length} readings, ${_currentData.length} points, ${_intervalLabel()})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
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
                    '$_selectedParam (${_intervalLabel()})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: _currentData.isEmpty
                        ? Center(
                            child: Text(
                              'No data available',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : LineChart(
                            ChartUtils.buildLineChartData(
                              _currentData,
                              lineColor: getParameterColors(
                                _selectedParam,
                              )['primary']!,
                              gradientStartColor: getParameterColors(
                                _selectedParam,
                              )['primary']!,
                              gradientEndColor: getParameterColors(
                                _selectedParam,
                              )['light']!,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Data Table
            if (_currentData.isNotEmpty)
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
                    rows: List.generate(min(5, _currentData.length), (index) {
                      final dataIndex = _currentData.length - 1 - index;
                      final value = _currentData[dataIndex];
                      final prevValue = dataIndex > 0
                          ? _currentData[dataIndex - 1]
                          : value;
                      final change = value - prevValue;

                      // Calculate time ago if we have history data
                      String timeLabel;
                      if (_displayReadings.isNotEmpty &&
                          dataIndex < _displayReadings.length) {
                        final timestamp = _displayReadings[dataIndex].timestamp;
                        timeLabel = FormatUtils.formatTimeAgo(timestamp);
                      } else {
                        timeLabel = '${index * 2} ${t('hours_ago')}';
                      }

                      return DataRow(
                        cells: [
                          DataCell(Text(timeLabel)),
                          DataCell(Text(FormatUtils.formatParamValue(value))),
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
                    }),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
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
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
