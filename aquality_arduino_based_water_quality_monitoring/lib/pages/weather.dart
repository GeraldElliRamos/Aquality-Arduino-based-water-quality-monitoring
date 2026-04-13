import 'dart:async';
import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../services/esp32_weather_service.dart';
import '../services/firebase_service.dart';
import '../models/weather_data.dart';

class WeatherView extends StatefulWidget {
  const WeatherView({super.key});

  @override
  State<WeatherView> createState() => _WeatherViewState();
}

class _WeatherViewState extends State<WeatherView> {
  late ESP32WeatherService _weatherService;
  final languageService = LanguageService();

  // ── Firebase live sensor data ────────────────────────────────────────────
  StreamSubscription<WaterQualityReading>? _sensorSub;
  WaterQualityReading? _latestReading;

  String t(String key) => languageService.t(key);

  @override
  void initState() {
    super.initState();
    languageService.addListener(_onLanguageChanged);
    _weatherService = ESP32WeatherService();
    _weatherService.fetchWeatherData();

    // Subscribe to the Firebase realtime sensor stream
    _sensorSub = FirebaseService.instance.sensorStream.listen((reading) {
      if (mounted) setState(() => _latestReading = reading);
    });
  }

  void _onLanguageChanged() => setState(() {});

  @override
  void dispose() {
    languageService.removeListener(_onLanguageChanged);
    _sensorSub?.cancel();
    super.dispose();
  }

  // ── Derive water temperature status from live Firebase reading ───────────
  bool get _hasLiveFirebaseReading {
    final r = _latestReading;
    if (r == null) return false;
    // Treat all-zero payload as placeholder/no sensor data.
    return !(r.temperature == 0 && r.ph == 0 && r.ammonia == 0 && r.turbidity == 0);
  }

  String _effectiveRecommendation(WeatherData weatherData) {
    final recommendation = weatherData.getRecommendation();
    if (_hasLiveFirebaseReading &&
        recommendation.toLowerCase().contains('not connected')) {
      return 'Live Firebase sensor readings are active. Continue monitoring parameter trends and keep values within safe ranges.';
    }
    return recommendation;
  }

  String _getTemperatureStatus(double temp, double minSafe, double maxSafe) {
    if (_latestReading == null) return 'not_connected';
    if (temp >= minSafe && temp <= maxSafe) return 'optimal';
    final margin = (maxSafe - minSafe) * 0.15;
    if (temp >= minSafe - margin && temp <= maxSafe + margin) return 'warning';
    return 'critical';
  }

  // ── Derive turbidity status from live Firebase reading ───────────────────
  String _getTurbidityStatus(double turbidity, double minSafe, double maxSafe) {
    if (_latestReading == null) return 'not_connected';
    if (turbidity >= minSafe && turbidity <= maxSafe) return 'optimal';
    final margin = (maxSafe - minSafe) * 0.15;
    if (turbidity >= minSafe - margin && turbidity <= maxSafe + margin) return 'warning';
    return 'critical';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'not_connected':
        return const Color(0xFF6B7280);
      case 'optimal':
        return const Color(0xFF10B981);
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'critical':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () => _weatherService.fetchWeatherData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ValueListenableBuilder<WeatherData?>(
          valueListenable: _weatherService.weatherDataNotifier,
          builder: (context, weatherData, _) {
            // Show loading state while fetching
            if (_weatherService.stateNotifier.value.isLoading && weatherData == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t('fetching_weather'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (weatherData == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 48,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t('failed_weather'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  // Manual Refresh Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Weather Updates',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _weatherService.fetchWeatherData();
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Refresh Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Current Weather Card
                  _buildCurrentWeatherCard(weatherData, isDark),
                  const SizedBox(height: 20),

                  // Safe Parameters Section — now driven by Firebase
                  _buildSafeParametersSection(weatherData, isDark),
                  const SizedBox(height: 20),

                  // 5-Day Forecast
                  _buildForecastSection(isDark),
                  const SizedBox(height: 20),

                  // Weather-based safe parameter prediction
                  _buildWeatherSafetyPredictionSection(isDark),
                  const SizedBox(height: 20),

                  // Recommendations
                  _buildRecommendationsCard(weatherData, isDark),
                  const SizedBox(height: 20),

                  // ESP32 Sensor Info
                  _buildSensorInfoCard(weatherData, isDark),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherCard(WeatherData weatherData, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('current_weather'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    weatherData.weatherCondition,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        weatherData.locationName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                weatherData.weatherIcon,
                style: const TextStyle(fontSize: 48),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherMetric(
                icon: Icons.thermostat,
                label: t('ambient'),
                value: '${weatherData.temperature.toStringAsFixed(1)}°C',
                color: Colors.white,
              ),
              _buildWeatherMetric(
                icon: Icons.opacity,
                label: t('humidity'),
                value: '${weatherData.humidity.toStringAsFixed(0)}%',
                color: Colors.white,
              ),
              _buildWeatherMetric(
                icon: Icons.air,
                label: t('wind'),
                value: '${weatherData.windSpeed.toStringAsFixed(1)} km/h',
                color: Colors.white,
              ),
              _buildWeatherMetric(
                icon: Icons.sunny,
                label: t('uv_index'),
                value: weatherData.uvIndex.toStringAsFixed(1),
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── Safe Parameters Section ──────────────────────────────────────────────
  // Water temperature and turbidity values now come from Firebase Realtime DB.
  // Safe-range bounds are still sourced from WeatherData (weather-adjusted).
  Widget _buildSafeParametersSection(WeatherData weatherData, bool isDark) {
    // Live values from Firebase (fall back to double.infinity when not yet received)
    final liveTemp = _latestReading?.temperature ?? double.infinity;
    final liveTurb = _latestReading?.turbidity ?? double.infinity;

    // Safe-range bounds from weather model
    final minTemp = weatherData.safeTemperatureMin;
    final maxTemp = weatherData.safeTemperatureMax;
    final minTurb = weatherData.safeTurbidityMin;
    final maxTurb = weatherData.safeTurbidityMax;

    // Statuses computed from live Firebase data
    final tempStatus = _getTemperatureStatus(liveTemp, minTemp, maxTemp);
    final turbStatus = _getTurbidityStatus(liveTurb, minTurb, maxTurb);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t('safe_parameter_status'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              // Live indicator badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _hasLiveFirebaseReading
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _hasLiveFirebaseReading
                          ? Icons.circle
                          : Icons.circle_outlined,
                      size: 8,
                      color: _hasLiveFirebaseReading
                          ? const Color(0xFF10B981)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _hasLiveFirebaseReading ? 'LIVE' : 'WAITING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _hasLiveFirebaseReading
                            ? const Color(0xFF10B981)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildParameterCard(
                  title: t('water_temperature'),
                  currentValue: liveTemp,
                  minSafe: minTemp,
                  maxSafe: maxTemp,
                  unit: '°C',
                  status: tempStatus,
                  icon: Icons.thermostat,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildParameterCard(
                  title: t('turbidity'),
                  currentValue: liveTurb,
                  minSafe: minTurb,
                  maxSafe: maxTurb,
                  unit: 'NTU',
                  status: turbStatus,
                  icon: Icons.opacity,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          // Last updated timestamp from Firebase
          if (_latestReading != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Firebase updated: '
                '${_latestReading!.timestamp.hour.toString().padLeft(2, '0')}:'
                '${_latestReading!.timestamp.minute.toString().padLeft(2, '0')}:'
                '${_latestReading!.timestamp.second.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParameterCard({
    required String title,
    required double currentValue,
    required double minSafe,
    required double maxSafe,
    required String unit,
    required String status,
    required IconData icon,
    required bool isDark,
  }) {
    final hasReading = currentValue.isFinite;
    final statusColor = _getStatusColor(status);
    final isSafe = status == 'optimal';

    // Progress value: how far through the safe range the reading sits (clamped 0–1)
    double progressValue = 0;
    if (hasReading && maxSafe > minSafe) {
      progressValue = ((currentValue - minSafe) / (maxSafe - minSafe)).clamp(0.0, 1.0);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: statusColor, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status == 'not_connected' ? 'N/A' : status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            hasReading ? '${currentValue.toStringAsFixed(1)}$unit' : '--',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Safe: ${minSafe.toStringAsFixed(1)}-${maxSafe.toStringAsFixed(1)}$unit',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hasReading ? (isSafe ? progressValue : 0.5) : 0,
              minHeight: 4,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSection(bool isDark) {
    final forecast = _weatherService.getForecast();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('forecast_5day'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: forecast.length,
              itemBuilder: (context, index) {
                final fc = forecast[index];
                return _buildForecastCard(fc, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(WeatherForecast forecast, bool isDark) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            forecast.dayLabel,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(forecast.weatherIcon, style: const TextStyle(fontSize: 32)),
          Column(
            children: [
              Text(
                '${forecast.maxTemp.toStringAsFixed(0)}°',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${forecast.minTemp.toStringAsFixed(0)}°',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.water_drop, size: 12, color: Colors.blue),
              const SizedBox(width: 2),
              Text(
                '${forecast.precipitationChance}%',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSafetyPredictionSection(bool isDark) {
    final forecast = _weatherService.getForecast().take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('predicted_safe_params'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            t('ranges_adjust_weather'),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          ...forecast.map((day) => _buildPredictedSafetyCard(day, isDark)),
        ],
      ),
    );
  }

  Widget _buildPredictedSafetyCard(WeatherForecast forecast, bool isDark) {
    final prediction = _getSafetyPredictionForWeather(forecast.condition);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: prediction['riskColor'] as Color, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${forecast.dayLabel} • ${forecast.condition}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (prediction['riskColor'] as Color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  prediction['riskLabel'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: prediction['riskColor'] as Color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildPredictionMetric(
                  icon: Icons.thermostat,
                  label: t('temp_safe'),
                  value: '${prediction['tempMin']}-${prediction['tempMax']}°C',
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPredictionMetric(
                  icon: Icons.opacity,
                  label: t('turbidity_safe'),
                  value:
                      '${prediction['turbMin']}-${prediction['turbMax']} NTU',
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, Object> _getSafetyPredictionForWeather(String condition) {
    final weather = condition.toLowerCase();

    if (weather.contains('thunder') || weather.contains('storm')) {
      return {
        'tempMin': 22,
        'tempMax': 29,
        'turbMin': 15,
        'turbMax': 70,
        'riskLabel': 'HIGH VARIANCE',
        'riskColor': const Color(0xFFEF4444),
      };
    }

    if (weather.contains('rain') || weather.contains('drizzle')) {
      return {
        'tempMin': 23,
        'tempMax': 30,
        'turbMin': 10,
        'turbMax': 55,
        'riskLabel': 'WATCH RUNOFF',
        'riskColor': const Color(0xFFF59E0B),
      };
    }

    if (weather.contains('sun') || weather.contains('clear')) {
      return {
        'tempMin': 24,
        'tempMax': 31,
        'turbMin': 5,
        'turbMax': 35,
        'riskLabel': 'STABLE',
        'riskColor': const Color(0xFF10B981),
      };
    }

    if (weather.contains('cloud') || weather.contains('overcast')) {
      return {
        'tempMin': 24,
        'tempMax': 32,
        'turbMin': 5,
        'turbMax': 40,
        'riskLabel': 'MODERATE',
        'riskColor': const Color(0xFF3B82F6),
      };
    }

    return {
      'tempMin': 25,
      'tempMax': 32,
      'turbMin': 5,
      'turbMax': 60,
      'riskLabel': 'DEFAULT',
      'riskColor': const Color(0xFF6B7280),
    };
  }

  Widget _buildRecommendationsCard(WeatherData weatherData, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber[600]),
              const SizedBox(width: 8),
              Text(
                'Recommendations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• ${_effectiveRecommendation(weatherData)}',
            style: const TextStyle(fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorInfoCard(WeatherData weatherData, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESP32 Sensor Information',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Sensor ID', weatherData.sensorId),
          _buildInfoRow(
            'Sensor Status',
            (weatherData.hasSensorReadings || _hasLiveFirebaseReading)
                ? 'Connected'
                : 'Not connected',
          ),
          _buildInfoRow(
            'Last Updated',
            '${(_hasLiveFirebaseReading ? _latestReading!.timestamp : weatherData.lastUpdated).hour.toString().padLeft(2, '0')}:${(_hasLiveFirebaseReading ? _latestReading!.timestamp : weatherData.lastUpdated).minute.toString().padLeft(2, '0')}',
          ),
          _buildInfoRow(
            t('temp_range'),
            '${weatherData.safeTemperatureMin}°C - ${weatherData.safeTemperatureMax}°C',
          ),
          _buildInfoRow(
            t('turbidity_range'),
            '${weatherData.safeTurbidityMin} - ${weatherData.safeTurbidityMax} NTU',
          ),
          // Show live Firebase readings in the info card too
          if (_latestReading != null) ...[
            const Divider(height: 16),
            const Text(
              'Firebase Live Readings',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            _buildInfoRow(
              'Water Temp',
              '${_latestReading!.temperature.toStringAsFixed(1)}°C',
            ),
            _buildInfoRow(
              'Turbidity',
              '${_latestReading!.turbidity.toStringAsFixed(1)} NTU',
            ),
            _buildInfoRow(
              'pH',
              _latestReading!.ph.toStringAsFixed(2),
            ),
            _buildInfoRow(
              'Ammonia (NH₃)',
              '${_latestReading!.ammonia.toStringAsFixed(2)} ppm',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}