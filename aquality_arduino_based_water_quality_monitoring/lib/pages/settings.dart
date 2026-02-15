import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import '../services/export_service.dart';
import '../widgets/dialogs.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final themeService = ThemeService();

  @override
  Widget build(BuildContext context) {
    final isDark = themeService.isDarkMode;
    final isAdmin = AuthService.isAdmin.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            title: 'Appearance',
            children: [
              _buildSwitchTile(
                context,
                icon: isDark ? Icons.dark_mode : Icons.light_mode,
                title: 'Dark Mode',
                subtitle: 'Toggle dark theme',
                value: isDark,
                onChanged: (value) {
                  setState(() {
                    themeService.toggleTheme();
                  });
                },
              ),
            ],
          ),
          _buildSection(
            context,
            title: 'Notifications',
            children: [
              _buildSwitchTile(
                context,
                icon: Icons.notifications_active,
                title: 'Push Notifications',
                subtitle: 'Receive alerts for critical parameters',
                value: true,
                onChanged: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications feature coming soon')),
                  );
                },
              ),
              _buildSwitchTile(
                context,
                icon: Icons.email,
                title: 'Email Alerts',
                subtitle: 'Get email for daily summaries',
                value: false,
                onChanged: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email alerts feature coming soon')),
                  );
                },
              ),
            ],
          ),
          _buildSection(
            context,
            title: 'Data',
            children: [
              if (isAdmin)
                _buildTile(
                  context,
                  icon: Icons.download,
                  title: 'Export Data',
                  subtitle: 'Download readings as CSV',
                  onTap: () async {
                    try {
                      InfoSnackBar.show(context, 'Exporting data...');
                      
                      final path = await ExportService.exportToCSV();
                      
                      if (context.mounted) {
                        SuccessSnackBar.show(
                          context,
                          'Data exported to ${path.split('/').last}',
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ErrorSnackBar.show(context, 'Export failed: $e');
                      }
                    }
                  },
                ),
              _buildTile(
                context,
                icon: Icons.refresh,
                title: 'Auto Refresh',
                subtitle: 'Every 30 seconds',
                trailing: const Text('30s', style: TextStyle(color: Colors.grey)),
                onTap: () {},
              ),
            ],
          ),
          _buildSection(
            context,
            title: 'Account',
            children: [
              _buildTile(
                context,
                icon: Icons.person,
                title: 'Profile',
                subtitle: 'Edit your profile information',
                onTap: () {
                  Navigator.of(context).pushNamed(isAdmin ? '/admin-user' : '/user');
                },
              ),
              _buildTile(
                context,
                icon: Icons.lock,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password change coming soon')),
                  );
                },
              ),
            ],
          ),
          _buildSection(
            context,
            title: 'About',
            children: [
              _buildTile(
                context,
                icon: Icons.info,
                title: 'App Version',
                subtitle: 'v1.0.0',
                onTap: () {},
              ),
              _buildTile(
                context,
                icon: Icons.help,
                title: 'Help & FAQ',
                subtitle: 'Frequently asked questions',
                onTap: () {
                  Navigator.of(context).pushNamed('/faq');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await ConfirmDialog.show(
                  context,
                  title: 'Logout',
                  message: 'Are you sure you want to logout?',
                  confirmText: 'Logout',
                  isDangerous: true,
                );
                if (confirmed && context.mounted) {
                  AuthService.logout();
                  Navigator.of(context).pushReplacementNamed('/login');
                  SuccessSnackBar.show(context, 'Logged out successfully');
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade900
                : Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF2563EB),
      ),
    );
  }
}
