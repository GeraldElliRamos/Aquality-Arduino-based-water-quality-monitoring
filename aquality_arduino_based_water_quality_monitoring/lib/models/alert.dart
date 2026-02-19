class Alert {
  final String id;
  final String title;
  final String subtitle;
  final AlertLevel level; 
  final String? parameterName;
  final double? reading;
  final String? unit;
  final DateTime timestamp;
  final bool isRead;
  final bool isDismissed;
  final String? action; 

  Alert({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.level,
    this.parameterName,
    this.reading,
    this.unit,
    required this.timestamp,
    this.isRead = false,
    this.isDismissed = false,
    this.action,
  });

  /// Get formatted time (e.g., "09:32 PM")
  String get formattedTime {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Get formatted date (e.g., "Feb 19")
  String get formattedDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[timestamp.month - 1]} ${timestamp.day}';
  }

  /// Check if alert is from today
  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  /// Check if alert is from yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return timestamp.year == yesterday.year &&
        timestamp.month == yesterday.month &&
        timestamp.day == yesterday.day;
  }

  /// Create from JSON
  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      level: AlertLevel.values.firstWhere(
        (e) => e.toString().split('.').last == (json['level'] as String).toLowerCase(),
        orElse: () => AlertLevel.info,
      ),
      parameterName: json['parameterName'] as String?,
      reading: json['reading'] != null ? (json['reading'] as num).toDouble() : null,
      unit: json['unit'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      isDismissed: json['isDismissed'] as bool? ?? false,
      action: json['action'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'level': level.toString().split('.').last,
      'parameterName': parameterName,
      'reading': reading,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'isDismissed': isDismissed,
      'action': action,
    };
  }

  /// Create a copy with modifications
  Alert copyWith({
    String? id,
    String? title,
    String? subtitle,
    AlertLevel? level,
    String? parameterName,
    double? reading,
    String? unit,
    DateTime? timestamp,
    bool? isRead,
    bool? isDismissed,
    String? action,
  }) {
    return Alert(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      level: level ?? this.level,
      parameterName: parameterName ?? this.parameterName,
      reading: reading ?? this.reading,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
      action: action ?? this.action,
    );
  }
}

enum AlertLevel {
  critical,
  warning,
  info,
}
