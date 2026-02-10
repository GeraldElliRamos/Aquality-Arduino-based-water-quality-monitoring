import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import 'pages/dashboard.dart';
import 'pages/trends.dart';
import 'pages/alerts.dart';
import 'pages/history.dart';
import 'pages/user.dart';
import 'pages/login.dart';
import 'pages/signup.dart';
import 'pages/splash.dart';
import 'admin/admin.dart';
import 'admin/admin_login.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const AqualityApp());
}

class AqualityApp extends StatelessWidget {
  const AqualityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aquality',
      home: const SplashView(),
      routes: {
        '/admin': (context) => const AdminView(),
        '/admin-login': (context) => const AdminLoginView(),
        '/login': (context) => const LoginView(),
        '/signup': (context) => const SignupView(),
        '/user': (context) => const UserView(),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE6F0FF), Color(0xFFE6FFFB)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 428),
            child: Column(
              children: [
                // Mobile Header
                SafeArea(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                  colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              child: const Icon(Icons.dashboard, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Aquality', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                SizedBox(height: 2),
                                Text('Tilapia Pond Monitor', style: TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ],
                        ),

                        // User button (separate user side)
                        IconButton(
                          icon: const Icon(Icons.person, color: Color(0xFF2563EB)),
                          onPressed: () {
                            if (AuthService.isLoggedIn.value) {
                              Navigator.of(context).pushNamed('/app');
                            } else {
                              Navigator.of(context).pushNamed('/login');
                            }
                          },
                          tooltip: 'User',
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Content
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
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Trends'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
      // Admin only floating action button
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