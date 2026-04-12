import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AdminView extends StatefulWidget {
  final int initialTab;
  const AdminView({super.key, this.initialTab = 0});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class Device {
  String id;
  String name;
  bool enabled;
  DateTime lastSeen;
  String status;

  Device({
    required this.id,
    required this.name,
    this.enabled = true,
    DateTime? lastSeen,
    this.status = 'online',
  }) : lastSeen = lastSeen ?? DateTime.now();
}

class ThresholdRule {
  String id;
  String parameter;
  String op; // '>' or '<'
  double value;
  String severity; // low/medium/high
  bool enabled;

  ThresholdRule({
    required this.id,
    required this.parameter,
    required this.op,
    required this.value,
    this.severity = 'high',
    this.enabled = true,
  });
}

class _AdminViewState extends State<AdminView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<Device> _devices = [
    Device(
      id: 'dev-001',
      name: 'Pond Sensor 1',
      lastSeen: DateTime.now().subtract(const Duration(seconds: 5)),
      status: 'online',
    ),
  ];

  final List<ThresholdRule> _rules = [
    ThresholdRule(
      id: 'r1',
      parameter: 'pH',
      op: '<',
      value: 6.5,
      severity: 'high',
    ),
  ];

  final List<String> _commandLog = [];

  String _getTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high': return const Color(0xFFDC2626);
      case 'medium': return const Color(0xFFF59E0B);
      case 'low': return const Color(0xFF10B981);
      default: return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addRule() async {
    final result = await showDialog<ThresholdRule>(
      context: context,
      builder: (ctx) {
        String param = 'pH';
        String op = '<';
        String severity = 'high';
        final valueCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Add Threshold Rule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: param,
                items: ['pH', 'Temperature', 'Turbidity', 'Ammonia']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => param = v ?? param,
                decoration: const InputDecoration(labelText: 'Parameter'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: op,
                      items: ['<', '>']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => op = v ?? op,
                      decoration: const InputDecoration(labelText: 'Operator'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: valueCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Value'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: severity,
                items: ['low', 'medium', 'high']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => severity = v ?? severity,
                decoration: const InputDecoration(labelText: 'Severity'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final v = double.tryParse(valueCtrl.text);
                if (v == null) return;
                final rule = ThresholdRule(
                  id: 'r${DateTime.now().millisecondsSinceEpoch}',
                  parameter: param,
                  op: op,
                  value: v,
                  severity: severity,
                );
                Navigator.of(ctx).pop(rule);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() => _rules.add(result));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rule added')));
    }
  }

  static const _maxLogEntries = 100;

  void _sendCommand(Device device, String command) {
    // Simulate sending command to device via gateway/MQTT
    setState(() {
      _commandLog.insert(
        0,
        '${DateTime.now().toIso8601String()} → ${device.id}: $command',
      );
      // Cap log to avoid unbounded memory growth
      if (_commandLog.length > _maxLogEntries) {
        _commandLog.removeRange(_maxLogEntries, _commandLog.length);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sent "$command" to ${device.name}')),
    );
  }

  void _deleteDevice(Device d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Device?'),
        content: Text('Are you sure you want to remove "${d.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _devices.removeWhere((x) => x.id == d.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Device "${d.name}" removed')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthService.isAdmin,
      builder: (context, isAdmin, _) {
        if (!isAdmin) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = isDark ? Colors.white : Colors.black;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Admin Panel'),
              titleTextStyle: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              elevation: 0,
              leading: BackButton(color: textColor),
              centerTitle: false,
              shape: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            body: const Center(child: Text('Access denied. Admins only.')),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Panel'),
            titleTextStyle: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 0,
            leading: BackButton(color: textColor),
            centerTitle: false,
            shape: Border(
              bottom: BorderSide(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                width: 1,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.devices), text: 'Devices', height: 56),
                Tab(icon: Icon(Icons.rule), text: 'Rules', height: 56),
                Tab(icon: Icon(Icons.terminal), text: 'Commands', height: 56),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDevicesTab(),
                _buildRulesTab(),
                _buildCommandsTab(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDevicesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with action
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connected Devices',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_devices.length} device${_devices.length != 1 ? 's' : ''} registered',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(
                  () => _devices.add(
                    Device(
                      id: 'dev-${_devices.length + 1}',
                      name: 'New Device ${_devices.length + 1}',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Device'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Devices list
        Expanded(
          child: _devices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.devices, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('No devices yet', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _devices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final d = _devices[i];
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Card(
                      elevation: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: d.status == 'online'
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: d.status == 'online' ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      d.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      d.status.toUpperCase(),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor: d.status == 'online'
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2),
                                    labelStyle: TextStyle(
                                      color: d.status == 'online' ? Colors.green.shade700 : Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ID: ${d.id}',
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Last seen: ${_getTimeAgo(d.lastSeen)}',
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'toggle') {
                                        setState(() => d.enabled = !d.enabled);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Device ${d.enabled ? 'enabled' : 'disabled'}')),
                                        );
                                      } else if (v == 'remove') {
                                        _deleteDevice(d);
                                      } else if (v == 'command') {
                                        _showCommandDialog(d);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(
                                        value: 'command',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.send, size: 18),
                                            const SizedBox(width: 8),
                                            const Text('Send Command'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'toggle',
                                        child: Row(
                                          children: [
                                            Icon(d.enabled ? Icons.pause : Icons.play_arrow, size: 18),
                                            const SizedBox(width: 8),
                                            Text(d.enabled ? 'Disable' : 'Enable'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'remove',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.delete, size: 18, color: Colors.red),
                                            const SizedBox(width: 8),
                                            const Text('Remove', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (!d.enabled)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Device Disabled',
                                      style: TextStyle(fontSize: 10, color: Colors.orange),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRulesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with action
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Threshold Rules',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_rules.where((r) => r.enabled).length} active rule${_rules.where((r) => r.enabled).length != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addRule,
              icon: const Icon(Icons.add),
              label: const Text('Add Rule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Rules list
        Expanded(
          child: _rules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rule, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('No rules yet', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _rules.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final r = _rules[i];
                    final severityColor = _getSeverityColor(r.severity);
                    return Card(
                      elevation: 2,
                      opacity: r.enabled ? 1.0 : 0.6,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${r.parameter} ${r.op} ${r.value}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Chip(
                                        label: Text(
                                          r.severity.toUpperCase(),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        backgroundColor: severityColor.withOpacity(0.2),
                                        labelStyle: TextStyle(
                                          color: severityColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        side: BorderSide(color: severityColor),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: r.enabled,
                                  onChanged: (v) => setState(() => r.enabled = v),
                                  activeColor: Colors.green,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Rule?'),
                                        content: Text('Are you sure you want to delete the rule "${r.parameter} ${r.op} ${r.value}"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              setState(() => _rules.removeAt(i));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Rule deleted')),
                                              );
                                            },
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCommandsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Remote Commands',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_commandLog.length} command${_commandLog.length != 1 ? 's' : ''} sent',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Send command button
        ElevatedButton.icon(
          onPressed: () {
            if (_devices.isNotEmpty) {
              _showCommandDialog(_devices.first);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No devices available')),
              );
            }
          },
          icon: const Icon(Icons.send),
          label: const Text('Send test command'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        // Commands log
        Text(
          'Command Log',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _commandLog.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('No commands sent yet', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade900
                        : Colors.grey.shade50,
                  ),
                  child: ListView.separated(
                    itemCount: _commandLog.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Colors.grey.shade300,
                      indent: 12,
                      endIndent: 12,
                    ),
                    itemBuilder: (ctx, i) {
                      final isLast = i == _commandLog.length - 1;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green.withOpacity(0.2),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _commandLog[i],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sent just now',
                                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _showCommandDialog(Device d) {
    final ctrl = TextEditingController(text: 'reboot');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Send command to ${d.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, size: 18, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Device: ${d.name}',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  labelText: 'Command',
                  hintText: 'e.g., reboot, reset',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade100,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _sendCommand(d, ctrl.text);
              },
              child: const Text('Send Command'),
            ),
          ],
        );
      },
    );
  }
}
