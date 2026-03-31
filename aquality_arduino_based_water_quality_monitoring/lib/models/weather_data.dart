/// Represents weather data and safe parameters for water quality monitoring
class WeatherData {
  final double temperature; // Celsius
  final double humidity; // Percentage
  final double windSpeed; // km/h
  final String weatherCondition; // Clear, Cloudy, Rainy, etc.
  final double uvIndex;
  final DateTime lastUpdated;
  final String sensorId; // ESP32 sensor identifier
  final String locationName; // City, Country
  final double latitude; // Device latitude
  final double longitude; // Device longitude

  // Safe parameter ranges for turbidity and temperature
  final double safeTemperatureMin; // Optimal minimum temperature
  final double safeTemperatureMax; // Optimal maximum temperature
  final double safeTurbidityMin; // Optimal minimum turbidity (NTU)
  final double safeTurbidityMax; // Optimal maximum turbidity (NTU)

  // Current readings from sensors
  final double currentTemperature; // Current water temperature
  final double currentTurbidity; // Current turbidity reading

  bool get hasSensorReadings =>
      currentTemperature.isFinite && currentTurbidity.isFinite;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCondition,
    required this.uvIndex,
    required this.lastUpdated,
    required this.sensorId,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.safeTemperatureMin = 25.0,
    this.safeTemperatureMax = 32.0,
    this.safeTurbidityMin = 5.0,
    this.safeTurbidityMax = 60.0,
    required this.currentTemperature,
    required this.currentTurbidity,
  });

  /// Check if temperature is within safe range
  bool get isTemperatureSafe =>
      hasSensorReadings &&
      currentTemperature >= safeTemperatureMin &&
      currentTemperature <= safeTemperatureMax;

  /// Check if turbidity is within safe range
  bool get isTurbiditySafe =>
      hasSensorReadings &&
      currentTurbidity >= safeTurbidityMin &&
      currentTurbidity <= safeTurbidityMax;

  /// Get temperature status (optimal, warning, critical)
  String get temperatureStatus {
    if (!hasSensorReadings) return 'not_connected';
    if (isTemperatureSafe) return 'optimal';
    if (currentTemperature < safeTemperatureMin - 2 ||
        currentTemperature > safeTemperatureMax + 2) {
      return 'critical';
    }
    return 'warning';
  }

  /// Get turbidity status (optimal, warning, critical)
  String get turbidityStatus {
    if (!hasSensorReadings) return 'not_connected';
    if (isTurbiditySafe) return 'optimal';
    if (currentTurbidity < safeTurbidityMin - 10 ||
        currentTurbidity > safeTurbidityMax + 20) {
      return 'critical';
    }
    return 'warning';
  }

  /// Get weather icon based on condition
  String get weatherIcon {
    switch (weatherCondition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return '☀️';
      case 'cloudy':
      case 'overcast':
        return '☁️';
      case 'rainy':
      case 'rain':
        return '🌧️';
      case 'stormy':
      case 'thunderstorm':
        return '⛈️';
      case 'foggy':
      case 'fog':
        return '🌫️';
      case 'snowy':
      case 'snow':
        return '❄️';
      default:
        return '🌤️';
    }
  }

  /// Get temperature deviation percentage from safe range
  double get temperatureDeviationPercentage {
    if (isTemperatureSafe) return 0;
    if (currentTemperature < safeTemperatureMin) {
      return ((safeTemperatureMin - currentTemperature) /
              (safeTemperatureMax - safeTemperatureMin)) *
          100;
    } else {
      return ((currentTemperature - safeTemperatureMax) /
              (safeTemperatureMax - safeTemperatureMin)) *
          100;
    }
  }

  /// Get turbidity deviation percentage from safe range
  double get turbidityDeviationPercentage {
    if (isTurbiditySafe) return 0;
    if (currentTurbidity < safeTurbidityMin) {
      return ((safeTurbidityMin - currentTurbidity) /
              (safeTurbidityMax - safeTurbidityMin)) *
          100;
    } else {
      return ((currentTurbidity - safeTurbidityMax) /
              (safeTurbidityMax - safeTurbidityMin)) *
          100;
    }
  }

  /// Generate recommendation based on weather and parameters
  String getRecommendation() {
    List<String> recommendations = [];

    if (!hasSensorReadings) {
      recommendations.add(
        'ESP32 turbidity/temperature sensor is not connected. Live sensor values are unavailable.',
      );
    }

    if (hasSensorReadings && !isTemperatureSafe) {
      if (currentTemperature < safeTemperatureMin) {
        recommendations.add(
          'Water temperature is too low. Consider increasing aeration or heating.',
        );
      } else {
        recommendations.add(
          'Water temperature is too high. Increase water circulation.',
        );
      }
    }

    if (hasSensorReadings && !isTurbiditySafe) {
      if (currentTurbidity < safeTurbidityMin) {
        recommendations.add(
          'Water is too clear. Check filtration system to maintain slight turbidity.',
        );
      } else {
        recommendations.add(
          'Water turbidity is high. Implement enhanced filtration and water treatment.',
        );
      }
    }

    if (hasSensorReadings &&
        weatherCondition.toLowerCase().contains('rain') &&
        currentTurbidity > safeTurbidityMax) {
      recommendations.add(
        'Heavy rain detected. Monitor turbidity levels closely for runoff effects.',
      );
    }

    if (temperature > 35) {
      recommendations.add(
        'High ambient temperature detected. Add shade or increase water cooling.',
      );
    }

    if (windSpeed > 30) {
      recommendations.add(
        'Strong winds recorded. Monitor pond for debris and wave action impact.',
      );
    }

    return recommendations.isEmpty
        ? 'All conditions are optimal for aquaculture.'
        : recommendations.join('\n• ');
  }

  /// Create a copy with updated values
  WeatherData copyWith({
    double? temperature,
    double? humidity,
    double? windSpeed,
    String? weatherCondition,
    double? uvIndex,
    DateTime? lastUpdated,
    String? sensorId,
    String? locationName,
    double? latitude,
    double? longitude,
    double? safeTemperatureMin,
    double? safeTemperatureMax,
    double? safeTurbidityMin,
    double? safeTurbidityMax,
    double? currentTemperature,
    double? currentTurbidity,
  }) {
    return WeatherData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      uvIndex: uvIndex ?? this.uvIndex,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      sensorId: sensorId ?? this.sensorId,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      safeTemperatureMin: safeTemperatureMin ?? this.safeTemperatureMin,
      safeTemperatureMax: safeTemperatureMax ?? this.safeTemperatureMax,
      safeTurbidityMin: safeTurbidityMin ?? this.safeTurbidityMin,
      safeTurbidityMax: safeTurbidityMax ?? this.safeTurbidityMax,
      currentTemperature: currentTemperature ?? this.currentTemperature,
      currentTurbidity: currentTurbidity ?? this.currentTurbidity,
    );
  }
}
