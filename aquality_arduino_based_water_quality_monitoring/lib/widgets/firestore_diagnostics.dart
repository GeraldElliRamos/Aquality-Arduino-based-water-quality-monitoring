import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class FirestoreDiagnostics extends StatefulWidget {
  const FirestoreDiagnostics({super.key});

  @override
  State<FirestoreDiagnostics> createState() => _FirestoreDiagnosticsState();
}

class _FirestoreDiagnosticsState extends State<FirestoreDiagnostics> {
  String _status = 'Initializing...';
  bool _isListening = false;
  String _latestData = 'No data received yet';
  int _receivedCount = 0;
  DateTime? _lastUpdate;
  String _errors = '';
  Map<String, dynamic> _diagnostics = {};

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _status = 'Testing Firestore connection...';
      _errors = '';
      _diagnostics = {};
    });
    
    try {
      // Run connection test
      final diag = await FirebaseService.instance.testConnection();
      
      setState(() => _diagnostics = diag);

      if (diag['firestore_reachable'] == true && diag['has_data'] == true) {
        _status = '✅ Firestore connected & has data';
        if (diag['parsed_successfully'] == true) {
          final vals = diag['values'] ?? {};
          _latestData = '''
Temperature: ${vals['temperature'] ?? '?'}°C
pH: ${vals['ph'] ?? '?'}
Ammonia: ${vals['ammonia'] ?? '?'} mg/L
Turbidity: ${vals['turbidity'] ?? '?'} NTU
Timestamp: ${vals['timestamp'] ?? '?'}
          ''';
        } else {
          _status = '⚠️ Data exists but parse error: ${diag['parse_error']}';
          _errors = diag['parse_error'] ?? 'Unknown error';
        }
        _startStreamListener();
      } else if (diag['firestore_reachable'] == true && diag['has_data'] == false) {
        _status = '⚠️ Firestore reachable but document empty';
        _errors = diag['help'] ?? '';
      } else {
        _status = '❌ Firestore unreachable';
        _errors = '${diag['error'] ?? 'Unknown error'}\n\n${diag['help'] ?? ''}';
      }
    } catch (e) {
      setState(() {
        _status = '❌ Diagnostic error';
        _errors = e.toString();
      });
      debugPrint('[Diagnostics] Error: $e');
    }
  }

  void _startStreamListener() {
    setState(() => _isListening = true);
    
    FirebaseService.instance.sensorStream.listen(
      (reading) {
        setState(() {
          _receivedCount++;
          _latestData = '''
Temperature: ${reading.temperature}°C
pH: ${reading.ph}
Ammonia: ${reading.ammonia} mg/L
Turbidity: ${reading.turbidity} NTU
Timestamp: ${reading.timestamp}
          ''';
          _lastUpdate = DateTime.now();
          if (_errors.isEmpty) {
            _status = '✅ Live updates active';
          }
        });
        debugPrint('[Diagnostics] Stream event #$_receivedCount: ${reading.temperature}°C');
      },
      onError: (e) {
        setState(() {
          _status = '❌ Stream error';
          _errors = e.toString();
        });
        debugPrint('[Diagnostics] Stream error: $e');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Diagnostics'),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: _status.startsWith('✅') ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _status.startsWith('✅') ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isListening ? '🔴 Listening for updates...' : '⚪ Not listening',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Data Display
            Text(
              'Latest Data Received:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _latestData,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistics',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Updates received: $_receivedCount'),
                        const SizedBox(width: 16),
                        Text(
                          _lastUpdate != null
                              ? 'Last: ${_lastUpdate!.hour}:${_lastUpdate!.minute}:${_lastUpdate!.second}'
                              : 'No updates yet',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Errors
            if (_errors.isNotEmpty) ...[
              Text(
                'Errors:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errors,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.red[700],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _runDiagnostics,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Check that data appears above\n'
                    '2. Look for a timestamp in the latest data\n'
                    '3. If "Listening..." appears, stream is active\n'
                    '4. Updates should appear as stream receives data\n'
                    '5. If stuck on initial fetch, check Firestore rules',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
