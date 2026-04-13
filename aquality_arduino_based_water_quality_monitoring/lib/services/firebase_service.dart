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

  /// Fallback reading used while waiting for the first Firebase event.
  static WaterQualityReading get placeholder => WaterQualityReading(
        temperature: 0,
        ph: 0,
        ammonia: 0,
        turbidity: 0,
        timestamp: DateTime.now(),
      );
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
/// ```
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  // ── Database reference ──────────────────────────────────────────────────
  static const String _dbUrl =
      'https://aquality-80539-default-rtdb.asia-southeast1.firebasedatabase.app';

  late final DatabaseReference _sensorsRef = FirebaseDatabase
      .instanceFor(app: FirebaseDatabase.instance.app, databaseURL: _dbUrl)
      .ref('Aquality');  // 🔥 Changed from 'sensors/latest' to 'Aquality'

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
}