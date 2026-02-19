/// Represents a water quality parameter with its current state and thresholds
class WaterQualityParameter {
  final String id;
  final String name;
  final String unit;
  final double currentValue;
  final double minSafe;
  final double maxSafe;
  final String status; // 'optimal', 'warning', 'critical'
  final DateTime lastUpdated;
  final IconType icon;
  final ParameterColor color;

  WaterQualityParameter({
    required this.id,
    required this.name,
    required this.unit,
    required this.currentValue,
    required this.minSafe,
    required this.maxSafe,
    required this.status,
    required this.lastUpdated,
    required this.icon,
    required this.color,
  });

  /// Calculate percentage within safe range (0-100)
  double get safetyPercentage {
    final range = maxSafe - minSafe;
    if (range <= 0) return 0;
    
    if (currentValue < minSafe) {
      return ((currentValue - (minSafe - range * 0.2)) / (range * 1.4)) * 100;
    } else if (currentValue > maxSafe) {
      return ((currentValue - minSafe) / (range * 1.4)) * 100;
    } else {
      return ((currentValue - minSafe) / range) * 100;
    }
  }

  /// Check if parameter is within safe range
  bool get isOptimal => currentValue >= minSafe && currentValue <= maxSafe;

  /// Distance from optimal range (negative = below, positive = above, 0 = in range)
  double get deviationFromOptimal {
    if (isOptimal) return 0;
    if (currentValue < minSafe) return currentValue - minSafe;
    return currentValue - maxSafe;
  }
}

enum IconType {
  temperature,
  ph,
  chlorine,
  dissolvedOxygen,
  ammonia,
  turbidity,
  conductivity,
  generic,
}

enum ParameterColor {
  orange,
  purple,
  amber,
  blue,
  red,
  teal,
  indigo,
  green,
}
