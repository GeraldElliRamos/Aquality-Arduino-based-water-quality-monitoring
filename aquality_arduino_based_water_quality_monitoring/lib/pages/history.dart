import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';
import '../widgets/dialogs.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});
  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  String _range = '7d';
  DateTimeRange? _customDateRange;
  
  @override
  void initState() {
    super.initState();
    _range = PreferencesService.instance.lastTimeRange;
    _customDateRange = _loadSavedDateRange();
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
          child: ListView.separated(
            itemCount: _records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = _records[i];
              return Container(
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
                          _metricColumn('${r['temp']}', '°C'),
                          _metricColumn('${r['ph']}', 'pH'),
                          _metricColumn('${r['cl']}', 'Cl'),
                          _metricColumn('${r['do']}', 'DO'),
                          _metricColumn('${r['nh3']}', 'NH₃'),
                        ],
                      ),
                    ),
                  ],
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
