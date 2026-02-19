import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/threshold.dart';

class ThresholdService {
  static const String _thresholdKeyPrefix = 'threshold_';

  /// Get all thresholds
  static Future<List<Threshold>> getAllThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final thresholds = <Threshold>[];

    for (final key in keys) {
      if (key.startsWith(_thresholdKeyPrefix)) {
        final data = prefs.getString(key);
        if (data != null) {
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            thresholds.add(Threshold.fromJson(json));
          } catch (e) {
            print('Error parsing threshold: $e');
          }
        }
      }
    }

    return thresholds;
  }

  /// Get threshold for a specific parameter
  static Future<Threshold?> getThreshold(String parameterId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('$_thresholdKeyPrefix$parameterId');
    if (data != null) {
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        return Threshold.fromJson(json);
      } catch (e) {
        print('Error parsing threshold: $e');
      }
    }
    return null;
  }

  /// Save or update a threshold
  static Future<bool> saveThreshold(Threshold threshold) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(threshold.toJson());
      return await prefs.setString(
        '$_thresholdKeyPrefix${threshold.parameterId}',
        json,
      );
    } catch (e) {
      print('Error saving threshold: $e');
      return false;
    }
  }

  /// Delete a threshold
  static Future<bool> deleteThreshold(String parameterId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove('$_thresholdKeyPrefix$parameterId');
    } catch (e) {
      print('Error deleting threshold: $e');
      return false;
    }
  }

  /// Reset all thresholds to defaults
  static Future<bool> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_thresholdKeyPrefix)) {
          await prefs.remove(key);
        }
      }
      return true;
    } catch (e) {
      print('Error resetting thresholds: $e');
      return false;
    }
  }

  /// Get default thresholds for all parameters
  static List<Threshold> getDefaultThresholds() {
    return [
      Threshold(
        parameterId: 'temperature',
        parameterName: 'Temperature',
        minSafeValue: 25,
        maxSafeValue: 30,
        warningMinValue: 20,
        warningMaxValue: 35,
        enableAlerts: true,
        enableNotifications: true,
        lastModified: DateTime.now(),
      ),
      Threshold(
        parameterId: 'pH',
        parameterName: 'pH Level',
        minSafeValue: 6.5,
        maxSafeValue: 9.0,
        warningMinValue: 6.0,
        warningMaxValue: 9.5,
        enableAlerts: true,
        enableNotifications: true,
        lastModified: DateTime.now(),
      ),
      Threshold(
        parameterId: 'chlorine',
        parameterName: 'Chlorine',
        minSafeValue: 0,
        maxSafeValue: 0.02,
        warningMinValue: 0,
        warningMaxValue: 0.05,
        enableAlerts: true,
        enableNotifications: true,
        lastModified: DateTime.now(),
      ),
      Threshold(
        parameterId: 'dissolvedOxygen',
        parameterName: 'Dissolved Oxygen',
        minSafeValue: 5.0,
        maxSafeValue: 10.0,
        warningMinValue: 4.0,
        warningMaxValue: 12.0,
        enableAlerts: true,
        enableNotifications: true,
        lastModified: DateTime.now(),
      ),
      Threshold(
        parameterId: 'ammonia',
        parameterName: 'Ammonia',
        minSafeValue: 0,
        maxSafeValue: 0.5,
        warningMinValue: 0,
        warningMaxValue: 1.0,
        enableAlerts: true,
        enableNotifications: true,
        lastModified: DateTime.now(),
      ),
    ];
  }
}
