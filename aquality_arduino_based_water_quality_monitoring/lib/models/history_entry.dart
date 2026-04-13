/// Represents a historical water quality snapshot from AqualityHistory node
class HistoryEntry {
  final String id;
  final double temperature;
  final double ph;
  final double ammonia;
  final double turbidity;
  final DateTime timestamp;

  HistoryEntry({
    required this.id,
    required this.temperature,
    required this.ph,
    required this.ammonia,
    required this.turbidity,
    required this.timestamp,
  });

  /// Create from Firebase snapshot
  factory HistoryEntry.fromMap(String key, Map<dynamic, dynamic> map) {
    return HistoryEntry(
      id: key,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      ph: (map['ph'] as num?)?.toDouble() ?? 0.0,
      ammonia: (map['nh3'] as num?)?.toDouble() ?? 0.0,
      turbidity: (map['turbidity'] as num?)?.toDouble() ?? 0.0,
      timestamp: _parseTimestamp(map['timestamp']),
    );
  }

  /// Convert to map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'ph': ph,
      'nh3': ammonia,
      'turbidity': turbidity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Parse timestamp from various formats
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (_) {
        return DateTime.now();
      }
    }
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.now();
  }

  /// Get formatted time string
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Get formatted date string
  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  /// Create a copy with modified fields
  HistoryEntry copyWith({
    String? id,
    double? temperature,
    double? ph,
    double? ammonia,
    double? turbidity,
    DateTime? timestamp,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      temperature: temperature ?? this.temperature,
      ph: ph ?? this.ph,
      ammonia: ammonia ?? this.ammonia,
      turbidity: turbidity ?? this.turbidity,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
