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
  final Color primaryBlue = const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final isDark = themeService.isDarkMode;
    final Color bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);
    final Color cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subHeaderColor = isDark ? Colors.white54 : Colors.black45;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        leading: BackButton(color: textColor),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('AQUACULTURE MANAGEMENT', subHeaderColor),
              _buildGroupedCard(cardColor, [
                _buildSettingRow(
                  icon: Icons.waves,
                  title: 'Pond Configurations',
                  isDark: isDark,
                  textColor: textColor,
                  onTap: () {},
                ),
                _buildDivider(isDark),
                _buildSettingRow(
                  icon: Icons.notifications_active_outlined,
                  title: 'Alert Thresholds',
                  isDark: isDark,
                  textColor: textColor,
                  onTap: () {},
                ),
                _buildDivider(isDark),
                _buildSettingRow(
                  icon: Icons.sensors,
                  title: 'Sensor Calibration',
                  isDark: isDark,
                  textColor: textColor,
                  onTap: () {},
                ),
              ]),

              const SizedBox(height: 25),

              _buildSectionHeader('APP PREFERENCES', subHeaderColor),
              _buildGroupedCard(cardColor, [
                _buildSettingRow(
                  icon: Icons.language,
                  title: 'Language',
                  isDark: isDark,
                  textColor: textColor,
                  value: 'English',
                ),
                _buildDivider(isDark),
                _buildSettingRow(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  isDark: isDark,
                  textColor: textColor,
                  trailing: Switch.adaptive(
                    value: isDark,
                    activeColor: primaryBlue,
                    onChanged: (v) => setState(() => themeService.toggleTheme()),
                  ),
                ),
              ]),

              const SizedBox(height: 25),

              _buildSectionHeader('SUPPORT', subHeaderColor),
              _buildGroupedCard(cardColor, [
                _buildSettingRow(
                  icon: Icons.help_outline,
                  title: 'FAQ / Help Center',
                  isDark: isDark,
                  textColor: textColor,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FAQView()),
                  ),
                ),
                _buildDivider(isDark),
                _buildSettingRow(
                  icon: Icons.info_outline,
                  title: 'About Aquality v1.0',
                  isDark: isDark,
                  textColor: textColor,
                ),
                _buildDivider(isDark),
                _buildSettingRow(
                  icon: Icons.logout,
                  title: 'Logout',
                  isDark: isDark,
                  textColor: Colors.redAccent,
                  iconColor: Colors.redAccent,
                  showChevron: false,
                  onTap: () {
                    AuthService.logout();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                ),
              ]),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildGroupedCard(Color color, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 54,
      thickness: 0.5,
      color: isDark ? Colors.white10 : Colors.black12,
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required bool isDark,
    required Color textColor,
    Color? iconColor,
    String? value,
    Widget? trailing,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap ?? () {},
      dense: true,
      leading: Icon(icon, color: iconColor ?? (isDark ? Colors.white70 : Colors.black54), size: 22),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w400),
      ),
      trailing: trailing ?? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(value, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 15)),
          if (showChevron) ...[
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.white24 : Colors.black26),
          ],
        ],
      ),
    );
  }
}