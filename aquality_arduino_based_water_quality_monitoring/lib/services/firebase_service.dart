import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../models/water_quality_reading.dart';
import '../models/history_entry.dart';
import '../models/alert_entry.dart';
import '../models/threshold.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  
  late FirebaseDatabase _database;
  StreamSubscription? _aqualityListener;
  StreamSubscription? _alertListener;
  StreamSubscription? _historyListener;

  // Stream controllers for state management
  final _currentReadingController = StreamController<WaterQualityReading>.broadcast();
  final _alertsController = StreamController<List<AlertEntry>>.broadcast();
  final _historyController = StreamController<List<HistoryEntry>>.broadcast();

  // Cache for latest values
  WaterQualityReading? _lastReading;
  List<AlertEntry> _alertCache = [];
  List<HistoryEntry> _historyCache = [];

  // Database references
  late DatabaseReference _aqualityRef;
  late DatabaseReference _alertsRef;
  late DatabaseReference _historyRef;

  factory FirebaseService() => _instance;

  FirebaseService._internal();

  /// Initialize Firebase Database service
  Future<void> init() async {
    _database = FirebaseDatabase.instance;
    
    // Set database URL explicitly
    _aqualityRef = _database.ref('Aquality');
    _alertsRef = _database.ref('AqualityAlerts');
    _historyRef = _database.ref('AqualityHistory');

    _setupListeners();
  }

  /// Setup real-time listeners for all data sources
  void _setupListeners() {
    // Listen to real-time updates from Aquality node
    _aqualityListener = _aqualityRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          final reading = WaterQualityReading.fromMap(data);
          _lastReading = reading;
          _currentReadingController.add(reading);
          
          // Check for threshold breaches and create alerts if needed
          _checkAndCreateAlerts(reading);
          
          // Save to history
          _saveToHistory(reading);
        }
      }
    });

    // Listen to alerts
    _alertListener = _alertsRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          _alertCache = [];
          data.forEach((key, value) {
            if (value is Map<dynamic, dynamic>) {
              _alertCache.add(AlertEntry.fromMap(key, value));
            }
          });
          // Sort by timestamp descending (newest first)
          _alertCache.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _alertsController.add(_alertCache);
        }
      }
    });

    // Listen to history updates
    _historyListener = _historyRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          _historyCache = [];
          data.forEach((key, value) {
            if (value is Map<dynamic, dynamic>) {
              _historyCache.add(HistoryEntry.fromMap(key, value));
            }
          });
          // Sort by timestamp descending (newest first)
          _historyCache.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _historyController.add(_historyCache);
        }
      }
    });
  }

  /// Get current reading stream
  Stream<WaterQualityReading> get currentReadingStream => _currentReadingController.stream;

  /// Get alerts stream
  Stream<List<AlertEntry>> get alertsStream => _alertsController.stream;

  /// Get history stream
  Stream<List<HistoryEntry>> get historyStream => _historyController.stream;

  /// Get last known reading
  WaterQualityReading? get lastReading => _lastReading;

  /// Get current alerts cache
  List<AlertEntry> get alertCache => _alertCache;

  /// Get current history cache
  List<HistoryEntry> get historyCache => _historyCache;

  /// Determine parameter status based on value and thresholds
  String _getParameterStatus(String parameter, double value) {
    switch (parameter) {
      case 'temperature':
        if (value >= 27.0 && value <= 30.0) return 'optimal';
        if (value >= 25.0 && value <= 32.0) return 'warning';
        return 'critical';
      
      case 'ph':
        if (value >= 6.5 && value <= 9.0) return 'optimal';
        return 'critical';
      
      case 'nh3':
        if (value >= 0.0 && value <= 0.02) return 'safe';
        if (value > 0.02 && value <= 0.05) return 'warning';
        return 'critical';
      
      case 'turbidity':
        if (value >= 0.0 && value <= 30.0) return 'safe';
        if (value > 30.0 && value <= 50.0) return 'warning';
        return 'critical';
      
      default:
        return 'unknown';
    }
  }

  /// Check for threshold breaches and create alerts
  Future<void> _checkAndCreateAlerts(WaterQualityReading reading) async {
    final alerts = <AlertEntry>[];
    
    // Check temperature
    final tempStatus = _getParameterStatus('temperature', reading.temperature);
    if (tempStatus == 'critical') {
      alerts.add(_createAlertForBreach(
        'temperature',
        reading.temperature,
        tempStatus,
      ));
    } else if (tempStatus == 'warning') {
      alerts.add(_createAlertForBreach(
        'temperature',
        reading.temperature,
        tempStatus,
      ));
    }

    // Check pH
    final phStatus = _getParameterStatus('ph', reading.ph);
    if (phStatus == 'critical') {
      alerts.add(_createAlertForBreach(
        'ph',
        reading.ph,
        phStatus,
      ));
    }

    // Check NH3 (Ammonia)
    final nh3Status = _getParameterStatus('nh3', reading.ammonia);
    if (nh3Status == 'critical') {
      alerts.add(_createAlertForBreach(
        'nh3',
        reading.ammonia,
        nh3Status,
      ));
    } else if (nh3Status == 'warning') {
      alerts.add(_createAlertForBreach(
        'nh3',
        reading.ammonia,
        nh3Status,
      ));
    }

    // Check Turbidity
    final turbidityStatus = _getParameterStatus('turbidity', reading.turbidity);
    if (turbidityStatus == 'critical') {
      alerts.add(_createAlertForBreach(
        'turbidity',
        reading.turbidity,
        turbidityStatus,
      ));
    } else if (turbidityStatus == 'warning') {
      alerts.add(_createAlertForBreach(
        'turbidity',
        reading.turbidity,
        turbidityStatus,
      ));
    }

    // Save alerts if any were created
    for (final alert in alerts) {
      await _saveAlert(alert);
    }
  }

  /// Create an alert for a parameter breach
  AlertEntry _createAlertForBreach(String parameter, double value, String status) {
    final typeMap = {
      'critical': 'Critical',
      'warning': 'Warning',
      'danger': 'Critical',
    };

    return AlertEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: typeMap[status] ?? 'Info',
      parameter: parameter,
      value: value,
      timestamp: DateTime.now(),
      description: _getAlertDescription(parameter, value, status),
    );
  }

  /// Get human-readable description for alert
  String _getAlertDescription(String parameter, double value, String status) {
    final statusStr = status == 'critical' ? 'Critical' : 'Warning';
    switch (parameter) {
      case 'temperature':
        return 'Temperature is $statusStr: ${value.toStringAsFixed(2)}°C';
      case 'ph':
        return 'pH Level is $statusStr: ${value.toStringAsFixed(2)}';
      case 'nh3':
        return 'Ammonia is $statusStr: ${value.toStringAsFixed(3)} mg/L';
      case 'turbidity':
        return 'Turbidity is $statusStr: ${value.toStringAsFixed(2)} NTU';
      default:
        return '$statusStr: $value';
    }
  }

  /// Save alert to Firebase
  Future<void> _saveAlert(AlertEntry alert) async {
    try {
      await _alertsRef.child(alert.id).set(alert.toMap());
    } catch (e) {
      print('Error saving alert: $e');
    }
  }

  /// Save reading to history
  Future<void> _saveToHistory(WaterQualityReading reading) async {
    try {
      final timestamp = DateTime.now();
      final historyEntry = HistoryEntry(
        id: timestamp.millisecondsSinceEpoch.toString(),
        temperature: reading.temperature,
        ph: reading.ph,
        ammonia: reading.ammonia,
        turbidity: reading.turbidity,
        timestamp: timestamp,
      );
      await _historyRef.child(historyEntry.id).set(historyEntry.toMap());
    } catch (e) {
      print('Error saving to history: $e');
    }
  }

  /// Get parameter status counts for dashboard
  Future<Map<String, int>> getParameterStatusCounts() async {
    if (_lastReading == null) {
      return {'optimal': 0, 'warning': 0, 'critical': 0};
    }

    int optimal = 0, warning = 0, critical = 0;

    // Count temperature
    final tempStatus = _getParameterStatus('temperature', _lastReading!.temperature);
    if (tempStatus == 'optimal') optimal++;
    else if (tempStatus == 'warning') warning++;
    else critical++;

    // Count pH
    final phStatus = _getParameterStatus('ph', _lastReading!.ph);
    if (phStatus == 'optimal') optimal++;
    else critical++;

    // Count ammonia
    final nh3Status = _getParameterStatus('nh3', _lastReading!.ammonia);
    if (nh3Status == 'safe') optimal++;
    else if (nh3Status == 'warning') warning++;
    else critical++;

    // Count turbidity
    final turbidityStatus = _getParameterStatus('turbidity', _lastReading!.turbidity);
    if (turbidityStatus == 'safe') optimal++;
    else if (turbidityStatus == 'warning') warning++;
    else critical++;

    return {'optimal': optimal, 'warning': warning, 'critical': critical};
  }

  /// Get history for a specific date range
  Future<List<HistoryEntry>> getHistoryRange(DateTime start, DateTime end) async {
    return _historyCache
        .where((entry) =>
            entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end))
        .toList();
  }

  /// Get alerts for a specific date
  Future<List<AlertEntry>> getAlertsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _alertCache
        .where((alert) =>
            alert.timestamp.isAfter(startOfDay) &&
            alert.timestamp.isBefore(endOfDay))
        .toList();
  }

  /// Get trend statistics for a parameter over a date range
  Future<Map<String, dynamic>> getTrendStats(
    String parameter,
    DateTime start,
    DateTime end,
  ) async {
    final rangeData = _historyCache
        .where((entry) =>
            entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end))
        .toList();

    if (rangeData.isEmpty) {
      return {
        'min': 0.0,
        'max': 0.0,
        'avg': 0.0,
        'trend': 0.0,
        'data': [],
      };
    }

    List<double> values = [];
    switch (parameter) {
      case 'temperature':
        values = rangeData.map((e) => e.temperature).toList();
        break;
      case 'ph':
        values = rangeData.map((e) => e.ph).toList();
        break;
      case 'nh3':
        values = rangeData.map((e) => e.ammonia).toList();
        break;
      case 'turbidity':
        values = rangeData.map((e) => e.turbidity).toList();
        break;
    }

    if (values.isEmpty) {
      return {
        'min': 0.0,
        'max': 0.0,
        'avg': 0.0,
        'trend': 0.0,
        'data': [],
      };
    }

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    
    // Calculate trend (percentage change from first to last)
    final trend = values.length > 1
        ? ((values.last - values.first) / values.first) * 100
        : 0.0;

    return {
      'min': min,
      'max': max,
      'avg': avg,
      'trend': trend,
      'data': values,
      'entries': rangeData,
    };
  }

  /// Mark alert as read
  Future<void> markAlertAsRead(String alertId) async {
    try {
      await _alertsRef.child(alertId).update({'isRead': true});
    } catch (e) {
      print('Error marking alert as read: $e');
    }
  }

  /// Delete alert
  Future<void> deleteAlert(String alertId) async {
    try {
      await _alertsRef.child(alertId).remove();
    } catch (e) {
      print('Error deleting alert: $e');
    }
  }

  /// Clear old alerts (older than specified days)
  Future<void> clearOldAlerts(int olderThanDays) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
      for (final alert in _alertCache) {
        if (alert.timestamp.isBefore(cutoffDate)) {
          await _alertsRef.child(alert.id).remove();
        }
      }
    } catch (e) {
      print('Error clearing old alerts: $e');
    }
  }

  /// Dispose and cleanup listeners
  void dispose() {
    _aqualityListener?.cancel();
    _alertListener?.cancel();
    _historyListener?.cancel();
    _currentReadingController.close();
    _alertsController.close();
    _historyController.close();
  }
}
