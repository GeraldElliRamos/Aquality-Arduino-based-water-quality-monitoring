import 'package:flutter/material.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});
  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  String _range = '7d';

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported CSV (${csv.length} chars)')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Historical Data', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            Row(
              children: ['24h', '7d', '30d'].map((r) {
                final selected = r == _range;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _range = r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF2563EB) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: selected ? Colors.transparent : Colors.grey.shade300),
                      ),
                      child: Text(r, style: TextStyle(color: selected ? Colors.white : Colors.black87)),
                    ),
                  ),
                );
              }).toList(),
            )
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _exportCsv,
            icon: const Icon(Icons.download, size: 18, color: Colors.white),
            label: const Text('Export CSV', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 34, 96, 231),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}
