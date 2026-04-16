import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/alert.dart';

/// Holds the latest water quality readings from Firebase.
class WaterQualityReading {
  final double temperature;
  final double ph;
  final double ammonia;
  final double turbidity;
  final DateTime timestamp;

  const WaterQualityReading({
    required this.temperature,
    required this.ph,
    required this.ammonia,
    required this.turbidity,
    required this.timestamp,
  });

  /// Parses a snapshot from the Firebase node at /Aquality.
  /// Accepts both numeric and string representations coming from Arduino.
  factory WaterQualityReading.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    double parseValue(dynamic v, double fallback) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    return WaterQualityReading(
      temperature: parseValue(data['temperature'], 0.0),
      ph: parseValue(data['ph'], 0.0),
      ammonia: parseValue(
        data['nh3'],
        0.0,
      ), // 🔥 Changed from 'ammonia' to 'nh3'
      turbidity: parseValue(data['turbidity'], 0.0),
      timestamp: data['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['timestamp'] as num).toInt(),
            )
          : DateTime.now(),
    );
  }

  /// Parses the Firestore document that stores the current ESP32 reading.
  /// The document may store sensor values directly or under a `readings` map.
  factory WaterQualityReading.fromFirestoreDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      debugPrint('[WaterQualityReading] Firestore snapshot data is null');
      return WaterQualityReading.placeholder;
    }

    debugPrint('[WaterQualityReading] Raw Firestore data: $data');

    final readings = data['readings'];
    final readingData = readings is Map
        ? Map<String, dynamic>.from(readings)
        : data;

    debugPrint('[WaterQualityReading] Using readingData: $readingData');

    double parseValue(dynamic v, double fallback) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    final timestampValue =
        readingData['timestamp'] ??
        readingData['timestampMs'] ??
        data['timestamp'] ??
        data['timestampMs'];

    final timestamp = timestampValue is num
        ? DateTime.fromMillisecondsSinceEpoch(timestampValue.toInt())
      : timestampValue is Timestamp
      ? timestampValue.toDate()
        : timestampValue is String
        ? DateTime.tryParse(timestampValue) ?? DateTime.now()
        : DateTime.now();

    final temp = parseValue(
      readingData['temperature'] ?? readingData['temp'],
      0.0,
    );
    final phVal = parseValue(readingData['ph'], 0.0);
    final ammVal = parseValue(readingData['ammonia'] ?? readingData['nh3'], 0.0);
    final turbVal = parseValue(readingData['turbidity'], 0.0);

    debugPrint('[WaterQualityReading] Parsed values - temp: $temp, ph: $phVal, ammonia: $ammVal, turbidity: $turbVal, timestamp: $timestamp');

    return WaterQualityReading(
      temperature: temp,
      ph: phVal,
      ammonia: ammVal,
      turbidity: turbVal,
      timestamp: timestamp,
    );
  }

  /// Parses a history entry with explicit timestamp key
  factory WaterQualityReading.fromHistoryEntry(
    String timestampKey,
    Map<dynamic, dynamic> data,
  ) {
    double parseValue(dynamic v, double fallback) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    return WaterQualityReading(
      temperature: parseValue(data['temperature'], 0.0),
      ph: parseValue(data['ph'], 0.0),
      ammonia: parseValue(data['nh3'], 0.0),
      turbidity: parseValue(data['turbidity'], 0.0),
      timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(timestampKey)),
    );
  }

  /// Fallback reading used while waiting for the first Firebase event.
  static WaterQualityReading get placeholder => WaterQualityReading(
    temperature: 0,
    ph: 0,
    ammonia: 0,
    turbidity: 0,
    timestamp: DateTime.now(),
  );

  /// Converts to JSON for storing in history
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'ph': ph,
      'nh3': ammonia,
      'turbidity': turbidity,
    };
  }
}

/// Service that streams live sensor data from Firestore and keeps the
/// history/alert features on Realtime Database.
///
/// Expected database structure (written by the Arduino / ESP32):
/// ```
/// /sensor_readings/esp32_001
///   readings:
///     temperature : 27.7
///     ph          : 7
///     ammonia     : 0.1
///     turbidity   : 23
///     timestamp   : 1713000000000   ← epoch ms (optional)
///   device_id: esp32_001
///
/// /Aquality_history
///   1713000000000:
///     temperature : 27.7
///     ph          : 7
///     nh3         : 0.1
///     turbidity   : 23
///   1713003600000:
///     temperature : 27.8
///     ...
/// ```
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  static const String _sensorCollection = 'sensor_readings';
  static const String _sensorDocumentId = 'esp32_001';

  // ── Database reference ──────────────────────────────────────────────────
  static const String _dbUrl =
      'https://aquality-80539-default-rtdb.asia-southeast1.firebasedatabase.app';

  late final DocumentReference<Map<String, dynamic>> _sensorDocRef =
      FirebaseFirestore.instance
          .collection(_sensorCollection)
          .doc(_sensorDocumentId);

  late final DatabaseReference _historyRef = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: _dbUrl,
  ).ref('Aquality_history');

  late final DatabaseReference _alertsRef = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: _dbUrl,
  ).ref('Aquality_alerts');

  // ── Public stream ────────────────────────────────────────────────────────
  /// Broadcast stream of the latest sensor reading.
  /// Emits immediately on first listen, then on every database change.
  late final Stream<WaterQualityReading>
  sensorStream = _sensorDocRef.snapshots().map((event) {
    if (!event.exists || event.data() == null) {
      debugPrint(
        '[FirebaseService] Firestore doc is missing – check $_sensorCollection/$_sensorDocumentId',
      );
      return WaterQualityReading.placeholder;
    }
    try {
      return WaterQualityReading.fromFirestoreDocument(event);
    } catch (e, st) {
      debugPrint('[FirebaseService] parse error: $e\n$st');
      return WaterQualityReading.placeholder;
    }
  }).asBroadcastStream();

  // ── Diagnostics ────────────────────────────────────────────────────────
  /// Tests Firestore connectivity and returns diagnostic information.
  Future<Map<String, dynamic>> testConnection() async {
    final diagnostics = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'collection': _sensorCollection,
      'document': _sensorDocumentId,
    };

    try {
      debugPrint('[FirebaseService] Testing Firestore connection...');
      
      final snapshot = await _sensorDocRef.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Firestore request timeout'),
      );

      diagnostics['firestore_reachable'] = true;
      diagnostics['document_exists'] = snapshot.exists;
      diagnostics['has_data'] = snapshot.data() != null;

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        diagnostics['document_data'] = data;
        
        try {
          final reading = WaterQualityReading.fromFirestoreDocument(snapshot);
          diagnostics['parsed_successfully'] = true;
          diagnostics['values'] = {
            'temperature': reading.temperature,
            'ph': reading.ph,
            'ammonia': reading.ammonia,
            'turbidity': reading.turbidity,
            'timestamp': reading.timestamp.toIso8601String(),
          };
        } catch (e) {
          diagnostics['parsed_successfully'] = false;
          diagnostics['parse_error'] = e.toString();
        }
      } else {
        diagnostics['help'] = 
          'Document not found. Check Firestore at: '
          'Collection "$_sensorCollection", Document "$_sensorDocumentId"';
      }

      debugPrint('[FirebaseService] Diagnostics: $diagnostics');
      return diagnostics;
    } on TimeoutException catch (e) {
      diagnostics['firestore_reachable'] = false;
      diagnostics['error'] = 'Timeout: ${e.message}';
      diagnostics['help'] = 'Firestore not responding. Check internet connection.';
      debugPrint('[FirebaseService] Timeout: $e');
      return diagnostics;
    } catch (e) {
      diagnostics['firestore_reachable'] = false;
      diagnostics['error'] = e.toString();
      diagnostics['help'] = 
        'Connection failed. Verify Firebase config and Security Rules.';
      debugPrint('[FirebaseService] Connection error: $e');
      return diagnostics;
    }
  }

  // ── One-shot fetch ───────────────────────────────────────────────────────
  /// Fetches the latest reading once (useful for initial load).
  Future<WaterQualityReading> fetchOnce() async {
    try {
      debugPrint('[FirebaseService] Fetching latest reading...');
      final snapshot = await _sensorDocRef.get();
      if (!snapshot.exists || snapshot.data() == null) {
        debugPrint(
          '[FirebaseService] No data at $_sensorCollection/$_sensorDocumentId',
        );
        return WaterQualityReading.placeholder;
      }
      debugPrint('[FirebaseService] Got snapshot: ${snapshot.data()}');
      return WaterQualityReading.fromFirestoreDocument(snapshot);
    } catch (e) {
      debugPrint('[FirebaseService] fetchOnce error: $e');
      return WaterQualityReading.placeholder;
    }
  }

  // ── History methods ──────────────────────────────────────────────────────

  /// Fetches historical readings for a given time range.
  ///
  /// [hours] - Number of hours to look back (e.g., 24, 168 for 7 days, 720 for 30 days)
  /// Returns list of readings sorted by timestamp (oldest to newest)
  Future<List<WaterQualityReading>> fetchHistory({required int hours}) async {
    try {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final startTime = endTime - (hours * 60 * 60 * 1000);

      final snapshot = await _historyRef
          .orderByKey()
          .startAt(startTime.toString())
          .endAt(endTime.toString())
          .get();

      if (snapshot.value == null) {
        debugPrint('[FirebaseService] No history data found');
        return [];
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final readings = <WaterQualityReading>[];

      data.forEach((timestampKey, value) {
        try {
          if (value is Map) {
            final reading = WaterQualityReading.fromHistoryEntry(
              timestampKey,
              Map<dynamic, dynamic>.from(value),
            );
            readings.add(reading);
          }
        } catch (e) {
          debugPrint('[FirebaseService] Error parsing history entry: $e');
        }
      });

      // Sort by timestamp
      readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      debugPrint(
        '[FirebaseService] Fetched ${readings.length} history readings',
      );
      return readings;
    } catch (e) {
      debugPrint('[FirebaseService] fetchHistory error: $e');
      return [];
    }
  }

  /// Fetches historical readings between [start] and [end] timestamps.
  /// Returns readings sorted by timestamp (oldest to newest).
  Future<List<WaterQualityReading>> fetchHistoryRange({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final startMs = start.millisecondsSinceEpoch;
      final endMs = end.millisecondsSinceEpoch;

      final snapshot = await _historyRef
          .orderByKey()
          .startAt(startMs.toString())
          .endAt(endMs.toString())
          .get();

      if (snapshot.value == null) {
        debugPrint('[FirebaseService] No history data found in selected range');
        return [];
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final readings = <WaterQualityReading>[];

      data.forEach((timestampKey, value) {
        try {
          if (value is Map) {
            readings.add(
              WaterQualityReading.fromHistoryEntry(
                timestampKey,
                Map<dynamic, dynamic>.from(value),
              ),
            );
          }
        } catch (e) {
          debugPrint(
            '[FirebaseService] Error parsing ranged history entry: $e',
          );
        }
      });

      readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return readings;
    } catch (e) {
      debugPrint('[FirebaseService] fetchHistoryRange error: $e');
      return [];
    }
  }

  /// Saves the current reading to history.
  /// Call this periodically (e.g., every 5 minutes) from your Arduino or app.
  Future<void> saveToHistory(WaterQualityReading reading) async {
    try {
      final timestamp = reading.timestamp.millisecondsSinceEpoch;
      await _historyRef.child(timestamp.toString()).set(reading.toJson());
      debugPrint('[FirebaseService] Saved reading to history at $timestamp');
    } catch (e) {
      debugPrint('[FirebaseService] saveToHistory error: $e');
    }
  }

  /// Automatically saves current reading to history every [intervalMinutes].
  /// Returns a StreamSubscription that can be cancelled.
  StreamSubscription<void> startAutoSaveHistory({int intervalMinutes = 5}) {
    return Stream.periodic(Duration(minutes: intervalMinutes)).listen((
      _,
    ) async {
      try {
        final reading = await fetchOnce();
        if (reading.temperature != 0 || reading.ph != 0) {
          await saveToHistory(reading);
        }
      } catch (e) {
        debugPrint('[FirebaseService] Auto-save error: $e');
      }
    });
  }

  /// Streams alerts from Firebase, newest first.
  Stream<List<Alert>> get alertsStream => _alertsRef
      .orderByChild('timestampMs')
      .limitToLast(200)
      .onValue
      .map((event) {
        if (event.snapshot.value == null) return <Alert>[];

        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          final items = <Alert>[];

          data.forEach((key, raw) {
            if (raw is Map) {
              final json = Map<String, dynamic>.from(raw);
              json['id'] = json['id'] ?? key;
              items.add(Alert.fromJson(json));
            }
          });

          items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return items;
        } catch (e) {
          debugPrint('[FirebaseService] alertsStream parse error: $e');
          return <Alert>[];
        }
      });

  /// Saves an alert to Firebase Realtime Database.
  Future<void> saveAlert(Alert alert) async {
    try {
      final data = alert.toJson();
      data['timestampMs'] = alert.timestamp.millisecondsSinceEpoch;
      await _alertsRef.child(alert.id).set(data);
    } catch (e) {
      debugPrint('[FirebaseService] saveAlert error: $e');
    }
  }

  /// Deletes a specific alert from Firebase Realtime Database.
  Future<void> deleteAlert(String alertId) async {
    try {
      await _alertsRef.child(alertId).remove();
    } catch (e) {
      debugPrint('[FirebaseService] deleteAlert error: $e');
    }
  }
}
