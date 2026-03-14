import 'package:flutter/foundation.dart';
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
            debugPrint('Error parsing threshold: $e');
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
        debugPrint('Error parsing threshold: $e');
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
      debugPrint('Error saving threshold: $e');
      return false;
    }
  }

  /// Delete a threshold
  static Future<bool> deleteThreshold(String parameterId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove('$_thresholdKeyPrefix$parameterId');
    } catch (e) {
      debugPrint('Error deleting threshold: $e');
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
      debugPrint('Error resetting thresholds: $e');
      return false;
    }
  }

  /// Get default thresholds for all parameters
  /// Values sourced from Safe_Level_Reference.csv:
  ///   minSafeValue/maxSafeValue  = Warning_Low/Warning_High (optimal range)
  ///   warningMinValue/warningMaxValue = Danger_Low/Danger_High (outer boundary before critical)
  static List<Threshold> getDefaultThresholds() {
    return [
      Threshold(
        parameterId: 'temperature',
        parameterName: 'Temperature',
        minSafeValue: 26.0,   // Warning_Low  (26-29 optimal)
        maxSafeValue: 29.0,   // Warning_High
        warningMinValue: 25.0, // Danger_Low
        warningMaxValue: 30.0, // Danger_High
        enableAlerts: true,
        enableNotifications: true,
        lastModified: DateTime.now(),
      ),
      Threshold(
        parameterId: 'pH',
        parameterName: 'pH Level',
        minSafeValue: 7.0,    // Warning_Low  (7.0-8.5 optimal)
        maxSafeValue: 8.5,    // Warning_High
        warningMinValue: 6.5,  // Danger_Low
        warningMaxValue: 9.0,  // Danger_High
        enableAlerts: true,
        enableNotifications: true,
        lastModified: DateTime.now(),
      ),
      Threshold(
        parameterId: 'dissolvedOxygen',
        parameterName: 'Dissolved Oxygen',
        minSafeValue: 5.0,    // Warning_Low  (>=5 marginal, >=6 optimal)
        maxSafeValue: 999.0,  // No upper danger limit
        warningMinValue: 3.0,  // Danger_Low   (<3 lethal)
        warningMaxValue: 999.0, // No upper danger limit
        enableAlerts: true,
        enableNotifications: true,
        lastModified: DateTime.now(),
      ),
      Threshold(
        parameterId: 'ammonia',
        parameterName: 'Ammonia',
        minSafeValue: 0.0,    // Danger_Low / Warning_Low
        maxSafeValue: 0.02,   // Warning_High (<=0.02 safe)
        warningMinValue: 0.0,  // Danger_Low
        warningMaxValue: 0.05, // Danger_High  (>0.05 danger)
        enableAlerts: true,
        enableNotifications: true,
        lastModified: DateTime.now(),
      ),
    ];
  }
}
