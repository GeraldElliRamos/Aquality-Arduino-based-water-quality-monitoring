import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AdminView extends StatelessWidget {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthService.isAdmin,
      builder: (context, isAdmin, _) {
        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Admin Panel'), backgroundColor: const Color(0xFF2563EB)),
            body: const Center(child: Text('Access denied. Admins only.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Panel'),
            backgroundColor: const Color(0xFF2563EB),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  AuthService.logout();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                tooltip: 'Logout',
              ),
            ],
          ),
          body: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Admin Controls', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('Placeholder for admin features: user management, device settings, logs.'),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Performing admin action')));
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Run admin task'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
