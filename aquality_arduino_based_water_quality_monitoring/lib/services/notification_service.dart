import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/analytics.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  final Map<String, DateTime> _lastNotified = {};
  static const Duration _cooldown = Duration(minutes: 5);
  // In-memory short buffers and EWMA state per parameter
  final Map<String, RollingBuffer> _buffers = {};
  final Map<String, double> _ewmaPrev = {};
  final Map<String, bool> _anomalous = {};



  Future<void> init() async {
    if (_initialized) return;
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification response
        },
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'aquality_threshold_channel',
              'Threshold Alerts',
              description: 'Water quality threshold breach notifications',
              importance: Importance.high,
            ),
          );

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

 

  
  Future<void> checkAndNotify({
    required String parameterId,
    required String parameterName,
    required double value,
    required String unit,
    required double minSafe,
    required double maxSafe,
    double? warningMin,
    double? warningMax,
    bool enableNotifications = true,
  }) async {
    if (!_initialized || !enableNotifications) return;

    // Append to rolling buffer
    final buf = _buffers.putIfAbsent(parameterId, () => RollingBuffer(30));
    buf.add(value);

    // Compute smoothed value (EWMA) and persist state
    final prev = _ewmaPrev[parameterId] ?? value;
    final smoothed = ewma(prev, value, 0.2);
    _ewmaPrev[parameterId] = smoothed;

    // Determine breach level using smoothed value, also run anomaly detectors
    String? level;
    final anomaly = isAnomalousMAD(buf.items, smoothed) || cusumDetect(buf.items, smoothed);
    _anomalous[parameterId] = anomaly;

    if (anomaly) {
      level = 'critical';
    } else if (smoothed < minSafe || smoothed > maxSafe) {
      final wMin = warningMin ?? minSafe - (maxSafe - minSafe) * 0.2;
      final wMax = warningMax ?? maxSafe + (maxSafe - minSafe) * 0.2;
      level = (smoothed < wMin || smoothed > wMax) ? 'critical' : 'warning';
    }

    if (level == null) return;

    // Cooldown check
    final last = _lastNotified[parameterId];
    if (last != null && DateTime.now().difference(last) < _cooldown) return;
    _lastNotified[parameterId] = DateTime.now();

    final title = level == 'critical'
        ? 'Critical Alert: $parameterName'
        : 'Warning: $parameterName';
    final display = smoothed;
    final body = unit.isEmpty
      ? '$parameterName reading of ${display.toStringAsFixed(2)} is $level.'
      : '$parameterName reading of ${display.toStringAsFixed(2)} $unit is $level.';

    await _showNotification(
      id: parameterId.hashCode,
      title: title,
      body: body,
    );
  }

  /// Public accessor for smoothed value if available
  double? getSmoothedValue(String parameterId) => _ewmaPrev[parameterId];

  /// Public accessor whether last computed sample was anomalous
  bool isAnomalous(String parameterId) => _anomalous[parameterId] ?? false;

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'aquality_threshold_channel',
      'Threshold Alerts',
      channelDescription: 'Water quality threshold breach notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _plugin.show(
        id,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('NotificationService show error: $e');
    }
  }
}
