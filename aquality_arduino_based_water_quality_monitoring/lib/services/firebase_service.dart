import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Holds the latest water quality readings from Firebase Realtime Database.
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
      ph:          parseValue(data['ph'], 0.0),
      ammonia:     parseValue(data['nh3'], 0.0),  // 🔥 Changed from 'ammonia' to 'nh3'
      turbidity:   parseValue(data['turbidity'], 0.0),
      timestamp: data['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['timestamp'] as num).toInt())
          : DateTime.now(),
    );
  }

  /// Parses a history entry with explicit timestamp key
  factory WaterQualityReading.fromHistoryEntry(String timestampKey, Map<dynamic, dynamic> data) {
    double parseValue(dynamic v, double fallback) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    return WaterQualityReading(
      temperature: parseValue(data['temperature'], 0.0),
      ph:          parseValue(data['ph'], 0.0),
      ammonia:     parseValue(data['nh3'], 0.0),
      turbidity:   parseValue(data['turbidity'], 0.0),
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

/// Service that streams live sensor data from Firebase Realtime Database.
///
/// Expected database structure (written by the Arduino / ESP32):
/// ```
/// /Aquality
///   temperature : 27.7
///   ph          : 7
///   nh3         : 0.1
///   turbidity   : 23
///   timestamp   : 1713000000000   ← epoch ms (optional)
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

  // ── Database reference ──────────────────────────────────────────────────
  static const String _dbUrl =
      'https://aquality-80539-default-rtdb.asia-southeast1.firebasedatabase.app';

  late final DatabaseReference _sensorsRef = FirebaseDatabase
      .instanceFor(app: FirebaseDatabase.instance.app, databaseURL: _dbUrl)
      .ref('Aquality');

  late final DatabaseReference _historyRef = FirebaseDatabase
      .instanceFor(app: FirebaseDatabase.instance.app, databaseURL: _dbUrl)
      .ref('Aquality_history');

  // ── Public stream ────────────────────────────────────────────────────────
  /// Broadcast stream of the latest sensor reading.
  /// Emits immediately on first listen, then on every database change.
  late final Stream<WaterQualityReading> sensorStream = _sensorsRef
      .onValue
      .map((event) {
        if (event.snapshot.value == null) {
          debugPrint('[FirebaseService] Aquality node is null – check DB path');
          return WaterQualityReading.placeholder;
        }
        try {
          return WaterQualityReading.fromSnapshot(event.snapshot);
        } catch (e, st) {
          debugPrint('[FirebaseService] parse error: $e\n$st');
          return WaterQualityReading.placeholder;
        }
      })
      .asBroadcastStream();

  // ── One-shot fetch ───────────────────────────────────────────────────────
  /// Fetches the latest reading once (useful for initial load).
  Future<WaterQualityReading> fetchOnce() async {
    try {
      final snapshot = await _sensorsRef.get();
      if (snapshot.value == null) return WaterQualityReading.placeholder;
      return WaterQualityReading.fromSnapshot(snapshot);
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
      
      debugPrint('[FirebaseService] Fetched ${readings.length} history readings');
      return readings;
    } catch (e) {
      debugPrint('[FirebaseService] fetchHistory error: $e');
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
    return Stream.periodic(Duration(minutes: intervalMinutes)).listen((_) async {
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
}