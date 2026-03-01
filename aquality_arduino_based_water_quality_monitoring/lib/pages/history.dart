import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'parameter_detail.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';
import '../widgets/dialogs.dart';
import '../widgets/shimmer_loading.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});
  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  String _range = '7d';
  DateTimeRange? _customDateRange;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _range = PreferencesService.instance.lastTimeRange;
    _customDateRange = _loadSavedDateRange();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _isLoading = false);
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
    final initialRange = _customDateRange ?? DateTimeRange(
      start: now.subtract(const Duration(days: 7)),
      end: now,
    );
    
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _range = 'custom';
        _saveTimeRange('custom');
        _saveDateRange(picked);
      });
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
          end: DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59),
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
  }

  String _getDateRangeText() {
    if (_customDateRange != null) {
      final formatter = DateFormat('MMM d');
      return '${formatter.format(_customDateRange!.start)} - ${formatter.format(_customDateRange!.end)}';
    }
    return _range;
  }

  final List<Map<String, dynamic>> _records = [
    {'date': 'Feb 1', 'temp': 28.1, 'ph': 8.0, 'cl': 0.02, 'do': 6.8, 'nh3': 0.10},
    {'date': 'Feb 1', 'temp': 29.8, 'ph': 6.8, 'cl': 0.00, 'do': 6.7, 'nh3': 0.15},
    {'date': 'Jan 30', 'temp': 27.2, 'ph': 8.2, 'cl': 0.02, 'do': 7.3, 'nh3': 0.22},
  ];

  String _buildCsv(List<Map<String, dynamic>> rows) {
    final headers = ['date','temp','ph','cl','do','nh3'];
    final sb = StringBuffer()..writeln(headers.join(','));
    for (final r in rows) {
      sb.writeln('${r['date']},${r['temp']},${r['ph']},${r['cl']},${r['do']},${r['nh3']}');
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
        return {'title': 'Temperature', 'unit': '°C', 'range': '27-30°C', 'icon': Icons.thermostat, 'color': Colors.orange};
      case 'ph':
        return {'title': 'pH Level', 'unit': '', 'range': '6.5-9.0', 'icon': Icons.water_drop, 'color': Colors.purple};
      case 'cl':
        return {'title': 'Chlorine', 'unit': 'mg/L', 'range': '<0.02 mg/L', 'icon': Icons.warning_amber_rounded, 'color': Colors.amber};
      case 'do':
        return {'title': 'Dissolved Oxygen', 'unit': 'mg/L', 'range': '>5 mg/L', 'icon': Icons.air, 'color': Colors.blue};
      case 'nh3':
        return {'title': 'Ammonia', 'unit': 'mg/L', 'range': '<0.3 mg/L', 'icon': Icons.waves, 'color': Colors.green};
      default:
        return {'title': field, 'unit': '', 'range': '-', 'icon': Icons.show_chart, 'color': Colors.blue};
    }
  }

  void _showRecordDetail(BuildContext context, Map<String, dynamic> r, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Record ${r['date']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(DateFormat.yMMMd().format(DateTime.now()), style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600)),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 8, children: [
              _detailChip(ctx, 'temp', r['temp']),
              _detailChip(ctx, 'ph', r['ph']),
              _detailChip(ctx, 'cl', r['cl']),
              _detailChip(ctx, 'do', r['do']),
              _detailChip(ctx, 'nh3', r['nh3']),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Delete record
                    final removed = Map<String, dynamic>.from(r);
                    setState(() => _records.removeAt(index));
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Record deleted'),
                      action: SnackBarAction(label: 'Undo', onPressed: () {
                        setState(() => _records.insert(index, removed));
                      }),
                    ));
                  },
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final csv = 'date,metric,value\n${r['date']},temp,${r['temp']}';
                    SuccessSnackBar.show(context, 'Prepared CSV snippet (${csv.length} chars)');
                    Navigator.of(ctx).pop();
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
            ])
          ]),
        );
      },
    );
  }

  Widget _detailChip(BuildContext ctx, String key, dynamic value) {
    final meta = _fieldMeta(key);
    return ActionChip(
      avatar: Icon(meta['icon'] as IconData, size: 18, color: meta['color'] as Color),
      label: Text('${meta['title']}: ${value.toString()} ${meta['unit'] as String}'),
      onPressed: () {
        Navigator.of(ctx).pop();
        Navigator.of(context).push(MaterialPageRoute(builder: (c) => ParameterDetailView(
          title: meta['title'] as String,
          value: value.toString(),
          unit: meta['unit'] as String,
          range: meta['range'] as String,
          icon: meta['icon'] as IconData,
          color: meta['color'] as Color,
        )));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Historical Data', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        // Quick filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _quickFilterChip('Today', 'today', isDark),
              _quickFilterChip('Yesterday', 'yesterday', isDark),
              _quickFilterChip('Week', 'week', isDark),
              _quickFilterChip('Month', 'month', isDark),
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
              color: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: 14, color: isDark ? Colors.grey.shade400 : Colors.blue.shade700),
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
                      _range = '7d';
                      _saveTimeRange('7d');
                      _saveDateRange(null);
                    });
                  },
                  child: Icon(Icons.close, size: 14, color: isDark ? Colors.grey.shade400 : Colors.blue.shade700),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        ValueListenableBuilder<bool>(
          valueListenable: AuthService.isAdmin,
          builder: (context, isAdmin, _) {
            if (!isAdmin) return const SizedBox.shrink();
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(
                  Icons.download,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  'Export CSV',
                  style: TextStyle(color: Colors.white),
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
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _isLoading
              ? const ShimmerHistory()
              : ListView.separated(
            itemCount: _records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = _records[i];
              final key = '${r['date']}_$i';
              return Dismissible(
                key: ValueKey(key),
                direction: DismissDirection.endToStart,
                background: Container(),
                secondaryBackground: Container(
                  padding: const EdgeInsets.only(right: 16),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: const [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete')]),
                ),
                onDismissed: (direction) {
                  final removed = Map<String, dynamic>.from(r);
                  setState(() => _records.removeAt(i));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Record deleted'),
                    action: SnackBarAction(label: 'Undo', onPressed: () {
                      setState(() => _records.insert(i, removed));
                    }),
                  ));
                },
                child: Semantics(
                  button: true,
                  label: 'Record ${r['date']}. Tap for details.',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showRecordDetail(context, r, i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 72,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r['date'], style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(onTap: () => _openParamFromRecord('temp', r['temp'].toString()), child: _metricColumn('${r['temp']}', '°C')),
                                GestureDetector(onTap: () => _openParamFromRecord('ph', r['ph'].toString()), child: _metricColumn('${r['ph']}', 'pH')),
                                GestureDetector(onTap: () => _openParamFromRecord('cl', r['cl'].toString()), child: _metricColumn('${r['cl']}', 'Cl')),
                                GestureDetector(onTap: () => _openParamFromRecord('do', r['do'].toString()), child: _metricColumn('${r['do']}', 'DO')),
                                GestureDetector(onTap: () => _openParamFromRecord('nh3', r['nh3'].toString()), child: _metricColumn('${r['nh3']}', 'NH₃')),
                              ],
                            ),
                          ),
                        ],
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

  Widget _metricColumn(String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.black54)),
      ],
    );
  }

  void _openParamFromRecord(String key, String value) {
    final meta = _fieldMeta(key);
    Navigator.of(context).push(MaterialPageRoute(builder: (c) => ParameterDetailView(
      title: meta['title'] as String,
      value: value,
      unit: meta['unit'] as String,
      range: meta['range'] as String,
      icon: meta['icon'] as IconData,
      color: meta['color'] as Color,
    )));
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
            color: selected ? const Color(0xFF2563EB) : (isDark ? Colors.grey.shade800 : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.transparent : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.black87),
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
          color: selected ? const Color(0xFF2563EB) : (isDark ? Colors.grey.shade800 : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: selected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.black87),
            ),
            const SizedBox(width: 6),
            Text(
              'Custom',
              style: TextStyle(
                color: selected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.black87),
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
