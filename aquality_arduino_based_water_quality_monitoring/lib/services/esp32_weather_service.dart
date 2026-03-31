import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/weather_data.dart';
import 'location_service.dart';

/// Service to communicate with ESP32 weather sensor
/// Handles data fetching, parsing, and caching with real weather API
class ESP32WeatherService {
  static final ESP32WeatherService _instance = ESP32WeatherService._internal();

  factory ESP32WeatherService() {
    return _instance;
  }

  ESP32WeatherService._internal();

  // Configuration
  static const String defaultSensorId = 'ESP32-WEATHER-001';
  static const String esp32Endpoint = 'http://192.168.1.100/api/weather';

  // OpenWeatherMap API Configuration
  // Get your free API key at: https://openweathermap.org/api
  late String openWeatherApiKey;
  static const String openWeatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';

  final ValueNotifier<WeatherData?> weatherDataNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  final LocationService _locationService = LocationService();
  double? _lastLatitude;
  double? _lastLongitude;

  /// Initialize the service with API key from environment
  Future<void> init({String? apiKey}) async {
    openWeatherApiKey = (apiKey ?? '').trim();
    await fetchWeatherData();
  }

  /// Fetch real weather data from OpenWeatherMap using device location
  Future<WeatherData?> fetchWeatherData() async {
    isLoadingNotifier.value = true;
    errorNotifier.value = null;

    try {
      // Get user's current location
      final position = await _locationService.getCurrentLocation();

      if (position == null) {
        errorNotifier.value =
            'Unable to get location. Please enable location services.';
        debugPrint('Location not available');
        return _getMockWeatherData();
      }

      _lastLatitude = position.latitude;
      _lastLongitude = position.longitude;

      debugPrint('Fetching weather for: $_lastLatitude, $_lastLongitude');

      // Fetch real weather data from OpenWeatherMap
      if (openWeatherApiKey.isNotEmpty) {
        final weatherData = await _fetchOpenWeatherData(
          position.latitude,
          position.longitude,
        );

        if (weatherData != null) {
          weatherDataNotifier.value = weatherData;
          errorNotifier.value = null;
          return weatherData;
        }
      }

      // Fallback to mock data
      debugPrint('Using mock weather data (no API key or request failed)');
      final mockData = _getMockWeatherData();
      weatherDataNotifier.value = mockData;
      errorNotifier.value =
          'Using demo data. Add OpenWeatherMap API key to .env for real data.';
      return mockData;
    } catch (e) {
      errorNotifier.value = 'Failed to fetch weather data: $e';
      debugPrint('Weather fetch error: $e');
      return _getMockWeatherData();
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Fetch weather from OpenWeatherMap API
  Future<WeatherData?> _fetchOpenWeatherData(double lat, double lon) async {
    try {
      final url = Uri.parse(
        '$openWeatherBaseUrl/weather?lat=$lat&lon=$lon&units=metric&appid=$openWeatherApiKey',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return _parseOpenWeatherData(json, lat, lon);
      } else if (response.statusCode == 401) {
        final apiMessage = _extractApiMessage(response.body);
        errorNotifier.value = 'OpenWeather API key unauthorized: $apiMessage';
        debugPrint('OpenWeather API error 401: $apiMessage');
        return null;
      } else {
        final apiMessage = _extractApiMessage(response.body);
        errorNotifier.value =
            'Weather API request failed (${response.statusCode}): $apiMessage';
        debugPrint('OpenWeather API error ${response.statusCode}: $apiMessage');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching OpenWeather data: $e');
      return null;
    }
  }

  /// Parse OpenWeatherMap JSON response
  WeatherData _parseOpenWeatherData(
    Map<String, dynamic> json,
    double lat,
    double lon,
  ) {
    try {
      final main = json['main'] as Map<String, dynamic>;
      final weather = (json['weather'] as List).first as Map<String, dynamic>;
      final wind = json['wind'] as Map<String, dynamic>;

      final temp = (main['temp'] as num).toDouble();
      final humidity = (main['humidity'] as num).toDouble();
      final windSpeed = (wind['speed'] as num).toDouble() * 3.6; // m/s to km/h
      final condition = weather['main'] as String;
      final uvIndex = _estimateUVIndex(json['clouds']['all'] as int);
      final city = (json['name'] as String?)?.trim();
      final country =
          (json['sys'] as Map<String, dynamic>?)?['country'] as String?;
      final apiLocationName = [
        city,
        country,
      ].where((part) => part != null && part.trim().isNotEmpty).join(', ');

      // ESP32 sensor not connected yet: keep water readings unavailable.
      final currentTemp = double.nan;
      final turbidity = double.nan;

      return WeatherData(
        temperature: temp,
        humidity: humidity,
        windSpeed: windSpeed,
        weatherCondition: condition,
        uvIndex: uvIndex,
        lastUpdated: DateTime.now(),
        sensorId: defaultSensorId,
        locationName: apiLocationName.isEmpty
            ? 'Location Unknown'
            : apiLocationName,
        latitude: lat,
        longitude: lon,
        safeTemperatureMin: 25.0,
        safeTemperatureMax: 32.0,
        safeTurbidityMin: 5.0,
        safeTurbidityMax: 60.0,
        currentTemperature: currentTemp,
        currentTurbidity: turbidity,
      );
    } catch (e) {
      debugPrint('Error parsing OpenWeather data: $e');
      return _getMockWeatherData();
    }
  }

  /// Estimate UV Index based on cloud coverage
  double _estimateUVIndex(int cloudPercentage) {
    final baseUV = 8.0;
    final reduction = (cloudPercentage / 100) * 5;
    return (baseUV - reduction).clamp(0, 11).toDouble();
  }

  String _extractApiMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          return message;
        }
      }
    } catch (_) {}
    return 'No detailed message returned by API.';
  }

  /// Get current weather data
  WeatherData? getCurrentWeather() {
    return weatherDataNotifier.value;
  }

  /// Update safe parameter ranges
  void updateSafeParameters({
    required double safeTemperatureMin,
    required double safeTemperatureMax,
    required double safeTurbidityMin,
    required double safeTurbidityMax,
  }) {
    if (weatherDataNotifier.value != null) {
      final updated = weatherDataNotifier.value!.copyWith(
        safeTemperatureMin: safeTemperatureMin,
        safeTemperatureMax: safeTemperatureMax,
        safeTurbidityMin: safeTurbidityMin,
        safeTurbidityMax: safeTurbidityMax,
      );
      weatherDataNotifier.value = updated;
    }
  }

  /// Generate 7-day weather forecast
  List<WeatherForecast> getForecast() {
    return _getMockForecast();
  }

  /// Mock weather data - fallback
  WeatherData _getMockWeatherData() {
    return WeatherData(
      temperature: 28.5,
      humidity: 75.0,
      windSpeed: 12.5,
      weatherCondition: 'Partly Cloudy',
      uvIndex: 6.5,
      locationName: 'Demo Location',
      latitude: 14.5995,
      longitude: 120.9842,
      lastUpdated: DateTime.now(),
      sensorId: defaultSensorId,
      safeTemperatureMin: 25.0,
      safeTemperatureMax: 32.0,
      safeTurbidityMin: 5.0,
      safeTurbidityMax: 60.0,
      currentTemperature: double.nan,
      currentTurbidity: double.nan,
    );
  }

  /// Mock forecast data
  List<WeatherForecast> _getMockForecast() {
    final now = DateTime.now();
    return [
      WeatherForecast(
        date: now,
        maxTemp: 32.0,
        minTemp: 24.0,
        condition: 'Sunny',
        precipitationChance: 10,
        humidity: 70,
      ),
      WeatherForecast(
        date: now.add(const Duration(days: 1)),
        maxTemp: 31.5,
        minTemp: 23.5,
        condition: 'Partly Cloudy',
        precipitationChance: 20,
        humidity: 75,
      ),
      WeatherForecast(
        date: now.add(const Duration(days: 2)),
        maxTemp: 30.0,
        minTemp: 22.0,
        condition: 'Rainy',
        precipitationChance: 80,
        humidity: 85,
      ),
      WeatherForecast(
        date: now.add(const Duration(days: 3)),
        maxTemp: 29.5,
        minTemp: 21.5,
        condition: 'Thunderstorm',
        precipitationChance: 95,
        humidity: 90,
      ),
      WeatherForecast(
        date: now.add(const Duration(days: 4)),
        maxTemp: 31.0,
        minTemp: 23.0,
        condition: 'Cloudy',
        precipitationChance: 30,
        humidity: 72,
      ),
      WeatherForecast(
        date: now.add(const Duration(days: 5)),
        maxTemp: 33.0,
        minTemp: 25.0,
        condition: 'Sunny',
        precipitationChance: 5,
        humidity: 65,
      ),
      WeatherForecast(
        date: now.add(const Duration(days: 6)),
        maxTemp: 32.5,
        minTemp: 24.5,
        condition: 'Sunny',
        precipitationChance: 10,
        humidity: 68,
      ),
    ];
  }

  /// Dispose resources
  void dispose() {
    weatherDataNotifier.dispose();
    isLoadingNotifier.dispose();
    errorNotifier.dispose();
  }
}

/// Weather forecast data model
class WeatherForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final String condition;
  final int precipitationChance;
  final int humidity;

  WeatherForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.condition,
    required this.precipitationChance,
    required this.humidity,
  });

  String get weatherIcon {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return '☀️';
      case 'cloudy':
      case 'overcast':
      case 'partly cloudy':
        return '☁️';
      case 'rainy':
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'stormy':
      case 'thunderstorm':
        return '⛈️';
      case 'foggy':
      case 'fog':
      case 'mist':
        return '🌫️';
      case 'snowy':
      case 'snow':
        return '❄️';
      default:
        return '🌤️';
    }
  }

  String get dayLabel {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}
