import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/gauge_widget.dart';
import '../widgets/shimmer_loading.dart';
import '../utils/format_utils.dart';
import '../services/notification_service.dart';
import '../services/threshold_service.dart';

class DashboardEnhanced extends StatefulWidget {
  const DashboardEnhanced({super.key});

  @override
  State<DashboardEnhanced> createState() => _DashboardEnhancedState();
}

class _DashboardEnhancedState extends State<DashboardEnhanced> {
  bool _isRefreshing = false;
  bool _isLoading = true;
  DateTime _lastRefreshedAt = DateTime.now();
  Timer? _refreshTimer;
  Timer? _displayTimer;
  
  // Smart refresh: cache parameter values to skip rebuilds when unchanged
  final Map<String, double> _lastParameterValues = {
    'temperature': -1,
    'pH': -1,
    'ammonia': -1,
    'turbidity': -1,
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startTimers();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _displayTimer?.cancel();
    super.dispose();
  }

  void _startTimers() {
    // Auto-refresh sensor data every 30 seconds.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _autoRefresh(),
    );
    // Tick every 30 s so the "Updated X ago" text stays current.
    _displayTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadInitialData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      _lastRefreshedAt = DateTime.now();
      setState(() => _isLoading = false);
      unawaited(_checkThresholds());
    }
  }

  Future<void> _autoRefresh() async {
    if (_isRefreshing || !mounted) return;
    
    // Check if parameters have changed before updating UI
    final hasChanges = _hasParametersChanged();
    
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 300));
    _lastRefreshedAt = DateTime.now();
    if (mounted) {
      setState(() => _isRefreshing = false);
      // Only check thresholds if data changed (skip redundant notifications)
      if (hasChanges) {
        unawaited(_checkThresholds());
      }
    }
  }
  
  /// Compare current param values with cached values to detect changes
  bool _hasParametersChanged() {
    final mockValues = <String, double>{
      'temperature': 29.4,
      'pH': 6.81,
      'ammonia': 0.016,
      'turbidity': 18.4,
    };
    
    for (final entry in mockValues.entries) {
      final id = entry.key;
      final value = entry.value;
      final lastValue = _lastParameterValues[id] ?? -1;
      // Threshold: 0.01 change triggers update (prevents jitter from sensor noise)
      if ((value - lastValue).abs() > 0.01) {
        _lastParameterValues[id] = value;
        return true;
      }
    }
    return false;
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 500));
    _lastRefreshedAt = DateTime.now();
    if (mounted) {
      setState(() => _isRefreshing = false);
      unawaited(_checkThresholds());
    }
  }

  Future<void> _checkThresholds() async {
    final stored = await ThresholdService.getAllThresholds();
    final effective = stored.isEmpty
        ? ThresholdService.getDefaultThresholds()
        : stored;

    // Mock values — swap with real sensor data when Arduino is connected.
    final mockValues = <String, (double, String)>{
      'temperature': (29.4, '°C'),
      'pH': (6.81, ''),
      'ammonia': (0.016, 'mg/L'),
      'turbidity': (18.4, 'NTU'),
    };

    for (final t in effective) {
      final entry = mockValues[t.parameterId];
      if (entry == null) continue;
      await NotificationService.instance.checkAndNotify(
        parameterId: t.parameterId,
        parameterName: t.parameterName,
        value: entry.$1,
        unit: entry.$2,
        minSafe: t.minSafeValue,
        maxSafe: t.maxSafeValue,
        warningMin: t.warningMinValue,
        warningMax: t.warningMaxValue,
        enableNotifications: t.enableNotifications,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: ShimmerDashboard(),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final summary = [
      {
        'label': 'Optimal',
        'count': 5,
        'color': Colors.green[700],
        'bg': isDark ? Colors.green[900]!.withValues(alpha: 0.3) : Colors.green[50],
      },
      {
        'label': 'Warning',
        'count': 0,
        'color': Colors.orange[800],
        'bg': isDark ? Colors.orange[900]!.withValues(alpha: 0.3) : Colors.orange[50],
      },
      {
        'label': 'Critical',
        'count': 0,
        'color': Colors.red[700],
        'bg': isDark ? Colors.red[900]!.withValues(alpha: 0.3) : Colors.red[50],
      },
    ];

    final parameters = [
      {
        'id': 'temperature',
        'title': 'Temperature',
        'rawValue': 29.4,
        'unit': '°C',
        'minSafe': 27.0,
        'maxSafe': 30.0,
        'status': 'Optimal range',
        'statusColor': Color(0xFF10B981),
        'gaugeColor': Colors.orange,
      },
      {
        'id': 'pH',
        'title': 'pH Level',
        'rawValue': 6.81,
        'unit': '',
        'minSafe': 6.5,
        'maxSafe': 9.0,
        'status': 'Optimal range',
        'statusColor': Color(0xFF10B981),
        'gaugeColor': Colors.purple,
      },
      {
        'id': 'ammonia',
        'title': 'Ammonia',
        'rawValue': 0.016,
        'unit': 'mg/L',
        'minSafe': 0.0,
        'maxSafe': 0.02,
        'status': 'Safe level',
        'statusColor': Color(0xFF10B981),
        'gaugeColor': Colors.amber,
      },
      {
        'id': 'turbidity',
        'title': 'Turbidity',
        'rawValue': 18.4,
        'unit': 'NTU',
        'minSafe': 0.0,
        'maxSafe': 30.0,
        'status': 'Safe level',
        'statusColor': Color(0xFF10B981),
        'gaugeColor': Colors.blue,
      },
    ];

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [Color(0xFF1E293B), Color(0xFF0F172A)]
                      : [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: summary.map((item) {
                      return Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: item['bg'] as Color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (item['color'] as Color).withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${item['count']}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: item['color'] as Color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['label'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Updated ${FormatUtils.formatTimeAgo(_lastRefreshedAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.signal_cellular_alt,
                              size: 14,
                              color: Colors.greenAccent,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Connected',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Center(
              child: Text(
                'Parameter Status',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.7,
              ),
              itemCount: parameters.length,
              itemBuilder: (context, index) {
                final param = parameters[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ParameterDetail(title: param['title'] as String),
                      ),
                    );
                  },
                  child: Builder(
                    builder: (context) {
                      final id = param['id'] as String?;
                      final raw = (param['rawValue'] as double);
                      double displayValue = raw;
                      bool anomalous = false;
                      if (id != null) {
                        final sv = NotificationService.instance
                            .getSmoothedValue(id);
                        if (sv != null) displayValue = sv;
                        anomalous = NotificationService.instance.isAnomalous(
                          id,
                        );
                      }

                      return GaugeWidget(
                        title: param['title'] as String,
                        value: displayValue,
                        minSafe: param['minSafe'] as double,
                        maxSafe: param['maxSafe'] as double,
                        unit: param['unit'] as String,
                        status: param['status'] as String,
                        statusColor: param['statusColor'] as Color,
                        gaugeColor: param['gaugeColor'] as Color,
                        isAnomalous: anomalous,
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

Widget ParameterDetail({required String title}) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: const Center(child: Text('Parameter details coming soon')),
  );
}
