import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/weather_data.dart';
import 'location_service.dart';
import 'connectivity_service.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Composite state class for weather data to reduce rebuild cycles
/// Combines weatherData, loading status, and error into single notifier
class WeatherState {
  final WeatherData? data;
  final bool isLoading;
  final String? error;

  WeatherState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  WeatherState copyWith({
    WeatherData? data,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearData = false,
  }) {
    return WeatherState(
      data: data ?? (clearData ? null : this.data),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

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

  /// Composite notifier: combines data, loading, and error into single rebuild cycle
  final ValueNotifier<WeatherState> stateNotifier = ValueNotifier(
    WeatherState(),
  );

  /// Legacy accessors for backward compatibility
  ValueNotifier<WeatherData?> get weatherDataNotifier {
    final notifier = ValueNotifier<WeatherData?>(stateNotifier.value.data);
    stateNotifier.addListener(() {
      notifier.value = stateNotifier.value.data;
    });
    return notifier;
  }

  ValueNotifier<bool> get isLoadingNotifier {
    final notifier = ValueNotifier<bool>(stateNotifier.value.isLoading);
    stateNotifier.addListener(() {
      notifier.value = stateNotifier.value.isLoading;
    });
    return notifier;
  }

  ValueNotifier<String?> get errorNotifier {
    final notifier = ValueNotifier<String?>(stateNotifier.value.error);
    stateNotifier.addListener(() {
      notifier.value = stateNotifier.value.error;
    });
    return notifier;
  }

  final LocationService _locationService = LocationService();
  final ConnectivityService _connectivityService = ConnectivityService();
  double? _lastLatitude;
  double? _lastLongitude;
  StreamSubscription<Position>? _positionSubscription;
  DateTime? _lastFetchTime;
  Timer? _periodicRefreshTimer;
  
  /// Cache for API responses (5-minute TTL)
  WeatherData? _cachedWeatherData;
  DateTime? _cacheTimestamp;
  static const Duration _cacheTTL = Duration(minutes: 5);
  
  /// Cache for forecast data
  List<WeatherForecast>? _cachedForecast;
  DateTime? _forecastCacheTimestamp;
  static const Duration _forecastCacheTTL = Duration(hours: 1);
  
  /// Minimum movement (meters) required to trigger a weather fetch
  final double _movementThresholdMeters = 50.0;
  /// Minimum interval between API fetches to avoid spamming (seconds)
  final int _minFetchIntervalSeconds = 30;
  /// Periodic refresh interval (minutes) - refreshes weather every X minutes
  static const int _periodicRefreshIntervalMinutes = 30;

  /// Initialize the service with API key from environment
  Future<void> init({String? apiKey}) async {
    openWeatherApiKey = (apiKey ?? '').trim();
    // Subscribe to location updates for real-time weather refreshes.
    try {
      _positionSubscription?.cancel();
      _positionSubscription = _locationService
          .getPositionStream(distanceFilter: _movementThresholdMeters.toInt())
          .listen((position) async {
        debugPrint('Location stream update: ${position.latitude},${position.longitude}');

        final shouldFetch = _shouldFetchForPosition(position);
        if (!shouldFetch) {
          debugPrint('Skipping weather fetch — movement/interval below threshold');
          return;
        }

        _lastLatitude = position.latitude;
        _lastLongitude = position.longitude;
        _lastFetchTime = DateTime.now();

        if (openWeatherApiKey.isNotEmpty) {
          final weatherData = await _fetchOpenWeatherData(
            position.latitude,
            position.longitude,
          );
          if (weatherData != null) {
            stateNotifier.value = stateNotifier.value.copyWith(
              data: weatherData,
              clearError: true,
            );
          }
        }
      }, onError: (e) {
        debugPrint('Location stream error: $e');
      });
    } catch (e) {
      debugPrint('Failed to subscribe to location stream: $e');
    }

    // Initial fetch (single-shot) to populate UI immediately.
    await fetchWeatherData();
    
    // Start periodic refresh timer (every 30 minutes)
    _startPeriodicRefresh();
  }

  /// Start periodic weather refresh timer
  void _startPeriodicRefresh() {
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = Timer.periodic(
      const Duration(minutes: _periodicRefreshIntervalMinutes),
      (_) {
        debugPrint('🔄 Periodic weather refresh triggered (every $_periodicRefreshIntervalMinutes min)');
        fetchWeatherData();
      },
    );
  }

  /// Stop periodic refresh timer
  void _stopPeriodicRefresh() {
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = null;
  }

  /// Fetch real weather data from OpenWeatherMap using device location
  Future<WeatherData?> fetchWeatherData() async {
    stateNotifier.value = stateNotifier.value.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      // Get user's current location
      final position = await _locationService.getCurrentLocation();

      if (position == null) {
        // Detailed diagnostics
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        final permission = await Geolocator.checkPermission();
        
        String diagnostics = 'Location fetch failed:\n';
        diagnostics += '- Services enabled: $serviceEnabled\n';
        diagnostics += '- Permission status: $permission\n';
        diagnostics += '- API key set: ${openWeatherApiKey.isNotEmpty}';
        
        stateNotifier.value = stateNotifier.value.copyWith(
          error: 'Unable to get location.\n\n$diagnostics\n\nPlease enable location services and grant permission.',
        );
        debugPrint('=== LOCATION DEBUG ===\n$diagnostics');
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
          stateNotifier.value = stateNotifier.value.copyWith(
            data: weatherData,
            isLoading: false,
            clearError: true,
          );
          return weatherData;
        }
      }

      // Fallback to mock data
      debugPrint('Using mock weather data (no API key or request failed)');
      final mockData = _getMockWeatherData();
      stateNotifier.value = stateNotifier.value.copyWith(
        data: mockData,
        isLoading: false,
        error: 'Using demo data. Add OpenWeatherMap API key to .env for real data.',
      );
      return mockData;
    } catch (e) {
      stateNotifier.value = stateNotifier.value.copyWith(
        error: 'Failed to fetch weather data: $e',
        isLoading: false,
      );
      debugPrint('Weather fetch error: $e');
      return _getMockWeatherData();
    }
  }

  /// Fetch weather from OpenWeatherMap API with caching
  Future<WeatherData?> _fetchOpenWeatherData(double lat, double lon) async {
    // Check cache first - if fresh, return cached data
    if (_isCacheValid()) {
      debugPrint('✓ Using cached weather data (${_getCacheAge().inSeconds}s old)');
      return _cachedWeatherData;
    }

    // Check connectivity - if offline, use cache or mock
    if (!_connectivityService.isOnline) {
      debugPrint('✗ Offline: Cannot fetch weather. Using cached data if available.');
      if (_cachedWeatherData != null) {
        stateNotifier.value = stateNotifier.value.copyWith(
          error: 'Using cached weather data (offline mode)',
        );
        return _cachedWeatherData;
      }
      stateNotifier.value = stateNotifier.value.copyWith(
        error: 'No internet connection. Unable to fetch weather.',
      );
      return _getMockWeatherData();
    }

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
        final weatherData = _parseOpenWeatherData(json, lat, lon);
        
        // Cache the response
        _cachedWeatherData = weatherData;
        _cacheTimestamp = DateTime.now();
        debugPrint('✓ Cached weather data (TTL: 5 min)');
        
        return weatherData;
      } else if (response.statusCode == 401) {
        final apiMessage = _extractApiMessage(response.body);
        stateNotifier.value = stateNotifier.value.copyWith(
          error: 'OpenWeather API key unauthorized: $apiMessage',
        );
        debugPrint('OpenWeather API error 401: $apiMessage');
        return null;
      } else {
        final apiMessage = _extractApiMessage(response.body);
        stateNotifier.value = stateNotifier.value.copyWith(
          error: 'Weather API request failed (${response.statusCode}): $apiMessage',
        );
        debugPrint('OpenWeather API error ${response.statusCode}: $apiMessage');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching OpenWeather data: $e');
      return null;
    }
  }

  bool _shouldFetchForPosition(Position position) {
    // If we have no previous fetch, allow it.
    if (_lastLatitude == null || _lastLongitude == null || _lastFetchTime == null) {
      return true;
    }

    // Time debounce: don't fetch if last fetch was recent.
    final elapsed = DateTime.now().difference(_lastFetchTime!).inSeconds;
    if (elapsed < _minFetchIntervalSeconds) {
      return false;
    }

    // Distance check
    final distance = _locationService.getDistance(
      startLatitude: _lastLatitude!,
      startLongitude: _lastLongitude!,
      endLatitude: position.latitude,
      endLongitude: position.longitude,
    );

    return distance >= _movementThresholdMeters;
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

  /// Check if weather cache is still valid (< 5 minutes old)
  bool _isCacheValid() {
    if (_cachedWeatherData == null || _cacheTimestamp == null) {
      return false;
    }
    final age = DateTime.now().difference(_cacheTimestamp!);
    return age < _cacheTTL;
  }

  /// Get age of cached weather data
  Duration _getCacheAge() {
    if (_cacheTimestamp == null) {
      return const Duration();
    }
    return DateTime.now().difference(_cacheTimestamp!);
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
    return stateNotifier.value.data;
  }

  /// Update safe parameter ranges
  void updateSafeParameters({
    required double safeTemperatureMin,
    required double safeTemperatureMax,
    required double safeTurbidityMin,
    required double safeTurbidityMax,
  }) {
    if (stateNotifier.value.data != null) {
      final updated = stateNotifier.value.data!.copyWith(
        safeTemperatureMin: safeTemperatureMin,
        safeTemperatureMax: safeTemperatureMax,
        safeTurbidityMin: safeTurbidityMin,
        safeTurbidityMax: safeTurbidityMax,
      );
      stateNotifier.value = stateNotifier.value.copyWith(data: updated);
    }
  }

  /// Generate 7-day weather forecast - fetches real data from OpenWeatherMap
  List<WeatherForecast> getForecast() {
    // Check cache first
    if (_isForecastCacheValid() && _cachedForecast != null) {
      debugPrint('✓ Using cached forecast data');
      return _cachedForecast!;
    }

    // If we have location data, we can fetch real forecast
    if (_lastLatitude != null && _lastLongitude != null && openWeatherApiKey.isNotEmpty) {
      debugPrint('Fetching real forecast data...');
      _fetchForecastDataAsync(_lastLatitude!, _lastLongitude!);
      
      // Return cached data if available while fetching
      if (_cachedForecast != null) {
        return _cachedForecast!;
      }
    }

    // Fallback to mock data
    return _getMockForecast();
  }

  /// Async method to fetch forecast in background
  Future<void> _fetchForecastDataAsync(double lat, double lon) async {
    try {
      if (!_connectivityService.isOnline) {
        debugPrint('✗ Offline: Cannot fetch forecast.');
        return;
      }

      final url = Uri.parse(
        '$openWeatherBaseUrl/forecast?lat=$lat&lon=$lon&units=metric&appid=$openWeatherApiKey',
      );

      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final forecast = _parseForecastData(data);
        _cachedForecast = forecast;
        _forecastCacheTimestamp = DateTime.now();
        debugPrint('✓ Forecast data fetched successfully');
      } else {
        debugPrint('✗ Forecast fetch failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching forecast: $e');
    }
  }

  /// Parse forecast API response into daily forecasts
  List<WeatherForecast> _parseForecastData(Map<String, dynamic> data) {
    final forecasts = <WeatherForecast>[];
    final list = data['list'] as List<dynamic>? ?? [];
    
    if (list.isEmpty) return _getMockForecast();

    // Group by day and get daily stats
    final dayMap = <String, List<Map<String, dynamic>>>{};
    
    for (final item in list) {
      final dt = DateTime.fromMillisecondsSinceEpoch((item['dt'] as int) * 1000);
      final dayKey = '${dt.year}-${dt.month}-${dt.day}';
      dayMap.putIfAbsent(dayKey, () => []).add(item as Map<String, dynamic>);
    }

    // Convert to daily forecasts (up to 5 days)
    for (final entries in dayMap.values.take(5)) {
      if (entries.isEmpty) continue;

      final temps = entries.map((e) => (e['main']['temp'] as num).toDouble()).toList();
      final humidity = (entries.first['main']['humidity'] as num).toDouble();
      final precipChance = ((entries.first['clouds']['all'] as num).toInt()).clamp(0, 100);
      final condition = entries.first['weather'][0]['main'] as String;
      final dt = DateTime.fromMillisecondsSinceEpoch((entries.first['dt'] as int) * 1000);

      forecasts.add(
        WeatherForecast(
          date: dt,
          maxTemp: temps.reduce((a, b) => a > b ? a : b),
          minTemp: temps.reduce((a, b) => a < b ? a : b),
          condition: condition,
          precipitationChance: precipChance,
          humidity: humidity.toInt(),
        ),
      );
    }

    return forecasts.take(5).toList();
  }

  /// Check if forecast cache is still valid
  bool _isForecastCacheValid() {
    if (_forecastCacheTimestamp == null) return false;
    return DateTime.now().difference(_forecastCacheTimestamp!) < _forecastCacheTTL;
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
    ];
  }

  /// Dispose resources
  void dispose() {
    _positionSubscription?.cancel();
    _stopPeriodicRefresh();
    // Note: Don't dispose stateNotifier as it's a singleton that may be reused
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
