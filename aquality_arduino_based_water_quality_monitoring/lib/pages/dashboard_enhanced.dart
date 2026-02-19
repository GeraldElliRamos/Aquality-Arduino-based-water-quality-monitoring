import 'package:flutter/material.dart';
import '../widgets/gauge_widget.dart';
import '../utils/color_utils.dart';
import '../utils/format_utils.dart';
import '../services/auth_service.dart';
import './parameter_detail.dart';

class DashboardEnhanced extends StatefulWidget {
  const DashboardEnhanced({super.key});

  @override
  State<DashboardEnhanced> createState() => _DashboardEnhancedState();
}

class _DashboardEnhancedState extends State<DashboardEnhanced> {
  String _updatedAt = 'Updated just now';
  bool _isRefreshing = false;

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _updatedAt = 'Updated ${FormatUtils.formatTimeAgo(DateTime.now())}';
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final summary = [
      {
        'label': 'Optimal',
        'count': 5,
        'color': Colors.green[700],
        'bg': isDark ? Colors.green[900]!.withOpacity(0.3) : Colors.green[50],
      },
      {
        'label': 'Warning',
        'count': 0,
        'color': Colors.orange[800],
        'bg': isDark ? Colors.orange[900]!.withOpacity(0.3) : Colors.orange[50],
      },
      {
        'label': 'Critical',
        'count': 0,
        'color': Colors.red[700],
        'bg': isDark ? Colors.red[900]!.withOpacity(0.3) : Colors.red[50],
      },
    ];

    final parameters = [
      {
        'title': 'Temperature',
        'value': 29.4,
        'unit': '°C',
        'minSafe': 27,
        'maxSafe': 30,
        'status': 'Optimal range',
        'statusColor': Color(0xFF10B981),
        'gaugeColor': Colors.orange,
      },
      {
        'title': 'pH Level',
        'value': 6.81,
        'unit': '',
        'minSafe': 6.5,
        'maxSafe': 9.0,
        'status': 'Optimal range',
        'statusColor': Color(0xFF10B981),
        'gaugeColor': Colors.purple,
      },
      {
        'title': 'Chlorine',
        'value': 0.009,
        'unit': 'mg/L',
        'minSafe': 0,
        'maxSafe': 0.02,
        'status': 'Safe level',
        'statusColor': Color(0xFF10B981),
        'gaugeColor': Colors.amber,
      },
      {
        'title': 'Dissolved Oxygen',
        'value': 6.32,
        'unit': 'mg/L',
        'minSafe': 5,
        'maxSafe': 10,
        'status': 'Healthy level',
        'statusColor': Color(0xFF10B981),
        'gaugeColor': Colors.blue,
      },
    ];

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [Color(0xFF1E293B), Color(0xFF0F172A)]
                      : [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: summary.map((item) {
                      return Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: item['bg'] as Color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (item['color'] as Color).withOpacity(0.3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${item['count']}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: item['color'] as Color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['label'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _updatedAt,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.4),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.signal_cellular_alt,
                                size: 14, color: Colors.greenAccent),
                            SizedBox(width: 4),
                            Text(
                              'Connected',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons - responsive to admin status
            ValueListenableBuilder<bool>(
              valueListenable: AuthService.isAdmin,
              builder: (context, isAdmin, _) {
                if (isAdmin) {
                  return SizedBox(
                    height: 65,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.tune,
                            label: 'Thresholds',
                            onTap: () =>
                                Navigator.of(context).pushNamed('/thresholds'),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.file_download,
                            label: 'Export',
                            onTap: () => _showExportOptions(context),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.refresh,
                            label: 'Refresh',
                            onTap: _onRefresh,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 100),
                    child: SizedBox(
                      height: 65,
                      child: _buildActionCard(
                        icon: Icons.refresh,
                        label: 'Refresh',
                        onTap: _onRefresh,
                        isDark: isDark,
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),

            const Text(
              'Parameter Status',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.7,
              ),
              itemCount: parameters.length,
              itemBuilder: (context, index) {
                final param = parameters[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ParameterDetail(
                          title: param['title'] as String,
                        ),
                      ),
                    );
                  },
                  child: GaugeWidget(
                    title: param['title'] as String,
                    value: param['value'] as double,
                    minSafe: param['minSafe'] as double,
                    maxSafe: param['maxSafe'] as double,
                    unit: param['unit'] as String,
                    status: param['status'] as String,
                    statusColor: param['statusColor'] as Color,
                    gaugeColor: param['gaugeColor'] as Color,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Colors.blue.shade600),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Export Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as CSV'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting as CSV...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting as PDF...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.data_object),
              title: const Text('Export as JSON'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting as JSON...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget ParameterDetail({required String title}) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: const Center(child: Text('Parameter details coming soon')),
  );
}



