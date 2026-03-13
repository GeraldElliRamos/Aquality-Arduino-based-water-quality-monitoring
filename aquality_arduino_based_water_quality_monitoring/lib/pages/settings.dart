import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import './faq.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final themeService = ThemeService();
  final Color primaryBlue = const Color(0xFF2563EB); // Your requested Blue

  @override
  Widget build(BuildContext context) {
    final isDark = themeService.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;
    final Color iconBg = isDark ? primaryBlue.withOpacity(0.15) : const Color(0xFFE0F7FF);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        title: const Text('Settings'),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: BackButton(color: textColor),
        centerTitle: false,
        shape: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildRow(
              icon: Icons.location_on_outlined,
              title: 'My addresses',
              isDark: isDark,
              iconBg: iconBg,
            ),
            _buildRow(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              isDark: isDark,
              iconBg: iconBg,
            ),
            _buildRow(
              icon: Icons.settings_outlined,
              title: 'Scan settings',
              isDark: isDark,
              iconBg: iconBg,
            ),
            
            // DARK MODE TOGGLE (FUNCTIONAL)
            _buildRow(
              icon: isDark ? Icons.dark_mode : Icons.light_mode_outlined,
              title: 'Dark Mode',
              isDark: isDark,
              iconBg: iconBg,
              trailing: Switch.adaptive(
                value: isDark,
                activeColor: primaryBlue,
                onChanged: (v) {
                  setState(() {
                    themeService.toggleTheme();
                  });
                },
              ),
            ),

            _buildRow(
              icon: Icons.help_outline,
              title: 'FAQ',
              isDark: isDark,
              iconBg: iconBg,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FAQView(),
                ),
              ),
            ),

            _buildRow(
              icon: Icons.language_rounded,
              title: 'Language',
              value: 'English',
              isDark: isDark,
              iconBg: iconBg,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String title,
    required bool isDark,
    required Color iconBg,
    Color? iconColor,
    String? value,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      onTap: onTap ?? () {},
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor ?? primaryBlue, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      trailing: trailing ?? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(value, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey, fontSize: 15)),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded, 
            size: 14, 
            color: isDark ? Colors.white30 : Colors.black26),
        ],
      ),
    );
  }
}