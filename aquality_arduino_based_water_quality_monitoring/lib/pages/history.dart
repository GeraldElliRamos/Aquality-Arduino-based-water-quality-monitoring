import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'parameter_detail.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';
import '../services/language_service.dart';
import '../services/firebase_service.dart';
import '../widgets/dialogs.dart';
import '../widgets/shimmer_loading.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});
  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  String _range = 'week';
  DateTimeRange? _customDateRange;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isConnected = false;
  bool _hasError = false;
  Timer? _refreshTimer;
  final languageService = LanguageService();
  List<Map<String, dynamic>> _records = [];

  String t(String key) => languageService.t(key);

  @override
  void initState() {
    super.initState();
    languageService.addListener(_onLanguageChanged);
    _range = PreferencesService.instance.lastTimeRange;
    _customDateRange = _loadSavedDateRange();

    // Seed immediate local data so History is never visually empty.
    _records = _mapReadingsToRecords(
      _buildSampleReadings(_effectiveDateRange()),
    );
    _isLoading = false;

    _loadHistoryData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) {
        _loadHistoryData();
      }
    });
  }

  void _onLanguageChanged() => setState(() {});

  @override
  void dispose() {
    _refreshTimer?.cancel();
    languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  Future<void> _loadHistoryData() async {
    if (mounted) {
      setState(() {
        _isRefreshing = true;
        _isLoading = _records.isEmpty;
      });
    }

    try {
      debugPrint('[HistoryView] Loading data for range: $_range');
      final dateRange = _effectiveDateRange();
      var readings = await FirebaseService.instance.fetchHistoryRange(
        start: dateRange.start,
        end: dateRange.end,
      );

      debugPrint('[HistoryView] Got ${readings.length} readings from Firestore');

      if (readings.isEmpty) {
        readings = _buildSampleReadings(dateRange);
      }

      final mapped = _mapReadingsToRecords(readings);

      if (mounted) {
        setState(() {
          _records = mapped;
          _isLoading = false;
          _isRefreshing = false;
          _hasError = false;
          _isConnected = readings.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('[HistoryView] Error loading history: $e');
      if (mounted) {
        final dateRange = _effectiveDateRange();
        final sampleReadings = _buildSampleReadings(dateRange);
        final mapped = _mapReadingsToRecords(sampleReadings);

        setState(() {
          _records = mapped;
          _isLoading = false;
          _isRefreshing = false;
          _hasError = true;
          _isConnected = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _mapReadingsToRecords(
    List<WaterQualityReading> readings,
  ) {
    final formatter = DateFormat('MMM d, hh:mm a');
    return readings.reversed.map((reading) {
      final ts = reading.timestamp.millisecondsSinceEpoch.toString();
      return <String, dynamic>{
        'id': ts,
        'date': formatter.format(reading.timestamp),
        'temp': reading.temperature,
        'ph': reading.ph,
        'turbidity': reading.turbidity,
        'nh3': reading.ammonia,
        'timestamp': reading.timestamp,
      };
    }).toList();
  }

  List<WaterQualityReading> _buildSampleReadings(DateTimeRange range) {
    final totalHours = range.end.difference(range.start).inHours;
    final stepHours = totalHours > 72 ? 6 : 2;
    final samples = <WaterQualityReading>[];

    for (int i = 0; i < 12; i++) {
      final ts = range.end.subtract(Duration(hours: i * stepHours));
      if (ts.isBefore(range.start)) break;

      samples.add(
        WaterQualityReading(
          temperature: 27.0 + (i % 4) * 0.35,
          ph: 7.1 + (i % 3) * 0.08,
          ammonia: 0.01 + (i % 4) * 0.002,
          turbidity: 18.0 + (i % 5) * 2.2,
          timestamp: ts,
        ),
      );
    }

    samples.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return samples;
  }

  DateTimeRange _effectiveDateRange() {
    final now = DateTime.now();

    if (_range == 'custom' && _customDateRange != null) {
      return _customDateRange!;
    }

    switch (_range) {
      case 'today':
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );
      case 'yesterday':
        final y = now.subtract(const Duration(days: 1));
        return DateTimeRange(
          start: DateTime(y.year, y.month, y.day),
          end: DateTime(y.year, y.month, y.day, 23, 59, 59),
        );
      case 'month':
      case '30d':
        return DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
      case '24h':
        return DateTimeRange(
          start: now.subtract(const Duration(hours: 24)),
          end: now,
        );
      case '7d':
      case 'week':
      default:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
    }
  }

  DateTimeRange? _loadSavedDateRange() {
    final start = PreferencesService.instance.historyStartDate;
    final end = PreferencesService.instance.historyEndDate;
    if (start != null && end != null) {
      return DateTimeRange(start: start, end: end);
    }
    return null;
  }

  void _saveTimeRange(String range) {
    PreferencesService.instance.setLastTimeRange(range);
  }

  void _saveDateRange(DateTimeRange? range) {
    if (range != null) {
      PreferencesService.instance.setHistoryDateRange(range.start, range.end);
    } else {
      PreferencesService.instance.setHistoryDateRange(null, null);
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialRange =
        _customDateRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _range = 'custom';
        _saveTimeRange('custom');
        _saveDateRange(picked);
      });
      _loadHistoryData();
    }
  }

  void _setQuickFilter(String filter) {
    final now = DateTime.now();
    DateTimeRange range;

    switch (filter) {
      case 'today':
        range = DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );
        break;
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        range = DateTimeRange(
          start: DateTime(yesterday.year, yesterday.month, yesterday.day),
          end: DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
            23,
            59,
            59,
          ),
        );
        break;
      case 'week':
        range = DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
        break;
      case 'month':
        range = DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
        break;
      default:
        return;
    }

    setState(() {
      _customDateRange = range;
      _range = filter;
      _saveTimeRange(filter);
      _saveDateRange(range);
    });
    _loadHistoryData();
  }

  String _getDateRangeText() {
    if (_customDateRange != null) {
      final formatter = DateFormat('MMM d');
      return '${formatter.format(_customDateRange!.start)} - ${formatter.format(_customDateRange!.end)}';
    }
    return _range;
  }

  // Tracks how many times each record has been re-inserted after undo,
  // so re-inserted Dismissible widgets always get a fresh key.
  final Map<String, int> _undoCount = {};

  String _buildCsv(List<Map<String, dynamic>> rows) {
    final headers = ['date', 'temp', 'ph', 'turbidity', 'nh3'];
    final sb = StringBuffer()..writeln(headers.join(','));
    for (final r in rows) {
      sb.writeln(
        '${r['date']},${r['temp']},${r['ph']},${r['turbidity']},${r['nh3']}',
      );
    }
    return sb.toString();
  }

  void _exportCsv() {
    final csv = _buildCsv(_records);
    SuccessSnackBar.show(context, 'Data exported (${csv.length} chars)');
  }

  Map<String, Object> _fieldMeta(String field) {
    switch (field) {
      case 'temp':
        return {
          'title': 'Temperature',
          'unit': '°C',
          'range': '27-30°C',
          'icon': Icons.thermostat,
          'color': Colors.orange,
        };
      case 'ph':
        return {
          'title': 'pH Level',
          'unit': '',
          'range': '6.5-9.0',
          'icon': Icons.water_drop,
          'color': Colors.purple,
        };
      case 'turbidity':
        return {
          'title': 'Turbidity',
          'unit': 'NTU',
          'range': '<=30 NTU',
          'icon': Icons.blur_on,
          'color': Colors.blue,
        };
      case 'nh3':
        return {
          'title': 'Ammonia',
          'unit': 'mg/L',
          'range': '<0.3 mg/L',
          'icon': Icons.waves,
          'color': Colors.green,
        };
      default:
        return {
          'title': field,
          'unit': '',
          'range': '-',
          'icon': Icons.show_chart,
          'color': Colors.blue,
        };
    }
  }

  void _showRecordDetail(
    BuildContext context,
    Map<String, dynamic> r,
    int index,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Record ${r['date']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat.yMMMd().format(DateTime.now()),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _detailChip(ctx, 'temp', r['temp']),
                  _detailChip(ctx, 'ph', r['ph']),
                  _detailChip(ctx, 'turbidity', r['turbidity']),
                  _detailChip(ctx, 'nh3', r['nh3']),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Delete record
                        final removed = Map<String, dynamic>.from(r);
                        final removedId = removed['id'] as String;
                        final removedIndex = _records.indexWhere(
                          (rec) => rec['id'] == removedId,
                        );
                        setState(
                          () => _records.removeWhere(
                            (rec) => rec['id'] == removedId,
                          ),
                        );
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t('record_deleted')),
                            action: SnackBarAction(
                              label: t('undo'),
                              onPressed: () {
                                setState(() {
                                  _records.insert(
                                    removedIndex.clamp(0, _records.length),
                                    removed,
                                  );
                                  _undoCount[removedId] =
                                      (_undoCount[removedId] ?? 0) + 1;
                                });
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_forever),
                      label: Text(t('delete')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final csv =
                            'date,metric,value\n${r['date']},temp,${r['temp']}';
                        SuccessSnackBar.show(
                          context,
                          'Prepared CSV snippet (${csv.length} chars)',
                        );
                        Navigator.of(ctx).pop();
                      },
                      icon: const Icon(Icons.share),
                      label: Text(t('share')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailChip(BuildContext ctx, String key, dynamic value) {
    final meta = _fieldMeta(key);
    return ActionChip(
      avatar: Icon(
        meta['icon'] as IconData,
        size: 18,
        color: meta['color'] as Color,
      ),
      label: Text(
        '${meta['title']}: ${value.toString()} ${meta['unit'] as String}',
      ),
      onPressed: () {
        Navigator.of(ctx).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (c) => ParameterDetailView(
              title: meta['title'] as String,
              value: value.toString(),
              unit: meta['unit'] as String,
              range: meta['range'] as String,
              icon: meta['icon'] as IconData,
              color: meta['color'] as Color,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleRecords = (!_isLoading && _records.isEmpty)
        ? _mapReadingsToRecords(_buildSampleReadings(_effectiveDateRange()))
        : _records;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t('historical_data'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            // Connection status badge
            if (_isRefreshing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (!_isRefreshing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _hasError
                    ? Colors.red.withValues(alpha: 0.1)
                    : (_isConnected
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _hasError
                      ? Colors.red.withValues(alpha: 0.3)
                      : (_isConnected
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.3)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _hasError
                        ? Icons.cloud_off
                        : (_isConnected ? Icons.cloud_done : Icons.cloud_queue),
                      size: 12,
                      color: _hasError
                        ? Colors.red
                        : (_isConnected ? Colors.green : Colors.grey),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _hasError ? 'Error' : (_isConnected ? 'Live' : 'Ready'),
                      style: TextStyle(
                        fontSize: 10,
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
        const SizedBox(height: 12),
        // Error indicator
        if (_hasError && _records.isEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Check Firestore connection in Settings',
                    style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
        // Quick filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _quickFilterChip(t('today'), 'today', isDark),
              _quickFilterChip(t('yesterday'), 'yesterday', isDark),
              _quickFilterChip(t('week'), 'week', isDark),
              _quickFilterChip(t('month'), 'month', isDark),
              _customDateRangeButton(isDark),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Display selected range
        if (_customDateRange != null || _range == 'custom')
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade800.withValues(alpha: 0.5)
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.blue.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  _getDateRangeText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _customDateRange = null;
                      _range = 'week';
                      _saveTimeRange('week');
                      _saveDateRange(null);
                    });
                    _loadHistoryData();
                  },
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        ValueListenableBuilder<bool>(
          valueListenable: AuthService.isAdmin,
          builder: (context, isAdmin, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: AuthService.isLGU,
              builder: (context, isLGU, _) {
                if (!isAdmin && !isLGU) return const SizedBox.shrink();
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _exportCsv,
                    icon: const Icon(
                      Icons.download,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      t('export_csv'),
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 34, 96, 231),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Past Readings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${visibleRecords.length} records',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoading
              ? const ShimmerHistory()
              : visibleRecords.isEmpty
              ? Center(
                  child: Text(
                    'No history data found for this range.',
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: visibleRecords.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final r = visibleRecords[i];
                    final recordId = r['id'] as String;
                    return RepaintBoundary(
                      child: Dismissible(
                        key: Key('${recordId}_${_undoCount[recordId] ?? 0}'),
                        direction: DismissDirection.endToStart,
                        background: Container(),
                        secondaryBackground: Container(
                          padding: const EdgeInsets.only(right: 16),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.delete, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(t('delete')),
                            ],
                          ),
                        ),
                        onDismissed: (direction) {
                          final removed = Map<String, dynamic>.from(r);
                          final removedIndex = _records.indexWhere(
                            (rec) => rec['id'] == recordId,
                          );
                          setState(
                            () => _records.removeWhere(
                              (rec) => rec['id'] == recordId,
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t('record_deleted')),
                              action: SnackBarAction(
                                label: t('undo'),
                                onPressed: () {
                                  setState(() {
                                    _records.insert(
                                      removedIndex.clamp(0, _records.length),
                                      removed,
                                    );
                                    _undoCount[recordId] =
                                        (_undoCount[recordId] ?? 0) + 1;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                        child: Semantics(
                          button: true,
                          label: 'Record ${r['date']}. Tap for details.',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _showRecordDetail(context, r, i),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF2563EB,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.history,
                                    color: Color(0xFF2563EB),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  r['date'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Temp ${r['temp']}°C | pH ${r['ph']} | Turb ${r['turbidity']} NTU | NH3 ${r['nh3']} mg/L',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  padding: const EdgeInsets.only(top: 8),
                ),
        ),
      ],
    );
  }

  void _openParamFromRecord(String key, String value) {
    final meta = _fieldMeta(key);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (c) => ParameterDetailView(
          title: meta['title'] as String,
          value: value,
          unit: meta['unit'] as String,
          range: meta['range'] as String,
          icon: meta['icon'] as IconData,
          color: meta['color'] as Color,
        ),
      ),
    );
  }

  Widget _quickFilterChip(String label, String value, bool isDark) {
    final selected = _range == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _setQuickFilter(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF2563EB)
                : (isDark ? Colors.grey.shade800 : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.grey.shade300 : Colors.black87),
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _customDateRangeButton(bool isDark) {
    final selected = _range == 'custom';
    return GestureDetector(
      onTap: _pickDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2563EB)
              : (isDark ? Colors.grey.shade800 : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.grey.shade300 : Colors.black87),
            ),
            const SizedBox(width: 6),
            Text(
              'Custom',
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade300 : Colors.black87),
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
