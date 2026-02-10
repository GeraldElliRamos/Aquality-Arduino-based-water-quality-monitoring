import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    // short delay to show splash, then route based on auth state
    Timer(const Duration(milliseconds: 900), _finish);
  }

  void _finish() {
    if (AuthService.isLoggedIn.value) {
      if (AuthService.isAdmin.value) {
        Navigator.of(context).pushReplacementNamed('/admin');
      } else {
        Navigator.of(context).pushReplacementNamed('/app');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE6F0FF), Color(0xFFE6FFFB)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.dashboard, size: 72, color: Color(0xFF2563EB)),
              SizedBox(height: 12),
              Text('Aquality', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('Tilapia Pond Monitor', style: TextStyle(fontSize: 14, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
