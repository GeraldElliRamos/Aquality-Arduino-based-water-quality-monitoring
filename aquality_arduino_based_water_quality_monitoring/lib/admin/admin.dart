import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class Device {
  String id;
  String name;
  bool enabled;
  DateTime lastSeen;
  String status;

  Device({required this.id, required this.name, this.enabled = true, DateTime? lastSeen, this.status = 'online'}) : lastSeen = lastSeen ?? DateTime.now();
}

class ThresholdRule {
  String id;
  String parameter;
  String op; // '>' or '<'
  double value;
  String severity; // low/medium/high
  bool enabled;

  ThresholdRule({required this.id, required this.parameter, required this.op, required this.value, this.severity = 'high', this.enabled = true});
}

class _AdminViewState extends State<AdminView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<Device> _devices = [
    Device(id: 'dev-001', name: 'Pond Sensor 1', lastSeen: DateTime.now().subtract(const Duration(seconds: 5)), status: 'online'),
  ];

  final List<ThresholdRule> _rules = [
    ThresholdRule(id: 'r1', parameter: 'pH', op: '<', value: 6.5, severity: 'high'),
  ];

  final List<String> _commandLog = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addRule() async {
    final result = await showDialog<ThresholdRule>(context: context, builder: (ctx) {
      String param = 'pH';
      String op = '<';
      String severity = 'high';
      final valueCtrl = TextEditingController();
      return AlertDialog(
        title: const Text('Add Threshold Rule'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(value: param, items: ['pH','Temperature','Dissolved Oxygen','Chlorine','Ammonia'].map((e)=>DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v)=> param = v ?? param, decoration: const InputDecoration(labelText: 'Parameter')),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(value: op, items: ['<','>'].map((e)=>DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v)=> op = v ?? op, decoration: const InputDecoration(labelText: 'Operator'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: valueCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Value'))),
          ]),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(value: severity, items: ['low','medium','high'].map((e)=>DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v)=> severity = v ?? severity, decoration: const InputDecoration(labelText: 'Severity')),
        ]),
        actions: [TextButton(onPressed: ()=> Navigator.of(ctx).pop(), child: const Text('Cancel')), ElevatedButton(onPressed: (){
          final v = double.tryParse(valueCtrl.text);
          if (v == null) return; 
          final rule = ThresholdRule(id: 'r${DateTime.now().millisecondsSinceEpoch}', parameter: param, op: op, value: v, severity: severity);
          Navigator.of(ctx).pop(rule);
        }, child: const Text('Add'))],
      );
    });

    if (result != null) {
      setState(() => _rules.add(result));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rule added')));
    }
  }

  static const _maxLogEntries = 100;

  void _sendCommand(Device device, String command) {
    // Simulate sending command to device via gateway/MQTT
    setState(() {
      _commandLog.insert(0, '${DateTime.now().toIso8601String()} → ${device.id}: $command');
      // Cap log to avoid unbounded memory growth
      if (_commandLog.length > _maxLogEntries) {
        _commandLog.removeRange(_maxLogEntries, _commandLog.length);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent "$command" to ${device.name}')));
  }

  void _deleteDevice(Device d) {
    setState(() => _devices.removeWhere((x) => x.id == d.id));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device removed')));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthService.isAdmin,
      builder: (context, isAdmin, _) {
        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Admin Panel'), backgroundColor: const Color(0xFF2563EB)),
            body: const Center(child: Text('Access denied. Admins only.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Panel'),
            backgroundColor: const Color(0xFF2563EB),
            bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Devices'), Tab(text: 'Rules'), Tab(text: 'Commands')]),
            actions: [
              IconButton(icon: const Icon(Icons.logout), onPressed: (){ AuthService.logout(); Navigator.of(context).pushReplacementNamed('/login'); }, tooltip: 'Logout'),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TabBarView(controller: _tabController, children: [
              _buildDevicesTab(),
              _buildRulesTab(),
              _buildCommandsTab(),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildDevicesTab() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('Devices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), TextButton.icon(onPressed: (){ setState(()=> _devices.add(Device(id: 'dev-${_devices.length+1}', name: 'New Device ${_devices.length+1}'))); }, icon: const Icon(Icons.add), label: const Text('Add Device'))]),
      const SizedBox(height: 8),
      Expanded(child: ListView.separated(itemCount: _devices.length, separatorBuilder: (_,__)=>const SizedBox(height:8), itemBuilder: (context,i){ final d = _devices[i]; return Card(child: ListTile(
        leading: CircleAvatar(backgroundColor: d.status == 'online' ? Colors.green : Colors.grey, child: Text(d.name[0])),
        title: Text(d.name),
        subtitle: Text('Last seen: ${d.lastSeen}'),
        trailing: PopupMenuButton<String>(onSelected: (v){ if (v=='toggle'){ setState(()=> d.enabled = !d.enabled);} else if (v=='remove'){ _deleteDevice(d);} else if (v=='command'){ _showCommandDialog(d);} }, itemBuilder: (ctx)=>[PopupMenuItem(value:'toggle', child: Text(d.enabled? 'Disable':'Enable')), const PopupMenuItem(value:'command', child: Text('Send Command')), const PopupMenuItem(value:'remove', child: Text('Remove'))]),
      )); })),
    ]);
  }

  Widget _buildRulesTab() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('Threshold Rules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), ElevatedButton.icon(onPressed: _addRule, icon: const Icon(Icons.add), label: const Text('Add Rule'))]),
      const SizedBox(height: 12),
      Expanded(child: _rules.isEmpty ? const Center(child: Text('No rules')) : ListView.separated(itemCount: _rules.length, separatorBuilder: (_,__)=>const SizedBox(height:8), itemBuilder: (ctx,i){ final r = _rules[i]; return Card(child: ListTile(
        title: Text('${r.parameter} ${r.op} ${r.value}'),
        subtitle: Text('Severity: ${r.severity}'),
        leading: Switch(value: r.enabled, onChanged: (v)=> setState(()=> r.enabled = v)),
        trailing: IconButton(icon: const Icon(Icons.delete), onPressed: ()=> setState(()=> _rules.removeAt(i))),
      )); })),
    ]);
  }

  Widget _buildCommandsTab() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Remote Commands', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ElevatedButton.icon(onPressed: (){ if (_devices.isNotEmpty) _showCommandDialog(_devices.first); else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No devices available'))); }, icon: const Icon(Icons.play_arrow), label: const Text('Send test command')),
      const SizedBox(height: 12),
      Expanded(
        child: _commandLog.isEmpty
          ? const Center(child: Text('No commands sent yet'))
          : ListView.builder(
              // builder is already virtualised; key ensures stable item identity
              itemCount: _commandLog.length,
              itemBuilder: (ctx, i) => RepaintBoundary(
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.terminal, size: 16),
                  title: Text(_commandLog[i], style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                ),
              ),
            ),
      ),
    ]);
  }

  void _showCommandDialog(Device d) {
    final ctrl = TextEditingController(text: 'reboot');
    showDialog(context: context, builder: (ctx){ return AlertDialog(title: Text('Send command to ${d.name}'), content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Command')), actions: [TextButton(onPressed: ()=> Navigator.of(ctx).pop(), child: const Text('Cancel')), ElevatedButton(onPressed: (){ Navigator.of(ctx).pop(); _sendCommand(d, ctrl.text); }, child: const Text('Send'))]); });
  }
}
