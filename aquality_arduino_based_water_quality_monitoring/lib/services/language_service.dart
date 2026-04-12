import 'package:flutter/material.dart';
import 'preferences_service.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  String _languageCode = 'en';
  String get languageCode => _languageCode;
  bool get isTagalog => _languageCode == 'tl';
  bool get isEnglish => _languageCode == 'en';
  Locale get locale => Locale(_languageCode);

  void loadSavedLanguage() {
    final saved = PreferencesService.instance.getLanguage();
    if (saved != null && (saved == 'en' || saved == 'tl')) {
      _languageCode = saved;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    await PreferencesService.instance.setLanguage(code);
    notifyListeners();
  }

  String t(String key) => AppTranslations.of(_languageCode, key);
}

class AppTranslations {
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      // ── Settings ────────────────────────────────────────────────
      'settings': 'Settings',
      'aquaculture_management': 'AQUACULTURE MANAGEMENT',
      'pond_configurations': 'Pond Configurations',
      'alert_thresholds': 'Alert Thresholds',
      'sensor_calibration': 'Sensor Calibration',
      'app_preferences': 'APP PREFERENCES',
      'language': 'Language',
      'appearance': 'Appearance',
      'support': 'SUPPORT',
      'faq_help': 'FAQ / Help Center',
      'about': 'About Aquality v1.0',
      'logout': 'Logout',
      'select_language': 'Select Language',
      'english': 'English',
      'tagalog': 'Tagalog (Filipino)',
      'cancel': 'Cancel',
      'language_changed': 'Language changed to',

      // ── Common ──────────────────────────────────────────────────
      'save': 'Save',
      'close': 'Close',
      'confirm': 'Confirm',
      'back': 'Back',
      'search': 'Search',
      'no_results': 'No results found',
      'loading': 'Loading...',
      'refresh': 'Refresh',
      'delete': 'Delete',
      'dismiss': 'Dismiss',
      'acknowledge': 'Acknowledge',
      'export_csv': 'Export CSV',
      'share': 'Share',
      'undo': 'Undo',
      'record_deleted': 'Record deleted',
      'alert_acknowledged': 'Alert acknowledged',

      // ── Dashboard ────────────────────────────────────────────────
      'system_status': 'System Status',
      'parameter_status': 'Parameter Status',
      'optimal': 'Optimal',
      'warning': 'Warning',
      'critical': 'Critical',
      'connected': 'Connected',
      'updated': 'Updated',
      'optimal_range': 'Optimal range',
      'safe_level': 'Safe level',
      'temperature': 'Temperature',
      'ph_level': 'pH Level',
      'ammonia': 'Ammonia',
      'turbidity': 'Turbidity',

      // ── Trends ───────────────────────────────────────────────────
      'parameter_trends': 'Parameter Trends',
      'select_parameter': 'Select Parameter',
      'trend_24h': 'Trend (24h)',
      'min': 'Min',
      'max': 'Max',
      'avg': 'Avg',
      'time': 'Time',
      'value': 'Value',
      'change': 'Change',
      'hours_ago': 'h ago',

      // ── Alerts ───────────────────────────────────────────────────
      'alerts': 'Alerts',
      'search_alerts': 'Search alerts...',
      'all': 'All',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'no_alerts': 'No Alerts',
      'no_alerts_desc': 'All parameters are within safe ranges.',
      'parameter': 'Parameter',
      'alert_time': 'Time',

      // ── History ──────────────────────────────────────────────────
      'historical_data': 'Historical Data',
      'week': 'Week',
      'month': 'Month',
      'record': 'Record',

      // ── Weather ──────────────────────────────────────────────────
      'current_weather': 'Current Weather',
      'fetching_weather': 'Getting your location & fetching weather data...',
      'failed_weather': 'Failed to load weather data',
      'ambient': 'Ambient',
      'humidity': 'Humidity',
      'wind': 'Wind',
      'uv_index': 'UV Index',
      'safe_parameter_status': 'Safe Parameter Status',
      'water_temperature': 'Water Temperature',
      'forecast_5day': '5-Day Forecast',
      'predicted_safe_params': 'Predicted Safe Parameters by Weather',
      'ranges_adjust_weather': 'These ranges adjust based on expected weather conditions.',
      'temp_safe': 'Temp Safe',
      'turbidity_safe': 'Turbidity Safe',
      'temp_range': 'Temperature Range',
      'turbidity_range': 'Turbidity Range',

      // ── Alert Messages (Farmer-friendly) ──────────────────────
      'water_too_hot': 'Water is too hot',
      'water_cold': 'Water is too cold',
      'water_cloudy': 'Water is very cloudy',
      'water_clear': 'Water is clear',
      'water_acidic': 'Water is acidic',
      'water_basic': 'Water is basic',
      'ammonia_high': 'Ammonia is high',
      'check_sensors': 'Please check your sensors',
      'backup_done': 'Backup completed',
      'water_clarity_issue': 'Water clarity issue',
      'water_temp_issue': 'Water temperature issue',
      'water_ph_issue': 'Water acidity/alkalinity issue',
      'action_needed': 'Action needed soon',
      'info_system': 'System information',

      // ── User / Profile ───────────────────────────────────────────
      'personal_information': 'Personal Information',
      'full_name': 'Full Name',
      'email_address': 'Email Address',
      'phone_number': 'Phone Number',
      'activity_insights': 'Activity Insights',
      'member_since': 'Member Since',
      'total_readings': 'Total Readings',
      'active_ponds': 'Active Ponds',
      'account_actions': 'Account Actions',
      'edit_profile': 'Edit Profile Details',
      'security_password': 'Security & Password',
      'logout_system': 'LOGOUT SYSTEM',
      'tilapia_farmer': 'Tilapia Farmer',
      'fish_pond_owner': 'Fish Pond Owner',
      'lgu_member': 'LGU Member',
      'user': 'User',

      // ── FAQ ──────────────────────────────────────────────────────
      'faq_title': 'Help & FAQ',
      'search_faq': 'Search FAQ...',
      'faq_general': 'General',
      'faq_parameters': 'Parameters',
      'faq_alerts': 'Alerts',
      'faq_data': 'Data & Export',
      'faq_troubleshoot': 'Troubleshooting',

      // FAQ - General
      'faq_q_what_is': 'What is Aquality?',
      'faq_a_what_is': 'Aquality is a water quality monitoring system for tilapia ponds. It uses Arduino-based sensors to measure key water parameters in real-time and helps you maintain optimal conditions for fish health.',
      'faq_q_update_freq': 'How often is data updated?',
      'faq_a_update_freq': 'The app refreshes data every 30 seconds automatically. You can also manually refresh by pulling down on the dashboard screen.',
      'faq_q_offline': 'Can I use Aquality offline?',
      'faq_a_offline': 'Aquality requires an internet connection to communicate with the Arduino sensors. However, historical data is cached locally for quick access.',

      // FAQ - Parameters
      'faq_q_temp': 'What is the ideal temperature for tilapia?',
      'faq_a_temp': 'Tilapia thrive in water temperatures between 26-30°C (78-86°F). Temperatures outside this range can stress the fish and affect growth rates.',
      'faq_q_ph': 'Why is pH level important?',
      'faq_a_ph': 'pH measures water acidity/alkalinity. Tilapia prefer slightly alkaline water (pH 7-9). Extreme pH values can harm fish health and affect their ability to absorb nutrients.',
      'faq_q_turbidity': 'What does turbidity mean?',
      'faq_a_turbidity': 'Turbidity measures how cloudy the water is due to suspended particles. For tilapia ponds, keep turbidity at or below 30 NTU; 30-50 NTU is warning level, and values above 50 NTU are dangerous.',
      'faq_q_ammonia': 'How dangerous is ammonia?',
      'faq_a_ammonia': 'Ammonia (NH₃) is highly toxic to fish even at very low levels. Keep ammonia below 0.02 mg/L. Regular water changes and proper biological filtration help control ammonia buildup.',
      'faq_q_ammonia2': 'What is ammonia and why is it harmful?',
      'faq_a_ammonia2': 'Ammonia (NH₃) is a toxic waste product from fish metabolism and decomposing organic matter. Keep NH₃ below 0.02 mg/L to prevent fish stress, disease, and mortality.',

      // FAQ - Alerts
      'faq_q_problem': 'How do I know if there\'s a problem?',
      'faq_a_problem': 'The app sends alerts when parameters go outside safe ranges. Critical alerts (red) require immediate action, warnings (yellow) need attention soon, and info alerts (blue) are for general updates.',
      'faq_q_customize': 'Can I customize alert thresholds?',
      'faq_a_customize': 'Currently, alert thresholds are set based on standard tilapia farming best practices. Custom threshold settings will be available in a future update.',
      'faq_q_clear': 'How do I clear or dismiss alerts?',
      'faq_a_clear': 'Alerts automatically clear when the parameter returns to the safe range. You can view all alerts history in the Alerts tab.',

      // FAQ - Data
      'faq_q_history': 'How far back can I view historical data?',
      'faq_a_history': 'Historical data is available for the past 30 days. You can filter by 24 hours, 7 days, 30 days, or select a custom date range in the History tab.',
      'faq_q_export': 'How do I export data? (Admin and LGU Members)',
      'faq_a_export': 'Admin users and LGU members can export data as CSV files from the History tab or Settings. The exported file includes all parameters with timestamps.',
      'faq_q_files': 'Where are exported files saved?',
      'faq_a_files': 'Exported CSV files are saved to your device\'s Documents/Aquality folder. You can access them through your file manager.',

      // FAQ - Troubleshooting
      'faq_q_no_data': 'The app shows "No data available"',
      'faq_a_no_data': 'This means the sensors are not sending data. Check if the Arduino device is powered on and connected to the internet. Verify all sensor connections.',
      'faq_q_frozen': 'Data seems inaccurate or frozen',
      'faq_a_frozen': 'Try refreshing the dashboard by pulling down. If data remains frozen, check the Arduino device status and sensor calibration.',
      'faq_q_dark': 'Dark mode isn\'t working',
      'faq_a_dark': 'Toggle dark mode from Settings > Appearance > Dark Mode. If it still doesn\'t work, try restarting the app.',

      // ── Additional Common Strings ────────────────────────────
      'confirm_changes': 'Confirm Changes',
      'are_you_sure_save': 'Are you sure you want to save your changes?',
      'profile_updated': 'Profile updated successfully',
      'edit_admin_profile': 'Edit Admin Profile',
      'data_updated': 'Data updated successfully',
      'error_occurred': 'An error occurred',
      'try_again': 'Try Again',
      'ok': 'OK',
      'successfully': 'Successfully',
      'failed': 'Failed',
      'unsaved_changes': 'You have unsaved changes',
      'discard_changes': 'Discard Changes',
      'keep_editing': 'Keep Editing',
      'management_tools': 'Management Tools',
      // ── Chatbot Messages ────────────────────────────────────────────────
      'aqua_welcome': 'Hi! I\'m Aqua 🌊 your Aquality assistant. I can help you understand the dashboard, trends, alerts, history, settings, and profile modules. What would you like to know?',
      'aqua_greeting': 'Hi! I am Aqua, your Aquality assistant. Ask me about dashboard, alerts, trends, history, settings, or safe water ranges for tilapia.',
      'aqua_what_is_aquality': 'Aquality is an Arduino-based water quality monitoring app for freshwater tilapia ponds. It tracks key parameters and helps you respond quickly to risky changes.',
      'aqua_modules': 'Aquality modules:\n1. Dashboard - Live sensor readings and current system status.\n2. Trends - Historical charts to see water quality patterns over time.\n3. Alerts - Warnings when parameters go out of safe range.\n4. History - Full log of past readings for review and reporting.',
      'aqua_dashboard': 'Dashboard shows real-time pH, temperature, ammonia, and turbidity readings, plus status indicators so you can quickly check if pond conditions are safe.',
      'aqua_trends': 'Trends shows historical charts of your water parameters. Use it to track patterns by day, week, or month and spot changes early.',
      'aqua_alerts': 'Alerts lists notifications when a parameter becomes unsafe. It helps you respond quickly before conditions affect fish health.',
      'aqua_history': 'History stores previous water quality readings so you can review, filter, and use records for monitoring and reports.',
      'aqua_ph_safe': 'Safe pH for tilapia is usually 6.5 to 8.5.',
      'aqua_temp_safe': 'Safe temperature for tilapia is around 25 C to 32 C.',
      'aqua_ammonia': 'Keep ammonia very low, ideally around 0.00 to 0.02 mg/L for safer tilapia conditions.',
      'aqua_turbidity': 'Recommended turbidity is below 30 NTU for better water quality conditions.',
      'aqua_about': 'I am Aqua, the Aquality Assistant. I help explain your water quality data and app features.',
      'aqua_how_to_use': 'Start from Dashboard for live readings, check Alerts for warnings, view Trends/History for analysis, then adjust thresholds in Settings.',
      'ask_module': 'Ask about any module...',
    },

    'tl': {
      // ── Settings ────────────────────────────────────────────────
      'settings': 'Mga Setting',
      'aquaculture_management': 'PAMAMAHALA NG AQUACULTURE',
      'pond_configurations': 'Mga Pagsasaayos ng Pond',
      'alert_thresholds': 'Mga Limitasyon ng Alerto',
      'sensor_calibration': 'Pag-calibrate ng Sensor',
      'app_preferences': 'MGA KAGUSTUHAN SA APP',
      'language': 'Wika',
      'appearance': 'Hitsura',
      'support': 'SUPORTA',
      'faq_help': 'FAQ / Sentro ng Tulong',
      'about': 'Tungkol sa Aquality v1.0',
      'logout': 'Mag-logout',
      'select_language': 'Pumili ng Wika',
      'english': 'Ingles',
      'tagalog': 'Tagalog (Filipino)',
      'cancel': 'Kanselahin',
      'language_changed': 'Binago ang wika sa',

      // ── Common ──────────────────────────────────────────────────
      'save': 'I-save',
      'close': 'Isara',
      'confirm': 'Kumpirmahin',
      'back': 'Bumalik',
      'search': 'Maghanap',
      'no_results': 'Walang nahanap na resulta',
      'loading': 'Naglo-load...',
      'refresh': 'I-refresh',
      'delete': 'Burahin',
      'dismiss': 'Tanggalin',
      'acknowledge': 'Kilalanin',
      'export_csv': 'I-export ang CSV',
      'share': 'Ibahagi',
      'undo': 'I-undo',
      'record_deleted': 'Nabura ang rekord',
      'alert_acknowledged': 'Natanggap ang alerto',

      // ── Dashboard ────────────────────────────────────────────────
      'system_status': 'Katayuan ng Sistema',
      'parameter_status': 'Katayuan ng Parameter',
      'optimal': 'Perpekto',
      'warning': 'Babala',
      'critical': 'Kritikal',
      'connected': 'Nakakonekta',
      'updated': 'Na-update',
      'optimal_range': 'Perpektong hanay',
      'safe_level': 'Ligtas na antas',
      'temperature': 'Temperatura',
      'ph_level': 'Antas ng pH',
      'ammonia': 'Ammonia',
      'turbidity': 'Kalabuan',

      // ── Trends ───────────────────────────────────────────────────
      'parameter_trends': 'Mga Trend ng Parameter',
      'select_parameter': 'Pumili ng Parameter',
      'trend_24h': 'Trend (24h)',
      'min': 'Min',
      'max': 'Max',
      'avg': 'Average',
      'time': 'Oras',
      'value': 'Halaga',
      'change': 'Pagbabago',
      'hours_ago': 'oras na',

      // ── Alerts ───────────────────────────────────────────────────
      'alerts': 'Mga Alerto',
      'search_alerts': 'Maghanap ng mga alerto...',
      'all': 'Lahat',
      'today': 'Ngayon',
      'yesterday': 'Kahapon',
      'no_alerts': 'Walang Alerto',
      'no_alerts_desc': 'Lahat ng parameter ay nasa ligtas na hanay.',
      'parameter': 'Parameter',
      'alert_time': 'Oras',

      // ── History ──────────────────────────────────────────────────
      'historical_data': 'Makasaysayang Data',
      'week': 'Linggo',
      'month': 'Buwan',
      'record': 'Rekord',

      // ── Weather ──────────────────────────────────────────────────
      'current_weather': 'Kasalukuyang Panahon',
      'fetching_weather': 'Kinukuha ang lokasyon at datos ng panahon...',
      'failed_weather': 'Hindi ma-load ang datos ng panahon',
      'ambient': 'Kapaligiran',
      'humidity': 'Halumigmig',
      'wind': 'Hangin',
      'uv_index': 'UV Index',
      'safe_parameter_status': 'Ligtas na Katayuan ng Parameter',
      'water_temperature': 'Temperatura ng Tubig',
      'forecast_5day': 'Forecast ng 5 Araw',
      'predicted_safe_params': 'Predicted na Ligtas na Parameter ayon sa Panahon',
      'ranges_adjust_weather': 'Ang mga ranggo na ito ay nag-adjust batay sa inaasahang kondisyon ng panahon.',
      'temp_safe': 'Ligtas na Temp',
      'turbidity_safe': 'Ligtas na Kalabuan',
      'temp_range': 'Hanay ng Temperatura',
      'turbidity_range': 'Hanay ng Kalabuan',

      // ── Alert Messages (Farmer-friendly) ──────────────────────
      'water_too_hot': 'Masyadong mainit ang tubig',
      'water_cold': 'Masyadong malamig ang tubig',
      'water_cloudy': 'Masyadong malabo ang tubig',
      'water_clear': 'Malinaw ang tubig',
      'water_acidic': 'Acidic ang tubig',
      'water_basic': 'Basic ang tubig',
      'ammonia_high': 'Mataas ang ammonia',
      'check_sensors': 'Mangyaring suriin ang iyong mga sensor',
      'backup_done': 'Backup ay tapos na',
      'water_clarity_issue': 'Problema sa kalinisan ng tubig',
      'water_temp_issue': 'Problema sa temperatura ng tubig',
      'water_ph_issue': 'Problema sa asididad/alkalinity ng tubig',
      'action_needed': 'May aksyon na kailangan malapit nang',
      'info_system': 'Impormasyon ng sistema',

      // ── User / Profile ───────────────────────────────────────────
      'personal_information': 'Personal na Impormasyon',
      'full_name': 'Buong Pangalan',
      'email_address': 'Email Address',
      'phone_number': 'Numero ng Telepono',
      'activity_insights': 'Mga Aktibidad',
      'member_since': 'Miyembro Mula',
      'total_readings': 'Kabuuang Pagbabasa',
      'active_ponds': 'Mga Aktibong Pond',
      'account_actions': 'Mga Aksyon sa Account',
      'edit_profile': 'I-edit ang Detalye ng Profile',
      'security_password': 'Seguridad at Password',
      'logout_system': 'MAG-LOGOUT',
      'tilapia_farmer': 'Magsasaka ng Tilapia',
      'fish_pond_owner': 'May-ari ng Fish Pond',
      'lgu_member': 'Miyembro ng LGU',
      'user': 'Gumagamit',

      // ── FAQ ──────────────────────────────────────────────────────
      'faq_title': 'Tulong at FAQ',
      'search_faq': 'Maghanap sa FAQ...',
      'faq_general': 'Pangkalahatan',
      'faq_parameters': 'Mga Parameter',
      'faq_alerts': 'Mga Alerto',
      'faq_data': 'Data at Export',
      'faq_troubleshoot': 'Pag-aayos ng Problema',

      // FAQ - General
      'faq_q_what_is': 'Ano ang Aquality?',
      'faq_a_what_is': 'Ang Aquality ay isang sistema ng pagsubaybay ng kalidad ng tubig para sa mga tilapia pond. Gumagamit ito ng mga sensor na batay sa Arduino upang masukat ang mga pangunahing parameter ng tubig sa real-time at tinutulungan kang mapanatili ang pinakamainam na kondisyon para sa kalusugan ng isda.',
      'faq_q_update_freq': 'Gaano kadalas ina-update ang data?',
      'faq_a_update_freq': 'Awtomatikong nagre-refresh ang app ng data tuwing 30 segundo. Maaari ka ring mag-refresh nang manu-mano sa pamamagitan ng pag-pull down sa dashboard screen.',
      'faq_q_offline': 'Maaari ko bang gamitin ang Aquality offline?',
      'faq_a_offline': 'Nangangailangan ang Aquality ng koneksyon sa internet upang makipag-ugnayan sa mga Arduino sensor. Gayunpaman, ang makasaysayang data ay naka-cache lokal para sa mabilis na pag-access.',

      // FAQ - Parameters
      'faq_q_temp': 'Ano ang perpektong temperatura para sa tilapia?',
      'faq_a_temp': 'Umunlad ang tilapia sa temperatura ng tubig na 26-30°C (78-86°F). Ang mga temperatura na labas sa hanay na ito ay maaaring mag-stress sa isda at makaapekto sa kanilang paglaki.',
      'faq_q_ph': 'Bakit mahalaga ang antas ng pH?',
      'faq_a_ph': 'Sinusukat ng pH ang asido/alkalinity ng tubig. Mas gusto ng tilapia ang bahagyang alkaline na tubig (pH 7-9). Ang mga matinding halaga ng pH ay maaaring makapinsala sa kalusugan ng isda.',
      'faq_q_turbidity': 'Ano ang ibig sabihin ng turbidity?',
      'faq_a_turbidity': 'Sinusukat ng turbidity kung gaano kalabo ang tubig dahil sa mga nakabitin na particle. Para sa mga tilapia pond, panatilihing nasa o mas mababa sa 30 NTU; ang 30-50 NTU ay antas ng babala, at ang mga halagang higit sa 50 NTU ay mapanganib.',
      'faq_q_ammonia': 'Gaano kapaligid ang ammonia?',
      'faq_a_ammonia': 'Ang ammonia (NH₃) ay lubhang nakakalason sa isda kahit sa napakababang antas. Panatilihing mas mababa sa 0.02 mg/L ang ammonia. Ang regular na pagpapalitan ng tubig ay nakakatulong sa pagkontrol ng ammonia.',
      'faq_q_ammonia2': 'Ano ang ammonia at bakit ito nakakapinsala?',
      'faq_a_ammonia2': 'Ang ammonia (NH₃) ay isang nakakalasong basura mula sa metabolismo ng isda at nabubulok na organikong bagay. Panatilihing mas mababa sa 0.02 mg/L ang NH₃ upang maiwasan ang stress ng isda.',

      // FAQ - Alerts
      'faq_q_problem': 'Paano ko malalaman kung may problema?',
      'faq_a_problem': 'Nagpapadala ang app ng mga alerto kapag ang mga parameter ay lumabas sa ligtas na hanay. Ang mga kritikal na alerto (pula) ay nangangailangan ng agarang aksyon, ang mga babala (dilaw) ay nangangailangan ng atensyon sa lalong madaling panahon.',
      'faq_q_customize': 'Maaari ba akong mag-customize ng mga limitasyon ng alerto?',
      'faq_a_customize': 'Sa kasalukuyan, ang mga limitasyon ng alerto ay nakatakda batay sa mga pamantayan ng pagsasaka ng tilapia. Ang mga custom na setting ng limitasyon ay magiging available sa isang susunod na update.',
      'faq_q_clear': 'Paano ko matatanggal o madi-dismiss ang mga alerto?',
      'faq_a_clear': 'Awtomatikong natatanggal ang mga alerto kapag ang parameter ay bumalik sa ligtas na hanay. Maaari mong tingnan ang lahat ng kasaysayan ng alerto sa tab na Mga Alerto.',

      // FAQ - Data
      'faq_q_history': 'Hanggang kailan ko makikita ang makasaysayang data?',
      'faq_a_history': 'Ang makasaysayang data ay available para sa nakalipas na 30 araw. Maaari kang mag-filter ayon sa 24 na oras, 7 araw, 30 araw, o pumili ng custom na hanay ng petsa sa tab na Kasaysayan.',
      'faq_q_export': 'Paano ako mag-export ng data? (Admin at Mga Miyembro ng LGU)',
      'faq_a_export': 'Ang mga admin user at mga miyembro ng LGU ay maaaring mag-export ng data bilang mga CSV file mula sa tab na Kasaysayan o Settings. Kasama sa na-export na file ang lahat ng parameter na may mga timestamp.',
      'faq_q_files': 'Saan sino-save ang mga na-export na file?',
      'faq_a_files': 'Ang mga na-export na CSV file ay sino-save sa Documents/Aquality folder ng iyong device. Maaari mong ma-access ang mga ito sa pamamagitan ng iyong file manager.',

      // FAQ - Troubleshooting
      'faq_q_no_data': 'Nagpapakita ang app ng "Walang available na data"',
      'faq_a_no_data': 'Nangangahulugan ito na ang mga sensor ay hindi nagpapadala ng data. Suriin kung ang Arduino device ay naka-on at nakakonekta sa internet. I-verify ang lahat ng koneksyon ng sensor.',
      'faq_q_frozen': 'Mukhang hindi tama o nadoble ang data',
      'faq_a_frozen': 'Subukang i-refresh ang dashboard sa pamamagitan ng pag-pull down. Kung nananatiling frozen ang data, suriin ang katayuan ng Arduino device at pag-calibrate ng sensor.',
      'faq_q_dark': 'Hindi gumagana ang dark mode',
      'faq_a_dark': 'I-toggle ang dark mode mula sa Settings > Hitsura > Dark Mode. Kung hindi pa rin gumagana, subukang i-restart ang app.',

      // ── Additional Common Strings ────────────────────────────
      'confirm_changes': 'Kumpirmahin ang Mga Pagbabago',
      'are_you_sure_save': 'Sigurado ka na bang gusto mong i-save ang iyong mga pagbabago?',
      'profile_updated': 'Matagumpay na ina-update ang profile',
      'edit_admin_profile': 'I-edit ang Admin Profile',
      'data_updated': 'Matagumpay na ina-update ang data',
      'error_occurred': 'Naganap ang isang error',
      'try_again': 'Subukan Muli',
      'ok': 'OK',
      'successfully': 'Matagumpay',
      'failed': 'Nabigong',
      'unsaved_changes': 'Mayroon kang hindi na-save na mga pagbabago',
      'discard_changes': 'Itapon ang Mga Pagbabago',
      'keep_editing': 'Magpatuloy sa Pag-edit',
      'management_tools': 'Mga Tool ng Pamamahala',
      // ── Chatbot Messages ────────────────────────────────────────────────
      'aqua_welcome': 'Kamusta! Ako si Aqua 🌊 ang iyong Aquality assistant. Matutulungan kita na maintindihan ang dashboard, trends, alerts, history, settings, at profile modules. Ano ang gusto mong malaman?',
      'aqua_greeting': 'Kamusta! Ako si Aqua, ang iyong Aquality assistant. Magtanong sa akin tungkol sa dashboard, alerts, trends, history, settings, o safe water ranges para sa tilapia.',
      'aqua_what_is_aquality': 'Ang Aquality ay isang Arduino-based water quality monitoring app para sa freshwater tilapia ponds. Sinusubaybayan nito ang mga pangunahing parameters at tumutulong sa iyo na tumugon ng mabilis sa mahigpit na pagbabago.',
      'aqua_modules': 'Mga module ng Aquality:\n1. Dashboard - Live sensor readings at kasalukuyang system status.\n2. Trends - Historical charts upang makita ang water quality patterns sa paglipas ng panahon.\n3. Alerts - Mga babala kapag lumabas ang isang parameter sa safe range.\n4. History - Buong log ng nakaraang readings para sa review at reporting.',
      'aqua_dashboard': 'Ang Dashboard ay nagpapakita ng real-time pH, temperature, ammonia, at turbidity readings, kasama ang status indicators para mabilis mong masuri kung ligtas ang kondisyon ng pond.',
      'aqua_trends': 'Ang Trends ay nagpapakita ng historical charts ng iyong water parameters. Gamitin ito upang subaybayan ang mga pattern araw-araw, linggo, o buwan at makilala ang mga pagbabago nang maaga.',
      'aqua_alerts': 'Ang Alerts ay nagpapatala ng mga notification kapag hindi ligtas ang isang parameter. Tumutulong ito sa iyo na tumugon ng mabilis bago makaapekto ang mga kondisyon sa kalusugan ng isda.',
      'aqua_history': 'Ang History ay nagsisimula ng mga nakaraang water quality readings upang mabago, ma-filter, at gamitin ang mga record para sa monitoring at reports.',
      'aqua_ph_safe': 'Ang ligtas na pH para sa tilapia ay karaniwang 6.5 hanggang 8.5.',
      'aqua_temp_safe': 'Ang ligtas na temperatura para sa tilapia ay tungkol sa 25 C hanggang 32 C.',
      'aqua_ammonia': 'Panatilihing napakababa ang ammonia, sa ideal na 0.00 hanggang 0.02 mg/L para sa mas ligtas na kondisyon ng tilapia.',
      'aqua_turbidity': 'Ang inirekomendang turbidity ay mas mababa sa 30 NTU para sa mas mahusay na water quality conditions.',
      'aqua_about': 'Ako si Aqua, ang Aquality Assistant. Tinutulungan kita na maunawaan ang iyong water quality data at app features.',
      'aqua_how_to_use': 'Magsimula sa Dashboard para sa live readings, tuklasin ang Alerts para sa mga babala, tingnan ang Trends/History para sa analysis, pagkatapos ay ayusin ang mga threshold sa Settings.',
      'ask_module': 'Magtanong tungkol sa anumang module...',
    },
  };

  static String of(String languageCode, String key) {
    return _translations[languageCode]?[key] ??
        _translations['en']?[key] ??
        key;
  }
}