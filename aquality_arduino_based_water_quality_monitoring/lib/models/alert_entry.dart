/// Represents an alert triggered by parameter threshold breach
class AlertEntry {
  final String id;
  final String type; // 'Critical', 'Warning', 'Info'
  final String parameter; // 'temperature', 'ph', 'nh3', 'turbidity'
  final double value;
  final DateTime timestamp;
  final String? description;
  final bool isRead;

  AlertEntry({
    required this.id,
    required this.type,
    required this.parameter,
    required this.value,
    required this.timestamp,
    this.description,
    this.isRead = false,
  });

  /// Create from Firebase snapshot
  factory AlertEntry.fromMap(String key, Map<dynamic, dynamic> map) {
    return AlertEntry(
      id: key,
      type: map['type'] as String? ?? 'Info',
      parameter: map['parameter'] as String? ?? 'unknown',
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      timestamp: _parseTimestamp(map['timestamp']),
      description: map['description'] as String?,
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  /// Convert to map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'parameter': parameter,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'isRead': isRead,
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

  /// Get human-readable parameter name
  String get parameterDisplay {
    switch (parameter) {
      case 'temperature':
        return 'Temperature';
      case 'ph':
        return 'pH Level';
      case 'nh3':
        return 'Ammonia';
      case 'turbidity':
        return 'Turbidity';
      default:
        return parameter;
    }
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
  AlertEntry copyWith({
    String? id,
    String? type,
    String? parameter,
    double? value,
    DateTime? timestamp,
    String? description,
    bool? isRead,
  }) {
    return AlertEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      parameter: parameter ?? this.parameter,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      isRead: isRead ?? this.isRead,
    );
  }
}
