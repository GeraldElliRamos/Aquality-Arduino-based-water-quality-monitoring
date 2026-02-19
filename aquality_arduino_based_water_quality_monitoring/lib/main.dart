import 'package:flutter/material.dart';

import 'pages/dashboard.dart';
import 'pages/trends.dart';
import 'pages/alerts.dart';
import 'pages/history.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferencesService.instance.init();
  runApp(const AqualityApp());
}

class AqualityApp extends StatefulWidget {
  const AqualityApp({super.key});

  @override
  State<AqualityApp> createState() => _AqualityAppState();
}

class _AqualityAppState extends State<AqualityApp> {
  final themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    themeService.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aquality',
      theme: themeService.lightTheme,
      darkTheme: themeService.darkTheme,
      themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashView(),
      routes: {
        '/onboarding': (context) => const OnboardingView(),
        '/admin': (context) => const AdminView(),
        '/admin-user': (context) => const AdminUserView(),
        '/admin-login': (context) => const AdminLoginView(),
        '/login': (context) => const LoginView(),
        '/signup': (context) => const SignupView(),
        '/user': (context) => const UserView(),
        '/settings': (context) => const SettingsView(),
        '/faq': (context) => const FAQView(),
        '/app': (context) => const AppScreen(),
      },
    );
  }
}

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _views = <Widget>[
    Dashboard(),
    TrendsView(),
    AlertsView(),
    HistoryView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Color(0xFF1A1A2E), Color(0xFF16213E)]
                : [Color(0xFFE6F0FF), Color(0xFFE6FFFB)],
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
                                Text(
                                  'Aquality',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Tilapia Pond Monitor',
                                  style: TextStyle(
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
                              onPressed: () {
                                Navigator.of(context).pushNamed('/settings');
                              },
                              tooltip: 'Settings',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.person,
                                color: Color(0xFF2563EB),
                              ),
                              onPressed: () {
                                if (AuthService.isLoggedIn.value) {
                                  // If admin, open admin user page; otherwise open regular user page
                                  if (AuthService.isAdmin.value) {
                                    Navigator.of(
                                      context,
                                    ).pushNamed('/admin-user');
                                  } else {
                                    Navigator.of(context).pushNamed('/user');
                                  }
                                } else {
                                  Navigator.of(context).pushNamed('/login');
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
                    child: _views[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Trends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),

      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: AuthService.isAdmin,
        builder: (context, isAdmin, _) {
          if (!isAdmin) return const SizedBox.shrink();
          return FloatingActionButton(
            backgroundColor: const Color(0xFF2563EB),
            onPressed: () => Navigator.of(context).pushNamed('/admin'),
            tooltip: 'Admin',
            child: const Icon(Icons.admin_panel_settings),
          );
        },
      ),
    );
  }
}
