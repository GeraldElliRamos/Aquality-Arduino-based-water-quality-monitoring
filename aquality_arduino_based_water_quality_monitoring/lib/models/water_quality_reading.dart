/// Represents a real-time water quality reading from Firebase
class WaterQualityReading {
  final double temperature;
  final double ph;
  final double ammonia;
  final double turbidity;
  final DateTime timestamp;

  WaterQualityReading({
    required this.temperature,
    required this.ph,
    required this.ammonia,
    required this.turbidity,
    required this.timestamp,
  });

  /// Create from Firebase snapshot
  factory WaterQualityReading.fromMap(Map<dynamic, dynamic> map) {
    return WaterQualityReading(
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      ph: (map['ph'] as num?)?.toDouble() ?? 0.0,
      ammonia: (map['nh3'] as num?)?.toDouble() ?? 0.0, // Firebase uses 'nh3'
      turbidity: (map['turbidity'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.now(),
    );
  }

  /// Convert to map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'ph': ph,
      'nh3': ammonia,
      'turbidity': turbidity,
    };
  }

  /// Create a copy with modified fields
  WaterQualityReading copyWith({
    double? temperature,
    double? ph,
    double? ammonia,
    double? turbidity,
    DateTime? timestamp,
  }) {
    return WaterQualityReading(
      temperature: temperature ?? this.temperature,
      ph: ph ?? this.ph,
      ammonia: ammonia ?? this.ammonia,
      turbidity: turbidity ?? this.turbidity,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
