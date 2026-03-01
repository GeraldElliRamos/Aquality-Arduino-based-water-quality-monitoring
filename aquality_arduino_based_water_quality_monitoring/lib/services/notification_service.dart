import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles local push notifications for water quality threshold breaches.
/// Includes a per-parameter cooldown to prevent notification spam.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Cooldown per parameter — avoids repeat notifications within 5 minutes.
  final Map<String, DateTime> _lastNotified = {};
  static const Duration _cooldown = Duration(minutes: 5);

  // ──────────────────────────────────────────────────────
  // Initialisation
  // ──────────────────────────────────────────────────────

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

      await _plugin.initialize(initSettings);

      // Create the Android notification channel once at startup.
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

  // ──────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────

  /// Compares [value] against the safe and warning thresholds.
  /// Fires a notification if a breach is detected and the cooldown has elapsed.
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

    // Determine breach level
    String? level;
    if (value < minSafe || value > maxSafe) {
      final wMin =
          warningMin ?? minSafe - (maxSafe - minSafe) * 0.2;
      final wMax =
          warningMax ?? maxSafe + (maxSafe - minSafe) * 0.2;
      level = (value < wMin || value > wMax) ? 'critical' : 'warning';
    }

    if (level == null) return;

    // Cooldown check
    final last = _lastNotified[parameterId];
    if (last != null && DateTime.now().difference(last) < _cooldown) return;
    _lastNotified[parameterId] = DateTime.now();

    final title = level == 'critical'
        ? 'Critical Alert: $parameterName'
        : 'Warning: $parameterName';
    final body = unit.isEmpty
        ? '$parameterName reading of ${value.toStringAsFixed(2)} is $level.'
        : '$parameterName reading of ${value.toStringAsFixed(2)} $unit is $level.';

    await _showNotification(
      id: parameterId.hashCode,
      title: title,
      body: body,
    );
  }

  // ──────────────────────────────────────────────────────
  // Internal helpers
  // ──────────────────────────────────────────────────────

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
      await _plugin.show(id, title, body, details);
    } catch (e) {
      debugPrint('NotificationService show error: $e');
    }
  }
}
