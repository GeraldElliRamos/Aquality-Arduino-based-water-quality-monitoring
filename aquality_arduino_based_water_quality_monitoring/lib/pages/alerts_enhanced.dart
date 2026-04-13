import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../models/alert_entry.dart';
import '../services/language_service.dart';
import '../services/firebase_service.dart';
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
  late FirebaseService _firebaseService;

  String t(String key) => languageService.t(key);

  @override
  void initState() {
    super.initState();
    languageService.addListener(_onLanguageChanged);
    _firebaseService = FirebaseService();
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
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Get alert level from alert type
  AlertLevel _getAlertLevel(String type) {
    switch (type.toLowerCase()) {
      case 'critical':
        return AlertLevel.critical;
      case 'warning':
        return AlertLevel.warning;
      default:
        return AlertLevel.info;
    }
  }

  /// Convert AlertEntry to Alert for UI
  Alert _convertToAlert(AlertEntry entry) {
    final level = _getAlertLevel(entry.type);
    final unit = _getUnitForParameter(entry.parameter);
    
    return Alert(
      id: entry.id,
      title: _getTitleForAlert(entry),
      subtitle: '${entry.parameterDisplay}: ${entry.value.toStringAsFixed(2)} $unit',
      level: level,
      parameterName: entry.parameterDisplay,
      reading: entry.value,
      unit: unit,
      timestamp: entry.timestamp,
    );
  }

  String _getTitleForAlert(AlertEntry entry) {
    switch (entry.parameter) {
      case 'temperature':
        if (entry.type == 'Critical') {
          return entry.value > 32 ? 'Water Too Hot' : 'Water Too Cold';
        }
        return 'Temperature Warning';
      case 'ph':
        return entry.value < 6.5 ? 'Water Too Acidic' : 'Water Too Alkaline';
      case 'nh3':
        return 'Ammonia Level High';
      case 'turbidity':
        return 'Water Cloudy';
      default:
        return '${entry.parameterDisplay} Alert';
    }
  }

  String _getUnitForParameter(String parameter) {
    switch (parameter) {
      case 'temperature':
        return '°C';
      case 'ph':
        return '';
      case 'nh3':
        return 'mg/L';
      case 'turbidity':
        return 'NTU';
      default:
        return '';
    }
  }

  List<Alert> _filterAlerts(List<AlertEntry> entries) {
    var alerts = entries.map(_convertToAlert).toList();

    // Filter by level
    if (_filter != 'All') {
      alerts = alerts.where((a) {
        if (_filter == 'Critical') return a.level == AlertLevel.critical;
        if (_filter == 'Warning') return a.level == AlertLevel.warning;
        if (_filter == 'Info') return a.level == AlertLevel.info;
        return true;
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      alerts = alerts.where((a) {
        return a.title.toLowerCase().contains(_searchQuery) ||
            a.subtitle.toLowerCase().contains(_searchQuery) ||
            (a.parameterName?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    return alerts;
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
                          onPressed: () {
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
                          onPressed: () {
                            Navigator.pop(ctx);
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
              StreamBuilder<List<AlertEntry>>(
                stream: _firebaseService.alertsStream,
                builder: (context, snapshot) {
                  final entries = snapshot.data ?? [];
                  final alerts = entries.map(_convertToAlert).toList();
                  
                  int critical = alerts.where((a) => a.level == AlertLevel.critical).length;
                  int warning = alerts.where((a) => a.level == AlertLevel.warning).length;
                  int info = alerts.where((a) => a.level == AlertLevel.info).length;

                  return SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip('All', critical + warning + info, isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('Critical', critical, isDark, color: Colors.red),
                        const SizedBox(width: 8),
                        _buildFilterChip('Warning', warning, isDark, color: Colors.orange),
                        const SizedBox(width: 8),
                        _buildFilterChip('Info', info, isDark, color: Colors.blue),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Alerts
        Expanded(
          child: StreamBuilder<List<AlertEntry>>(
            stream: _firebaseService.alertsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final entries = snapshot.data ?? [];
              final alerts = _filterAlerts(entries);
              final groupedAlerts = _groupAlertsByDate(alerts);

              if (alerts.isEmpty) {
                return EmptyState(
                  icon: Icons.notifications_none,
                  title: 'No Alerts',
                  description: _searchQuery.isNotEmpty
                      ? 'No alerts match your search'
                      : 'All systems running smoothly',
                  message: '',
                );
              }

              return ListView.builder(
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
