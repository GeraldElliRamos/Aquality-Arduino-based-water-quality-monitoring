import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/gauge_widget.dart';
import '../widgets/shimmer_loading.dart';
import '../utils/format_utils.dart';
import '../services/language_service.dart';
import '../services/notification_service.dart';
import '../services/threshold_service.dart';
import '../services/firebase_service.dart';
import 'parameter_detail.dart';

class DashboardEnhanced extends StatefulWidget {
  const DashboardEnhanced({super.key});

  @override
  State<DashboardEnhanced> createState() => _DashboardEnhancedState();
}

class _DashboardEnhancedState extends State<DashboardEnhanced> {
  // ── State ────────────────────────────────────────────────────────────────
  bool _isRefreshing = false;
  bool _isLoading = true;
  bool _isConnected = false;
  bool _hasError = false;
  DateTime _lastRefreshedAt = DateTime.now();

  // Live sensor values — nullable so we know if Firebase has sent real data yet
  double? _temperature;
  double? _ph;
  double? _ammonia;
  double? _turbidity;

  // ── Subscriptions / timers ───────────────────────────────────────────────
  StreamSubscription<WaterQualityReading>? _sensorSub;
  Timer? _displayTimer;

  final languageService = LanguageService();
  String t(String key) => languageService.t(key);

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    languageService.addListener(_onLanguageChanged);
    _initFirebase();
    _displayTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  @override
  void dispose() {
    languageService.removeListener(_onLanguageChanged);
    _sensorSub?.cancel();
    _displayTimer?.cancel();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _tick() {
    if (mounted) {
      setState(() {});
    }
  }

  // ── Firebase ─────────────────────────────────────────────────────────────
  Future<void> _initFirebase() async {
    // Attach the live Firestore stream first so realtime updates are not
    // delayed by the one-shot initial fetch.
    debugPrint('[Dashboard] Starting Firestore sensor stream listener');
    _sensorSub = FirebaseService.instance.sensorStream.listen(
      (reading) {
        debugPrint('[Dashboard] Received sensor reading: temp=${reading.temperature}, ph=${reading.ph}, ammonia=${reading.ammonia}, turbidity=${reading.turbidity}');
        if (mounted) _applyReading(reading, connected: true);
      },
      onError: (e) {
        debugPrint('[Dashboard] stream error: $e');
        if (mounted) {
          setState(() {
            _hasError = true;
            _isConnected = false;
            _isLoading = false; // never stay stuck on shimmer
          });
        }
      },
    );

    try {
      final initial = await FirebaseService.instance.fetchOnce();
      if (mounted) _applyReading(initial, connected: true);
    } catch (e) {
      debugPrint('[Dashboard] fetchOnce error: $e');
      // Don't leave the user stuck on shimmer — show disconnected state
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _isConnected = false;
        });
      }
    }
  }

  void _applyReading(WaterQualityReading r, {required bool connected}) {
    // Treat 0.0 as a valid sensor value only after the first real read.
    // placeholder() returns all zeros — detect that and keep showing shimmer
    // until we get a non-placeholder reading (timestamp is DateTime.now() for
    // placeholders, so we can't distinguish; instead check if the DB node exists
    // via the stream null-check in firebase_service.dart).
    final isPlaceholder = r.temperature == 0.0 &&
        r.ph == 0.0 &&
        r.ammonia == 0.0 &&
        r.turbidity == 0.0;

    debugPrint('[Dashboard] _applyReading - isPlaceholder=$isPlaceholder, temp=${r.temperature}, ph=${r.ph}, ammonia=${r.ammonia}, turbidity=${r.turbidity}');

    final hasChanges = !isPlaceholder &&
        ((_temperature == null) ||
            (_temperature! - r.temperature).abs() > 0.001 ||
            (_ph! - r.ph).abs() > 0.001 ||
            (_ammonia! - r.ammonia).abs() > 0.0001 ||
            (_turbidity! - r.turbidity).abs() > 0.001);

    debugPrint('[Dashboard] hasChanges=$hasChanges');

    setState(() {
      if (!isPlaceholder) {
        _temperature = r.temperature;
        _ph = r.ph;
        _ammonia = r.ammonia;
        _turbidity = r.turbidity;
        _lastRefreshedAt = r.timestamp;
      }
      _isConnected = connected;
      _isLoading = false;
      _hasError = false;
    });

    if (hasChanges) {
      unawaited(_checkThresholds());
    }
  }

  // ── Pull-to-refresh ───────────────────────────────────────────────────────
  Future<void> _onRefresh() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    try {
      final reading = await FirebaseService.instance.fetchOnce();
      if (mounted) _applyReading(reading, connected: true);
    } catch (e) {
      debugPrint('[Dashboard] refresh error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isConnected = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  // ── Threshold / notification check ────────────────────────────────────────
  Future<void> _checkThresholds() async {
    final temp = _temperature;
    final ph = _ph;
    final ammonia = _ammonia;
    final turbidity = _turbidity;
    if (temp == null || ph == null || ammonia == null || turbidity == null) {
      return;
    }

    final stored = await ThresholdService.getAllThresholds();
    final effective =
        stored.isEmpty ? ThresholdService.getDefaultThresholds() : stored;

    final liveValues = <String, (double, String)>{
      'temperature': (temp,     '°C'),
      'pH':          (ph,       ''),
      'ammonia':     (ammonia,  'mg/L'),
      'turbidity':   (turbidity,'NTU'),
    };

    for (final threshold in effective) {
      final entry = liveValues[threshold.parameterId];
      if (entry == null) continue;
      await NotificationService.instance.checkAndNotify(
        parameterId:         threshold.parameterId,
        parameterName:       threshold.parameterName,
        value:               entry.$1,
        unit:                entry.$2,
        minSafe:             threshold.minSafeValue,
        maxSafe:             threshold.maxSafeValue,
        warningMin:          threshold.warningMinValue,
        warningMax:          threshold.warningMaxValue,
        enableNotifications: threshold.enableNotifications,
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _statusLabel(String parameterId, double value) {
    switch (parameterId) {
      case 'temperature':
        return (value >= 26 && value <= 29) ? t('optimal_range') : t('warning');
      case 'pH':
        return (value >= 7.0 && value <= 8.5) ? t('optimal_range') : t('warning');
      case 'ammonia':
        return (value >= 0 && value <= 0.02) ? t('safe_level') : t('warning');
      case 'turbidity':
        return (value >= 0 && value <= 30) ? t('safe_level') : t('warning');
      default:
        return t('optimal_range');
    }
  }

  Color _statusColor(String parameterId, double value) {
    const ok = Color(0xFF10B981);
    final warn = Colors.orange;
    switch (parameterId) {
      case 'temperature': return (value >= 26 && value <= 29) ? ok : warn;
      case 'pH':          return (value >= 7.0 && value <= 8.5) ? ok : warn;
      case 'ammonia':     return (value >= 0 && value <= 0.02) ? ok : warn;
      case 'turbidity':   return (value >= 0 && value <= 30) ? ok : warn;
      default:            return ok;
    }
  }

  IconData _parameterIcon(String parameterId) {
    switch (parameterId) {
      case 'temperature':
        return Icons.thermostat;
      case 'pH':
        return Icons.water_drop;
      case 'ammonia':
        return Icons.waves;
      case 'turbidity':
        return Icons.blur_on;
      default:
        return Icons.show_chart;
    }
  }

  String _parameterRangeLabel(String parameterId) {
    switch (parameterId) {
      case 'temperature':
        return '26.0-29.0';
      case 'pH':
        return '7.0-8.5';
      case 'ammonia':
        return '0.0-0.02';
      case 'turbidity':
        return '0.0-30.0';
      default:
        return '-';
    }
  }

  int _valueDecimals(String parameterId) {
    switch (parameterId) {
      case 'ammonia':
        return 3;
      case 'turbidity':
        return 1;
      default:
        return 2;
    }
  }

  int _countByStatus(String status) {
    int count = 0;
    final checks = <(String, double?, double, double)>[
      ('temperature', _temperature, 26.0, 29.0),
      ('pH',          _ph,          7.0,  8.5),
      ('ammonia',     _ammonia,     0.0,  0.02),
      ('turbidity',   _turbidity,   0.0,  30.0),
    ];
    for (final c in checks) {
      final v = c.$2;
      if (v == null) continue; // not yet received
      final inRange = v >= c.$3 && v <= c.$4;
      if (status == 'optimal' && inRange) count++;
      if (status == 'warning' && !inRange) count++;
    }
    return count;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
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
        'label': t('optimal'),
        'count': _countByStatus('optimal'),
        'color': Colors.green[700]!,
        'bg': isDark
            ? Colors.green[900]!.withValues(alpha: 0.3)
            : Colors.green[50]!,
      },
      {
        'label': t('warning'),
        'count': _countByStatus('warning'),
        'color': Colors.orange[800]!,
        'bg': isDark
            ? Colors.orange[900]!.withValues(alpha: 0.3)
            : Colors.orange[50]!,
      },
      {
        'label': t('critical'),
        'count': 0,
        'color': Colors.red[700]!,
        'bg': isDark
            ? Colors.red[900]!.withValues(alpha: 0.3)
            : Colors.red[50]!,
      },
    ];

    // Use ?? 0.0 so the gauge renders even before data arrives
    final parameters = [
      {
        'id':         'temperature',
        'title':      t('temperature'),
        'rawValue':   _temperature ?? 0.0,
        'unit':       '°C',
        'minSafe':    26.0,
        'maxSafe':    29.0,
        'gaugeColor': Colors.orange,
      },
      {
        'id':         'pH',
        'title':      t('ph_level'),
        'rawValue':   _ph ?? 0.0,
        'unit':       '',
        'minSafe':    7.0,
        'maxSafe':    8.5,
        'gaugeColor': Colors.purple,
      },
      {
        'id':         'ammonia',
        'title':      t('ammonia'),
        'rawValue':   _ammonia ?? 0.0,
        'unit':       'mg/L',
        'minSafe':    0.0,
        'maxSafe':    0.02,
        'gaugeColor': Colors.amber,
      },
      {
        'id':         'turbidity',
        'title':      t('turbidity'),
        'rawValue':   _turbidity ?? 0.0,
        'unit':       'NTU',
        'minSafe':    0.0,
        'maxSafe':    30.0,
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
            // ── System Status card ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
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
                          color: (_hasError
                                  ? Colors.red
                                  : _isConnected
                                      ? Colors.green
                                      : Colors.orange)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (_hasError
                                    ? Colors.red
                                    : _isConnected
                                        ? Colors.green
                                        : Colors.orange)
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _hasError
                                  ? Icons.wifi_off
                                  : Icons.signal_cellular_alt,
                              size: 14,
                              color: _hasError
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _hasError
                                  ? 'Disconnected'
                                  : _isConnected
                                      ? 'Live'
                                      : 'Connecting…',
                              style: const TextStyle(
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
                  if (_hasError) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 16, color: Colors.redAccent),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Could not reach Firebase. Pull down to retry.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // ── No data yet banner (connected but DB path empty) ────
                  if (!_hasError && _isConnected && _temperature == null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.sensors_off,
                              size: 16, color: Colors.orangeAccent),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Waiting for sensor data at /sensors/latest …',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            if (_isRefreshing)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),

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
                  final id  = param['id'] as String;
                  final raw = param['rawValue'] as double;
                  final sv = NotificationService.instance.getSmoothedValue(id);
                  final displayValue = sv ?? raw;

                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ParameterDetailView(
                          title: param['title'] as String,
                          value: displayValue.toStringAsFixed(_valueDecimals(id)),
                          unit: param['unit'] as String,
                          range: _parameterRangeLabel(id),
                          icon: _parameterIcon(id),
                          color: param['gaugeColor'] as Color,
                        ),
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        final anomalous =
                            NotificationService.instance.isAnomalous(id);

                        return GaugeWidget(
                          title:       param['title'] as String,
                          value:       displayValue,
                          minSafe:     param['minSafe'] as double,
                          maxSafe:     param['maxSafe'] as double,
                          unit:        param['unit'] as String,
                          status:      _statusLabel(id, displayValue),
                          statusColor: _statusColor(id, displayValue),
                          gaugeColor:  param['gaugeColor'] as Color,
                          isAnomalous: anomalous,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}