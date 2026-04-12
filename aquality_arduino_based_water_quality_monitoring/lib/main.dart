import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pages/dashboard_enhanced.dart';
import 'pages/trends_enhanced.dart';
import 'pages/alerts_enhanced.dart';
import 'pages/history.dart';
import 'pages/weather.dart';
import 'pages/user.dart';
import 'pages/admin_user.dart';
import 'pages/login.dart';
import 'pages/signup.dart';
import 'pages/splash.dart';
import 'pages/settings.dart';
import 'pages/onboarding.dart';
import 'pages/faq.dart';
import 'admin/admin.dart';
import 'admin/admin_login.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'services/preferences_service.dart';
import 'services/language_service.dart';
import 'services/esp32_weather_service.dart';
import 'services/connectivity_service.dart';
import 'pages/role_selection.dart';
import 'widgets/chatbot.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await PreferencesService.instance.init();
  await ThemeService().loadSavedTheme();
  LanguageService().loadSavedLanguage();
  AuthService.init();

  // Initialize connectivity service for network detection
  await ConnectivityService().init();

  // Initialize weather service with OpenWeatherMap API key
  final weatherApiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  await ESP32WeatherService().init(apiKey: weatherApiKey);

  runApp(const AqualityApp());
}

class AqualityApp extends StatefulWidget {
  const AqualityApp({super.key});

  @override
  State<AqualityApp> createState() => _AqualityAppState();
}

class _AqualityAppState extends State<AqualityApp> {
  final themeService = ThemeService();
  final languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    themeService.addListener(() => setState(() {}));
    languageService.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aquality',
      theme: themeService.lightTheme,
      darkTheme: themeService.darkTheme,
      themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: languageService.locale,

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashView();
          }
          if (snapshot.hasData) {
            return ValueListenableBuilder<String>(
              valueListenable: AuthService.userRole,
              builder: (context, role, _) {
                if (role.isEmpty) return const SplashView();
                switch (role) {
                  case 'fishPondOwner':
                    return const AppScreen(role: 'fishPondOwner');
                  case 'lgu':
                    return const AppScreen(role: 'lgu');
                  default:
                    return const AppScreen(role: 'tilapiaFarmer');
                }
              },
            );
          }
          return const LoginView();
        },
      ),

      routes: {
        '/onboarding': (context) => const OnboardingView(),
        '/admin': (context) => const AdminView(),
        '/admin-user': (context) => const AdminUserView(),
        '/admin-login': (context) => const AdminLoginView(),
        '/login': (context) => const LoginView(),
        '/signup': (context) => const SignupView(),
        '/role-selection': (context) => const RoleSelectionView(),
        '/user': (context) => const UserView(),
        '/settings': (context) => const SettingsView(),
        '/faq': (context) => const FAQView(),
        '/app': (context) => const AppScreen(role: 'tilapiaFarmer'),
        '/app-owner': (context) => const AppScreen(role: 'fishPondOwner'),
        '/app-lgu': (context) => const AppScreen(role: 'lgu'),
      },

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('tl')],
    );
  }
}

class AppScreen extends StatefulWidget {
  final String role;
  const AppScreen({super.key, this.role = 'tilapiaFarmer'});

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _views = <Widget>[
    DashboardEnhanced(),
    TrendsViewEnhanced(),
    AlertsViewEnhanced(),
    WeatherView(),
    HistoryView(),
    AdminView(),
  ];

  String get _roleLabel {
    final languageService = LanguageService();
    switch (widget.role) {
      case 'fishPondOwner':
        return languageService.t('fish_pond_owner');
      case 'lgu':
        return languageService.t('lgu_member');
      default:
        return 'Tilapia Pond Monitor';
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                    : [const Color(0xFFE6F0FF), const Color(0xFFE6FFFB)],
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 428),
                child: Column(
                  children: [
                    SafeArea(
                      child: Container(
                        color: Theme.of(context).cardColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF2563EB),
                                        Color(0xFF06B6D4),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.dashboard,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Aquality',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _roleLabel,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.settings_outlined,
                                    color: Color(0xFF2563EB),
                                  ),
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushNamed('/settings'),
                                  tooltip: 'Settings',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.person,
                                    color: Color(0xFF2563EB),
                                  ),
                                  onPressed: () {
                                    if (AuthService.isAdmin.value) {
                                      Navigator.of(
                                        context,
                                      ).pushNamed('/admin-user');
                                    } else {
                                      Navigator.of(context).pushNamed('/user');
                                    }
                                  },
                                  tooltip: 'Profile',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: IndexedStack(
                          index: _selectedIndex,
                          children: _views,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: ValueListenableBuilder<bool>(
            valueListenable: AuthService.isAdmin,
            builder: (context, isAdmin, _) {
              return BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _selectedIndex,
                selectedItemColor: const Color(0xFF2563EB),
                unselectedItemColor: Colors.grey[600],
                onTap: (index) {
                  // Prevent navigation to admin panel if not admin
                  if (index == 5 && !isAdmin) return;
                  _onItemTapped(index);
                },
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.show_chart),
                    label: 'Trends',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.notifications),
                    label: 'Alerts',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.cloud),
                    label: 'Weather',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.history),
                    label: 'History',
                  ),
                  if (isAdmin)
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.admin_panel_settings),
                      label: 'Admin',
                    ),
                ],
              );
            },
          ),

        ),
        // Chatbot floating button
        const AqualityChatbot(),
      ],
    );
  }
}