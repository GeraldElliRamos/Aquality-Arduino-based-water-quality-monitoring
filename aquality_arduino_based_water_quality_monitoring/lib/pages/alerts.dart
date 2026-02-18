import 'package:flutter/material.dart';
import '../widgets/empty_state.dart';

class AlertsView extends StatefulWidget {
  const AlertsView({super.key});
  @override
  State<AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends State<AlertsView> {
  String _filter = 'All';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> alerts = [
    {'level': 'critical', 'title': 'Dissolved oxygen critically low', 'subtitle': 'Dissolved Oxygen: 3.919 mg/L', 'time': '09:32 PM'},
    {'level': 'warning', 'title': 'pH slightly acidic', 'subtitle': 'pH: 6.01', 'time': '09:24 PM'},
    {'level': 'critical', 'title': 'Dissolved oxygen critically low', 'subtitle': 'Dissolved Oxygen: 3.90 mg/L', 'time': '05:25 PM'},
    {'level': 'info', 'title': 'Sensor calibration recommended', 'subtitle': 'System: 0', 'time': '04:43 PM'},
    {'level': 'info', 'title': 'Daily data backup completed', 'subtitle': 'System: 0', 'time': '02:48 PM'},
    {'level': 'critical', 'title': 'Temperature critically high', 'subtitle': 'Temperature: 34.16 °C', 'time': '11:31 AM'},
  ];

  List<Map<String, dynamic>> get _filteredAlerts {
    var filtered = alerts;
    
    // Filter by level
    if (_filter != 'All') {
      filtered = filtered.where((a) {
        if (_filter == 'Critical') return a['level'] == 'critical';
        if (_filter == 'Warning') return a['level'] == 'warning';
        if (_filter == 'Info') return a['level'] == 'info';
        return true;
      }).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((a) {
        final title = (a['title'] as String).toLowerCase();
        final subtitle = (a['subtitle'] as String).toLowerCase();
        return title.contains(_searchQuery) || subtitle.contains(_searchQuery);
      }).toList();
    }
    
    return filtered;
  }

  int countBy(String level) => alerts.where((a) => a['level'] == level.toLowerCase()).length;

  void _showAlertDetail(BuildContext context, Map<String, dynamic> a) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(a['title'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                Text(a['time'] as String, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600)),
              ]),
              const SizedBox(height: 8),
              Text(a['subtitle'] as String, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : Colors.grey.shade700)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Acknowledge: remove alert
                      setState(() {
                        alerts.removeAt(alerts.indexWhere((it) => it['title'] == a['title'] && it['time'] == a['time']));
                      });
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert acknowledged')));
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Acknowledge'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Close'),
                  ),
                ),
              ])
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final critical = countBy('critical');
    final warning = countBy('warning');
    final info = countBy('info');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          _summaryCard(critical, 'Critical', isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50, Colors.red, isDark),
          const SizedBox(width: 8),
          _summaryCard(warning, 'Warning', isDark ? Colors.orange.shade900.withOpacity(0.3) : Colors.yellow.shade50, Colors.orange, isDark),
          const SizedBox(width: 8),
          _summaryCard(info, 'Info', isDark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50, Colors.blue, isDark),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search alerts...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchCtrl.clear(),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
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
                      color: selected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.grey.shade800 : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? Colors.transparent : (isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                    ),
                    child: Text(t, style: TextStyle(color: selected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.grey.shade400 : Colors.black54))),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _filteredAlerts.isEmpty
              ? EmptyState(
                  icon: _searchQuery.isNotEmpty ? Icons.search_off : Icons.notifications_off,
                  title: _searchQuery.isNotEmpty ? 'No Results' : 'No Alerts',
                  message: _searchQuery.isNotEmpty
                      ? 'Try different search terms'
                      : 'No alerts for this filter',
                )
                : ListView.separated(
                    itemCount: _filteredAlerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    padding: const EdgeInsets.only(top: 8),
                    itemBuilder: (context, i) {
                      final a = _filteredAlerts[i];
                      final key = '${a['title']}_${a['time']}_$i';
                      return Dismissible(
                        key: ValueKey(key),
                        background: Container(
                          padding: const EdgeInsets.only(left: 16),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                          child: Row(children: const [Icon(Icons.check, color: Colors.green), SizedBox(width: 8), Text('Acknowledge')]),
                        ),
                        secondaryBackground: Container(
                          padding: const EdgeInsets.only(right: 16),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: const [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Dismiss')]),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Acknowledge
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Acknowledge Alert'),
                                content: Text('Mark "${a['title']}" as acknowledged?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                  ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Acknowledge')),
                                ],
                              ),
                            );
                            return confirmed == true;
                          }
                          // Dismiss on end-to-start without confirm
                          return true;
                        },
                        onDismissed: (direction) {
                          setState(() {
                            alerts.removeAt(alerts.indexWhere((it) => it['title'] == a['title'] && it['time'] == a['time']));
                          });
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(direction == DismissDirection.startToEnd ? 'Alert acknowledged' : 'Alert dismissed')));
                        },
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showAlertDetail(context, a),
                          child: AlertCard(level: a['level'] as String, title: a['title'] as String, subtitle: a['subtitle'] as String, time: a['time'] as String, isDark: isDark),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _summaryCard(int count, String label, Color bg, Color accent, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.black12)),
        child: Column(children: [
          CircleAvatar(backgroundColor: accent, radius: 16, child: Icon(Icons.close, color: Colors.white, size: 18)),
          const SizedBox(height: 8),
          Text('$count', style: TextStyle(color: accent, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.black54)),
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
  final bool isDark;
  const AlertCard({super.key, required this.level, required this.title, required this.subtitle, required this.time, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bg;
    Icon icon;
    switch (level) {
      case 'critical':
        borderColor = isDark ? Colors.red.shade900 : Colors.red.shade200;
        bg = isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50;
        icon = Icon(Icons.cancel, color: Colors.red.shade700);
        break;
      case 'warning':
        borderColor = isDark ? Colors.orange.shade900 : Colors.orange.shade200;
        bg = isDark ? Colors.orange.shade900.withOpacity(0.3) : Colors.yellow.shade50;
        icon = Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800);
        break;
      default:
        borderColor = isDark ? Colors.blue.shade900 : Colors.blue.shade200;
        bg = isDark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50;
        icon = Icon(Icons.info, color: Colors.blue.shade700);
    }

    return Semantics(
      button: true,
      label: '$title. $subtitle. Time: $time. Level: $level',
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.white, borderRadius: BorderRadius.circular(8)), child: icon),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 6), Text(subtitle, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black54, fontSize: 12))])),
          Text(time, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black54, fontSize: 12)),
        ]),
      ),
    );
  }
}
