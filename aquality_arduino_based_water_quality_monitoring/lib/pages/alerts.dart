import 'package:flutter/material.dart';

class AlertsView extends StatefulWidget {
  const AlertsView({super.key});
  @override
  State<AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends State<AlertsView> {
  String _filter = 'All';

  final List<Map<String, dynamic>> alerts = [
    {'level': 'critical', 'title': 'Dissolved oxygen critically low', 'subtitle': 'Dissolved Oxygen: 3.919 mg/L', 'time': '09:32 PM'},
    {'level': 'warning', 'title': 'pH slightly acidic', 'subtitle': 'pH: 6.01', 'time': '09:24 PM'},
    {'level': 'critical', 'title': 'Dissolved oxygen critically low', 'subtitle': 'Dissolved Oxygen: 3.90 mg/L', 'time': '05:25 PM'},
    {'level': 'info', 'title': 'Sensor calibration recommended', 'subtitle': 'System: 0', 'time': '04:43 PM'},
    {'level': 'info', 'title': 'Daily data backup completed', 'subtitle': 'System: 0', 'time': '02:48 PM'},
    {'level': 'critical', 'title': 'Temperature critically high', 'subtitle': 'Temperature: 34.16 °C', 'time': '11:31 AM'},
  ];

  List<Map<String, dynamic>> get _filteredAlerts {
    if (_filter == 'All') return alerts;
    return alerts.where((a) {
      if (_filter == 'Critical') return a['level'] == 'critical';
      if (_filter == 'Warning') return a['level'] == 'warning';
      if (_filter == 'Info') return a['level'] == 'info';
      return true;
    }).toList();
  }

  int countBy(String level) => alerts.where((a) => a['level'] == level.toLowerCase()).length;

  @override
  Widget build(BuildContext context) {
    final critical = countBy('critical');
    final warning = countBy('warning');
    final info = countBy('info');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          _summaryCard(critical, 'Critical', Colors.red.shade50, Colors.red),
          const SizedBox(width: 8),
          _summaryCard(warning, 'Warning', Colors.yellow.shade50, Colors.orange),
          const SizedBox(width: 8),
          _summaryCard(info, 'Info', Colors.blue.shade50, Colors.blue),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: ['All', 'Critical', 'Warning', 'Info'].map((t) {
              final selected = _filter == t;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filter = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: selected ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? Colors.transparent : Colors.grey.shade300),
                    ),
                    child: Text(t, style: TextStyle(color: selected ? Colors.white : Colors.black54)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: _filteredAlerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            padding: const EdgeInsets.only(top: 8),
            itemBuilder: (context, i) {
              final a = _filteredAlerts[i];
              return AlertCard(level: a['level'] as String, title: a['title'] as String, subtitle: a['subtitle'] as String, time: a['time'] as String);
            },
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(int count, String label, Color bg, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
        child: Column(children: [
          CircleAvatar(backgroundColor: accent, radius: 16, child: Icon(Icons.close, color: Colors.white, size: 18)),
          const SizedBox(height: 8),
          Text('$count', style: TextStyle(color: accent, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ]),
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  final String level;
  final String title;
  final String subtitle;
  final String time;
  const AlertCard({super.key, required this.level, required this.title, required this.subtitle, required this.time});

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bg;
    Icon icon;
    switch (level) {
      case 'critical':
        borderColor = Colors.red.shade200;
        bg = Colors.red.shade50;
        icon = Icon(Icons.cancel, color: Colors.red.shade700);
        break;
      case 'warning':
        borderColor = Colors.orange.shade200;
        bg = Colors.yellow.shade50;
        icon = Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800);
        break;
      default:
        borderColor = Colors.blue.shade200;
        bg = Colors.blue.shade50;
        icon = Icon(Icons.info, color: Colors.blue.shade700);
    }

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: icon),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 6), Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12))])),
        Text(time, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ]),
    );
  }
}
