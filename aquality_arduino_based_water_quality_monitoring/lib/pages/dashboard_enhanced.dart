import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/gauge_widget.dart';
import '../widgets/shimmer_loading.dart';
import '../utils/format_utils.dart';
import '../services/language_service.dart';
import '../services/firebase_service.dart';
import '../models/water_quality_reading.dart';

class DashboardEnhanced extends StatefulWidget {
  const DashboardEnhanced({super.key});

  @override
  State<DashboardEnhanced> createState() => _DashboardEnhancedState();
}

class _DashboardEnhancedState extends State<DashboardEnhanced> {
  DateTime _lastRefreshedAt = DateTime.now();
  Timer? _displayTimer;
  final languageService = LanguageService();
  late FirebaseService _firebaseService;

  String t(String key) => languageService.t(key);

  @override
  void initState() {
    super.initState();
    languageService.addListener(_onLanguageChanged);
    _firebaseService = FirebaseService();
    _startDisplayTimer();
  }

  @override
  void dispose() {
    languageService.removeListener(_onLanguageChanged);
    _displayTimer?.cancel();
    super.dispose();
  }

  void _onLanguageChanged() => setState(() {});

  void _startDisplayTimer() {
    // Tick every 30 s so the "Updated X ago" text stays current.
    _displayTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  /// Get status and color for a parameter
  Map<String, dynamic> _getParameterStatus(String parameter, double value) {
    String status = 'neutral';
    Color statusColor = Colors.grey;
    String statusText = 'Unknown';

    switch (parameter) {
      case 'temperature':
        if (value >= 27.0 && value <= 30.0) {
          status = 'optimal';
          statusColor = Color(0xFF10B981);
          statusText = t('optimal_range');
        } else if (value >= 25.0 && value <= 32.0) {
          status = 'warning';
          statusColor = Colors.orange;
          statusText = t('warning');
        } else {
          status = 'critical';
          statusColor = Colors.red;
          statusText = t('critical');
        }
        break;

      case 'ph':
        if (value >= 6.5 && value <= 9.0) {
          status = 'optimal';
          statusColor = Color(0xFF10B981);
          statusText = t('optimal_range');
        } else {
          status = 'critical';
          statusColor = Colors.red;
          statusText = t('critical');
        }
        break;

      case 'ammonia':
        if (value >= 0.0 && value <= 0.02) {
          status = 'safe';
          statusColor = Color(0xFF10B981);
          statusText = t('safe_level');
        } else if (value > 0.02 && value <= 0.05) {
          status = 'warning';
          statusColor = Colors.orange;
          statusText = t('warning');
        } else {
          status = 'critical';
          statusColor = Colors.red;
          statusText = t('critical');
        }
        break;

      case 'turbidity':
        if (value >= 0.0 && value <= 30.0) {
          status = 'safe';
          statusColor = Color(0xFF10B981);
          statusText = t('safe_level');
        } else if (value > 30.0 && value <= 50.0) {
          status = 'warning';
          statusColor = Colors.orange;
          statusText = t('warning');
        } else {
          status = 'critical';
          statusColor = Colors.red;
          statusText = t('critical');
        }
        break;
    }

    return {
      'status': status,
      'statusColor': statusColor,
      'statusText': statusText,
    };
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _lastRefreshedAt = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: StreamBuilder<WaterQualityReading>(
        stream: _firebaseService.currentReadingStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ShimmerDashboard(),
            );
          }

          if (!snapshot.hasData) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ShimmerDashboard(),
            );
          }

          final reading = snapshot.data!;
          _lastRefreshedAt = reading.timestamp;

          // Calculate status counts
          final tempStatus = _getParameterStatus('temperature', reading.temperature);
          final phStatus = _getParameterStatus('ph', reading.ph);
          final ammoniaStatus = _getParameterStatus('ammonia', reading.ammonia);
          final turbidityStatus = _getParameterStatus('turbidity', reading.turbidity);

          int optimalCount = 0, warningCount = 0, criticalCount = 0;

          // Count temperature
          if (tempStatus['status'] == 'optimal') optimalCount++;
          else if (tempStatus['status'] == 'warning') warningCount++;
          else if (tempStatus['status'] == 'critical') criticalCount++;

          // Count pH
          if (phStatus['status'] == 'optimal') optimalCount++;
          else if (phStatus['status'] == 'critical') criticalCount++;

          // Count ammonia
          if (ammoniaStatus['status'] == 'safe') optimalCount++;
          else if (ammoniaStatus['status'] == 'warning') warningCount++;
          else if (ammoniaStatus['status'] == 'critical') criticalCount++;

          // Count turbidity
          if (turbidityStatus['status'] == 'safe') optimalCount++;
          else if (turbidityStatus['status'] == 'warning') warningCount++;
          else if (turbidityStatus['status'] == 'critical') criticalCount++;

          final summary = [
            {
              'label': t('optimal'),
              'count': optimalCount,
              'color': Colors.green[700],
              'bg': isDark
                  ? Colors.green[900]!.withValues(alpha: 0.3)
                  : Colors.green[50],
            },
            {
              'label': t('warning'),
              'count': warningCount,
              'color': Colors.orange[800],
              'bg': isDark
                  ? Colors.orange[900]!.withValues(alpha: 0.3)
                  : Colors.orange[50],
            },
            {
              'label': t('critical'),
              'count': criticalCount,
              'color': Colors.red[700],
              'bg': isDark
                  ? Colors.red[900]!.withValues(alpha: 0.3)
                  : Colors.red[50],
            },
          ];

          final parameters = [
            {
              'id': 'temperature',
              'title': t('temperature'),
              'rawValue': reading.temperature,
              'unit': '°C',
              'minSafe': 27.0,
              'maxSafe': 30.0,
              ...tempStatus,
            },
            {
              'id': 'ph',
              'title': t('ph_level'),
              'rawValue': reading.ph,
              'unit': '',
              'minSafe': 6.5,
              'maxSafe': 9.0,
              ...phStatus,
            },
            {
              'id': 'ammonia',
              'title': t('ammonia'),
              'rawValue': reading.ammonia,
              'unit': 'mg/L',
              'minSafe': 0.0,
              'maxSafe': 0.02,
              ...ammoniaStatus,
            },
            {
              'id': 'turbidity',
              'title': t('turbidity'),
              'rawValue': reading.turbidity,
              'unit': 'NTU',
              'minSafe': 0.0,
              'maxSafe': 30.0,
              ...turbidityStatus,
            },
          ];

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(12),
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
                                    color: (item['color'] as Color)
                                        .withValues(alpha: 0.3),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: Text(
                      'Parameter Status',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: parameters.length,
                    itemBuilder: (context, index) {
                      final param = parameters[index];
                      return GaugeWidget(
                        title: param['title'] as String,
                        value: param['rawValue'] as double,
                        minSafe: param['minSafe'] as double,
                        maxSafe: param['maxSafe'] as double,
                        unit: param['unit'] as String,
                        status: param['statusText'] as String,
                        statusColor: param['statusColor'] as Color,
                        gaugeColor: _getGaugeColor(param['id'] as String),
                        isAnomalous: false,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Get gauge color for parameter
  Color _getGaugeColor(String paramId) {
    switch (paramId) {
      case 'temperature':
        return Colors.orange;
      case 'ph':
        return Colors.purple;
      case 'ammonia':
        return Colors.amber;
      case 'turbidity':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

Widget ParameterDetail({required String title}) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: const Center(child: Text('Parameter details coming soon')),
  );
}
