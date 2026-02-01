import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});
  @override
  Widget build(BuildContext context) {
    final updatedAt = 'Updated 11:03:25 PM';
    final summary = [
      {'label': 'Optimal', 'count': 5, 'color': Colors.green[700], 'bg': Colors.green[50]},
      {'label': 'Warning', 'count': 0, 'color': Colors.orange[800], 'bg': Colors.orange[50]},
      {'label': 'Critical', 'count': 0, 'color': Colors.red[700], 'bg': Colors.red[50]},
    ];

    final params = [
      {
        'title': 'Temperature',
        'range': '27-30°C',
        'value': '29.4',
        'unit': '°C',
        'icon': Icons.thermostat,
        'status': 'Optimal range',
        'statusColor': Color(0xFF10B981),
        'bg': Color(0xFFFFF6F0)
      },
      {
        'title': 'pH Level',
        'range': '6.5-9.0',
        'value': '6.81',
        'unit': '',
        'icon': Icons.water_drop,
        'status': 'Optimal range',
        'statusColor': Color(0xFF10B981),
        'bg': Color(0xFFF7F4FF)
      },
      {
        'title': 'Chlorine',
        'range': '<0.02 mg/L',
        'value': '0.009',
        'unit': 'mg/L',
        'icon': Icons.warning_amber_rounded,
        'status': 'Safe level',
        'statusColor': Color(0xFF10B981),
        'bg': Color(0xFFFFFBF0)
      },
      {
        'title': 'Dissolved Oxygen',
        'range': '>5 mg/L',
        'value': '6.32',
        'unit': 'mg/L',
        'icon': Icons.air,
        'status': 'Healthy level',
        'statusColor': Color(0xFF10B981),
        'bg': Color(0xFFF0FBFF)
      },
      {
        'title': 'Ammonia',
        'range': '<0.3 mg/L',
        'value': '0.219',
        'unit': 'mg/L',
        'icon': Icons.waves,
        'status': 'Safe level',
        'statusColor': Color(0xFF10B981),
        'bg': Color(0xFFF7FFF6)
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(updatedAt, style: TextStyle(color: Colors.black54)),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
                label: const Text('Refresh', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: const Color.fromARGB(255, 20, 73, 231)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: summary.map((s) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: s['bg'] as Color?,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: s['color'] as Color?, size: 20),
                      const SizedBox(height: 8),
                      Text('${s['count']}', style: TextStyle(color: s['color'] as Color?, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(s['label'].toString(), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Column(
            children: params.map((p) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ParameterCard(
                  title: p['title'] as String,
                  range: p['range'] as String,
                  value: p['value'] as String,
                  unit: p['unit'] as String,
                  icon: p['icon'] as IconData,
                  statusLabel: p['status'] as String,
                  statusColor: p['statusColor'] as Color,
                  background: p['bg'] as Color,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class ParameterCard extends StatelessWidget {
  final String title;
  final String range;
  final String value;
  final String unit;
  final IconData icon;
  final String statusLabel;
  final Color statusColor;
  final Color background;

  const ParameterCard({
    super.key,
    required this.title,
    required this.range,
    required this.value,
    required this.unit,
    required this.icon,
    required this.statusLabel,
    required this.statusColor,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
            child: Icon(icon, color: Colors.orange[700], size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                StatusBadge(label: range, color: Colors.grey.shade200, textColor: Colors.black87),
              ]),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Text(unit, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                const Spacer(),
                StatusBadge(label: statusLabel, color: statusColor.withOpacity(0.12), textColor: statusColor),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const StatusBadge({super.key, required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)), child: Text(label, style: TextStyle(fontSize: 12, color: textColor)));
  }
}
