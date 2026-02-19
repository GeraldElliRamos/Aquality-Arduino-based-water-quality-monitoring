import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';

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
    final isAdmin = AuthService.isAdmin.value;
    
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final Color iconBg = isDark ? primaryBlue.withOpacity(0.15) : const Color(0xFFE0F7FF);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: textColor),
        centerTitle: true,
        title: Text('Profile', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.more_horiz, color: textColor)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// 👤 PROFILE HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 38,
                    backgroundColor: Color(0xFF2563EB),
                    child: Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAdmin ? 'Admin User' : 'Standard User',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        Text(
                          'admin@profile.com',
                          style: TextStyle(color: subTextColor, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// 🔵 EDIT PROFILE BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(isAdmin ? '/admin-user' : '/user');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// 🛠 SETTINGS LIST
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
              icon: Icons.language_rounded,
              title: 'Language',
              value: 'English',
              isDark: isDark,
              iconBg: iconBg,
            ),

            _buildRow(
              icon: Icons.logout_rounded,
              title: 'Log out',
              isDark: isDark,
              iconBg: isDark ? Colors.red.withOpacity(0.1) : const Color(0xFFFFEBEE),
              iconColor: Colors.redAccent,
              onTap: () async {
                 AuthService.logout();
                 Navigator.of(context).pushReplacementNamed('/login');
              },
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