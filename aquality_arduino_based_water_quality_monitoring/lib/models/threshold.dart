/// Represents user-configured thresholds for a water quality parameter
class Threshold {
  final String parameterId;
  final String parameterName;
  final double minSafeValue;
  final double maxSafeValue;
  final double? warningMinValue;
  final double? warningMaxValue;
  final bool enableAlerts;
  final bool enableNotifications;
  final DateTime lastModified;

  Threshold({
    required this.parameterId,
    required this.parameterName,
    required this.minSafeValue,
    required this.maxSafeValue,
    this.warningMinValue,
    this.warningMaxValue,
    this.enableAlerts = true,
    this.enableNotifications = true,
    required this.lastModified,
  });

  /// Create from JSON (for storage)
  factory Threshold.fromJson(Map<String, dynamic> json) {
    return Threshold(
      parameterId: json['parameterId'] as String,
      parameterName: json['parameterName'] as String,
      minSafeValue: (json['minSafeValue'] as num).toDouble(),
      maxSafeValue: (json['maxSafeValue'] as num).toDouble(),
      warningMinValue: json['warningMinValue'] != null
          ? (json['warningMinValue'] as num).toDouble()
          : null,
      warningMaxValue: json['warningMaxValue'] != null
          ? (json['warningMaxValue'] as num).toDouble()
          : null,
      enableAlerts: json['enableAlerts'] as bool? ?? true,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      lastModified: DateTime.parse(json['lastModified'] as String),
    );
  }

  /// Convert to JSON (for storage)
  Map<String, dynamic> toJson() {
    return {
      'parameterId': parameterId,
      'parameterName': parameterName,
      'minSafeValue': minSafeValue,
      'maxSafeValue': maxSafeValue,
      'warningMinValue': warningMinValue,
      'warningMaxValue': warningMaxValue,
      'enableAlerts': enableAlerts,
      'enableNotifications': enableNotifications,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  /// Create a copy with modifications
  Threshold copyWith({
    String? parameterId,
    String? parameterName,
    double? minSafeValue,
    double? maxSafeValue,
    double? warningMinValue,
    double? warningMaxValue,
    bool? enableAlerts,
    bool? enableNotifications,
    DateTime? lastModified,
  }) {
    return Threshold(
      parameterId: parameterId ?? this.parameterId,
      parameterName: parameterName ?? this.parameterName,
      minSafeValue: minSafeValue ?? this.minSafeValue,
      maxSafeValue: maxSafeValue ?? this.maxSafeValue,
      warningMinValue: warningMinValue ?? this.warningMinValue,
      warningMaxValue: warningMaxValue ?? this.warningMaxValue,
      enableAlerts: enableAlerts ?? this.enableAlerts,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      lastModified: lastModified ?? DateTime.now(),
    );
  }
}
