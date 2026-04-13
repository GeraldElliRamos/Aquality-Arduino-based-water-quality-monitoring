import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../models/threshold.dart' as aq;
import '../services/firebase_service.dart';
import '../services/language_service.dart';
import '../services/threshold_service.dart';
import '../utils/color_utils.dart';
import '../utils/format_utils.dart';
import '../widgets/empty_state.dart';

class AlertsViewEnhanced extends StatefulWidget {
  const AlertsViewEnhanced({super.key});

  @override
  State<AlertsViewEnhanced> createState() => _AlertsViewEnhancedState();
}

class _AlertsViewEnhancedState extends State<AlertsViewEnhanced> {
  String _filter = 'All';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  final languageService = LanguageService();
  final List<Alert> _alerts = [];

  StreamSubscription<WaterQualityReading>? _sensorSub;
  StreamSubscription<List<Alert>>? _alertsSub;
  final Map<String, DateTime> _lastAlertAt = {};
  static const Duration _alertCooldown = Duration(minutes: 10);

  String t(String key) => languageService.t(key);

  @override
  void initState() {
    super.initState();
    languageService.addListener(_onLanguageChanged);
    _initLiveAlerts();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.toLowerCase();
      });
    });
  }

  void _onLanguageChanged() => setState(() {});

  @override
  void dispose() {
    languageService.removeListener(_onLanguageChanged);
    _sensorSub?.cancel();
    _alertsSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initLiveAlerts() async {
    _alertsSub = FirebaseService.instance.alertsStream.listen((items) {
      if (!mounted) return;
      setState(() {
        _alerts
          ..clear()
          ..addAll(items);
      });
    });

    try {
      final initial = await FirebaseService.instance.fetchOnce();
      await _processReading(initial);
    } catch (_) {
      // Live stream below will still try to recover.
    }

    _sensorSub = FirebaseService.instance.sensorStream.listen((reading) {
      unawaited(_processReading(reading));
    });
  }

  Future<void> _processReading(WaterQualityReading reading) async {
    final isPlaceholder = reading.temperature == 0.0 &&
        reading.ph == 0.0 &&
        reading.ammonia == 0.0 &&
        reading.turbidity == 0.0;
    if (isPlaceholder) return;

    final stored = await ThresholdService.getAllThresholds();
    final thresholds =
        stored.isEmpty ? ThresholdService.getDefaultThresholds() : stored;

    for (final threshold in thresholds) {
      if (!threshold.enableAlerts) continue;

      final value = _valueForParameter(reading, threshold.parameterId);
      if (value == null) continue;

      final level = _computeLevel(threshold, value);
      if (level == null) continue;

      final cooldownKey = '${threshold.parameterId}:${level.name}';
      final last = _lastAlertAt[cooldownKey];
      if (last != null && DateTime.now().difference(last) < _alertCooldown) {
        continue;
      }
      _lastAlertAt[cooldownKey] = DateTime.now();

      final unit = _unitForParameter(threshold.parameterId);
      final decimals = _decimalsForParameter(threshold.parameterId);
      final formatted = FormatUtils.formatWithUnit(
        value,
        unit,
        decimals: decimals,
      );
      final newAlert = Alert(
        id: '${threshold.parameterId}_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleForAlert(threshold.parameterName, level),
        subtitle: '${threshold.parameterName}: $formatted',
        level: level,
        parameterName: threshold.parameterName,
        reading: value,
        unit: unit,
        timestamp: DateTime.now(),
      );

      await FirebaseService.instance.saveAlert(newAlert);
    }
  }

  double? _valueForParameter(WaterQualityReading reading, String parameterId) {
    switch (parameterId.toLowerCase()) {
      case 'temperature':
        return reading.temperature;
      case 'ph':
      case 'ph level':
        return reading.ph;
      case 'ammonia':
      case 'nh3':
        return reading.ammonia;
      case 'turbidity':
        return reading.turbidity;
      default:
        return null;
    }
  }

  AlertLevel? _computeLevel(aq.Threshold threshold, double value) {
    if (value >= threshold.minSafeValue && value <= threshold.maxSafeValue) {
      return null;
    }

    final isCritical = (threshold.warningMinValue != null &&
            value < threshold.warningMinValue!) ||
        (threshold.warningMaxValue != null && value > threshold.warningMaxValue!);

    return isCritical ? AlertLevel.critical : AlertLevel.warning;
  }

  String _unitForParameter(String parameterId) {
    switch (parameterId.toLowerCase()) {
      case 'temperature':
        return '°C';
      case 'ammonia':
      case 'nh3':
        return 'mg/L';
      case 'turbidity':
        return 'NTU';
      case 'ph':
      case 'ph level':
      default:
        return '';
    }
  }

  int _decimalsForParameter(String parameterId) {
    switch (parameterId.toLowerCase()) {
      case 'temperature':
      case 'ph':
      case 'ph level':
        return 2;
      case 'ammonia':
      case 'nh3':
        return 3;
      case 'turbidity':
        return 1;
      default:
        return 2;
    }
  }

  String _titleForAlert(String parameterName, AlertLevel level) {
    if (level == AlertLevel.critical) {
      return 'Critical $parameterName level';
    }
    return 'Warning $parameterName level';
  }

  List<Alert> get _filteredAlerts {
    var filtered = List<Alert>.from(_alerts);

    // Filter by level
    if (_filter != 'All') {
      filtered = filtered.where((a) {
        if (_filter == 'Critical') return a.level == AlertLevel.critical;
        if (_filter == 'Warning') return a.level == AlertLevel.warning;
        if (_filter == 'Info') return a.level == AlertLevel.info;
        return true;
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((a) {
        return a.title.toLowerCase().contains(_searchQuery) ||
            a.subtitle.toLowerCase().contains(_searchQuery) ||
            (a.parameterName?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    return filtered;
  }

  Map<String, List<Alert>> _groupAlertsByDate(List<Alert> alerts) {
    final groups = <String, List<Alert>>{};

    for (final alert in alerts) {
      String groupKey;
      if (alert.isToday) {
        groupKey = 'Today';
      } else if (alert.isYesterday) {
        groupKey = 'Yesterday';
      } else {
        groupKey = alert.formattedDate;
      }

      groups.putIfAbsent(groupKey, () => []).add(alert);
    }

    return groups;
  }

  int countBy(AlertLevel level) =>
      _alerts.where((a) => a.level == level).length;

  void _showAlertDetail(BuildContext context, Alert alert) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final levelColor = ColorUtils.getAlertLevelColor(alert.level, isDark: isDark);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [Colors.grey.shade900, Colors.grey.shade800]
                    : [Colors.white, Colors.grey.shade50],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with level badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: levelColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: levelColor.withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    alert.level == AlertLevel.critical
                                        ? Icons.error
                                        : alert.level == AlertLevel.warning
                                            ? Icons.warning
                                            : Icons.info,
                                    color: levelColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    alert.level.toString().split('.').last.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: levelColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              alert.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Alert message box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: levelColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: levelColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            alert.subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Details grid
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              FormatUtils.formatDateTime(alert.timestamp),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (alert.parameterName != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Parameter',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                alert.parameterName!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await FirebaseService.instance.deleteAlert(alert.id);
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.close_rounded),
                          label: Text(t('dismiss')),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await FirebaseService.instance.deleteAlert(alert.id);
                            Navigator.pop(ctx);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(t('alert_acknowledged')),
                                backgroundColor: Colors.green.shade600,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_rounded),
                          label: Text(t('acknowledge')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: levelColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredAlerts = _filteredAlerts;
    final groupedAlerts = _groupAlertsByDate(filteredAlerts);

    return Column(
      children: [
        // Filter and Search
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search alerts...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade700 : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('All', countBy(AlertLevel.critical) +
                            countBy(AlertLevel.warning) +
                            countBy(AlertLevel.info),
                        isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'Critical', countBy(AlertLevel.critical), isDark,
                        color: Colors.red),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'Warning', countBy(AlertLevel.warning), isDark,
                        color: Colors.orange),
                    const SizedBox(width: 8),
                    _buildFilterChip('Info', countBy(AlertLevel.info), isDark,
                        color: Colors.blue),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Alerts
        if (filteredAlerts.isEmpty)
          Expanded(
            child: EmptyState(
              icon: Icons.notifications_none,
              title: 'No Alerts',
              description: _searchQuery.isNotEmpty
                  ? 'No alerts match your search'
                  : 'All systems running smoothly',
              message: '',
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: groupedAlerts.keys.length,
              itemBuilder: (context, groupIndex) {
                final groupKey = groupedAlerts.keys.toList()[groupIndex];
                final groupAlerts = groupedAlerts[groupKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Text(
                        groupKey,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    ...groupAlerts.map((alert) {
                      return _buildAlertItem(
                        alert,
                        isDark,
                        onTap: () => _showAlertDetail(context, alert),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int count, bool isDark,
      {Color? color}) {
    final isSelected = _filter == label;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filter = label);
      },
      backgroundColor: isDark ? Colors.grey.shade700 : Colors.white,
      selectedColor: (color ?? Colors.blue).withOpacity(0.2),
      side: BorderSide(
        color: isSelected
            ? (color ?? Colors.blue)
            : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
      ),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: isSelected
            ? (color ?? Colors.blue)
            : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
      ),
    );
  }

  Widget _buildAlertItem(Alert alert, bool isDark,
      {required VoidCallback onTap}) {
    final bgColor = ColorUtils.getAlertBgColor(alert.level, isDark: isDark);
    final levelColor = ColorUtils.getAlertLevelColor(alert.level, isDark: isDark);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: levelColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _getAlertIcon(alert.level),
                    color: levelColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    alert.formattedTime,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: levelColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.arrow_forward_ios, size: 14, color: levelColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAlertIcon(AlertLevel level) {
    switch (level) {
      case AlertLevel.critical:
        return Icons.error;
      case AlertLevel.warning:
        return Icons.warning_amber;
      case AlertLevel.info:
        return Icons.info;
    }
  }
}
