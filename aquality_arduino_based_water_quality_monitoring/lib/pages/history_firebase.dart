import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../services/language_service.dart';
import '../models/history_entry.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});
  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  String _range = '7d';
  DateTimeRange? _customDateRange;
  late FirebaseService _firebaseService;
  final languageService = LanguageService();

  String t(String key) => languageService.t(key);

  @override
  void initState() {
    super.initState();
    languageService.addListener(_onLanguageChanged);
    _firebaseService = FirebaseService();
  }

  void _onLanguageChanged() => setState(() {});

  @override
  void dispose() {
    languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  DateTime _getRangeStart() {
    final now = DateTime.now();
    if (_customDateRange != null) return _customDateRange!.start;
    
    switch (_range) {
      case 'today':
        return DateTime(now.year, now.month, now.day);
      case 'yesterday':
        return now.subtract(const Duration(days: 1));
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return now.subtract(const Duration(days: 30));
      default:
        return now.subtract(const Duration(days: 7));
    }
  }

  DateTime _getRangeEnd() {
    if (_customDateRange != null) return _customDateRange!.end;
    return DateTime.now();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialRange = _customDateRange ??
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
      });
    }
  }

  void _setQuickFilter(String filter) {
    setState(() {
      _range = filter;
      _customDateRange = null;
    });
  }

  String _getDateRangeText() {
    if (_customDateRange != null) {
      final formatter = DateFormat('MMM d');
      return '${formatter.format(_customDateRange!.start)} - ${formatter.format(_customDateRange!.end)}';
    }
    return _range;
  }

  String _buildCsv(List<HistoryEntry> entries) {
    final headers = ['Date', 'Time', 'Temperature (°C)', 'pH', 'Ammonia (mg/L)', 'Turbidity (NTU)'];
    final sb = StringBuffer()..writeln(headers.join(','));
    for (final entry in entries) {
      sb.writeln(
        '${entry.formattedDate},${entry.formattedTime},${entry.temperature.toStringAsFixed(2)},${entry.ph.toStringAsFixed(2)},${entry.ammonia.toStringAsFixed(3)},${entry.turbidity.toStringAsFixed(2)}',
      );
    }
    return sb.toString();
  }

  void _exportCsv(List<HistoryEntry> entries) {
    final csv = _buildCsv(entries);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported (${csv.length} bytes)')),
    );
    // In a real app, you would write this to a file or share it
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rangeStart = _getRangeStart();
    final rangeEnd = _getRangeEnd();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Historical Data',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        
        // Quick filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _quickFilterChip('Today', 'today', isDark),
              const SizedBox(width: 8),
              _quickFilterChip('Yesterday', 'yesterday', isDark),
              const SizedBox(width: 8),
              _quickFilterChip('Week', 'week', isDark),
              const SizedBox(width: 8),
              _quickFilterChip('Month', 'month', isDark),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _range == 'custom' 
                        ? Colors.blue 
                        : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _range == 'custom' ? Colors.blue : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    'Custom',
                    style: TextStyle(
                      color: _range == 'custom' ? Colors.white : null,
                      fontWeight: _range == 'custom' ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        if (_range == 'custom' && _customDateRange != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 14),
                const SizedBox(width: 6),
                Text(_getDateRangeText(), style: const TextStyle(fontSize: 12)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _range = '7d'),
                  child: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        
        // History data
        Expanded(
          child: StreamBuilder<List<HistoryEntry>>(
            stream: _firebaseService.historyStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allEntries = snapshot.data ?? [];
              final filteredEntries = allEntries
                  .where((e) => e.timestamp.isAfter(rangeStart) && e.timestamp.isBefore(rangeEnd))
                  .toList();

              if (filteredEntries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('No data available for this period', 
                        style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: filteredEntries.length + 1,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == filteredEntries.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: () => _exportCsv(filteredEntries),
                        icon: const Icon(Icons.file_download, size: 18),
                        label: const Text('Export as CSV'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    );
                  }

                  final entry = filteredEntries[index];
                  return _buildHistoryTile(entry, isDark);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _quickFilterChip(String label, String value, bool isDark) {
    final isSelected = _range == value;
    return GestureDetector(
      onTap: () => _setQuickFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTile(HistoryEntry entry, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.formattedDate,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                entry.formattedTime,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _parameterBadge('Temp', '${entry.temperature.toStringAsFixed(1)}°C', Colors.orange),
              _parameterBadge('pH', entry.ph.toStringAsFixed(2), Colors.purple),
              _parameterBadge('NH₃', '${entry.ammonia.toStringAsFixed(3)}mg/L', Colors.green),
              _parameterBadge('Turbidity', '${entry.turbidity.toStringAsFixed(1)}NTU', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _parameterBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
