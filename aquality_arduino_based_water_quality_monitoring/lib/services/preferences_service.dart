import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  static PreferencesService get instance => _instance;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Onboarding
  bool get hasCompletedOnboarding => _prefs?.getBool('onboarding_completed') ?? false;
  
  Future<bool> setOnboardingCompleted(bool value) async {
    return await _prefs?.setBool('onboarding_completed', value) ?? false;
  }

  // Theme
  bool? get isDarkMode => _prefs?.getBool('is_dark_mode');
  
  Future<bool> setDarkMode(bool value) async {
    return await _prefs?.setBool('is_dark_mode', value) ?? false;
  }

  // History Time Range
  String get lastTimeRange => _prefs?.getString('last_time_range') ?? '24h';
  
  Future<bool> setLastTimeRange(String value) async {
    return await _prefs?.setString('last_time_range', value) ?? false;
  }

  // History Date Range
  DateTime? get historyStartDate {
    final timestamp = _prefs?.getInt('history_start_date');
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  DateTime? get historyEndDate {
    final timestamp = _prefs?.getInt('history_end_date');
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  Future<bool> setHistoryDateRange(DateTime? start, DateTime? end) async {
    if (start != null && end != null) {
      await _prefs?.setInt('history_start_date', start.millisecondsSinceEpoch);
      return await _prefs?.setInt('history_end_date', end.millisecondsSinceEpoch) ?? false;
    } else {
      await _prefs?.remove('history_start_date');
      await _prefs?.remove('history_end_date');
      return true;
    }
  }

  // Clear all preferences
  Future<bool> clearAll() async {
    return await _prefs?.clear() ?? false;
  }

  // Clear specific preference
  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }
}
