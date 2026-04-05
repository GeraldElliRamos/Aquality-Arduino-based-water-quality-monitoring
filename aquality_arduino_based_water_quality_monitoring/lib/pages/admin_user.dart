import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'edit_admin_profile.dart';
import 'security_passwords.dart'; // Ensure this matches your file name

class AdminUserView extends StatefulWidget {
  const AdminUserView({super.key});

  @override
  State<AdminUserView> createState() => _AdminUserViewState();
}

class _AdminUserViewState extends State<AdminUserView> {
  final _nameController = TextEditingController(text: 'Admin User');
  final _emailController = TextEditingController(text: 'admin@aquality.com');
  final _phoneController = TextEditingController(text: '+63 912 345 6789');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Aquality Color Palette
    const primaryBlue = Color(0xFF2563EB);
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Admin Profile',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: textColor),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 1. Profile Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: primaryBlue.withOpacity(0.1),
                        child: const Icon(Icons.person, size: 50, color: primaryBlue),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        child: const Icon(Icons.verified, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nameController.text,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  Text(
                    'System Administrator',
                    style: TextStyle(color: subTextColor, fontSize: 14, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Stats Row
            Row(
              children: [
                _buildStatCard('Total Ponds', '12', Icons.water_drop, primaryBlue, cardBg, textColor, isDark),
                const SizedBox(width: 16),
                _buildStatCard('Active IoT', '08', Icons.router, Colors.indigoAccent, cardBg, textColor, isDark),
              ],
            ),

            const SizedBox(height: 24),

            // 3. Account Actions Card
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text('Account Actions', 
                  style: TextStyle(color: subTextColor, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _buildActionTile(
                    icon: Icons.edit_note_rounded,
                    title: 'Edit Profile Details',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditAdminProfileView(
                            initialName: _nameController.text,
                            initialEmail: _emailController.text,
                            initialPhone: _phoneController.text,
                            onSave: (name, email, phone) {
                              setState(() {
                                _nameController.text = name;
                                _emailController.text = email;
                                _phoneController.text = phone;
                              });
                            },
                          ),
                        ),
                      );
                    },
                    textColor: textColor,
                  ),
                  Divider(height: 1, indent: 60, color: isDark ? Colors.white10 : Colors.grey.shade100),
                  _buildActionTile(
                    icon: Icons.shield_outlined,
                    title: 'Security & Password',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SecuritySettingsPage()));
                    },
                    textColor: textColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Management Card
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text('Management Tools', 
                  style: TextStyle(color: subTextColor, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildActionTile(icon: Icons.analytics_outlined, title: 'Analyze Water History', onTap: () {}, textColor: textColor),
                  Divider(height: 1, indent: 60, color: isDark ? Colors.white10 : Colors.grey.shade100),
                  _buildActionTile(icon: Icons.settings_input_component, title: 'Sensor Thresholds', onTap: () {}, textColor: textColor),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 5. Logout Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: () {
                  AuthService.logout();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('LOGOUT SYSTEM', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildStatCard(String label, String value, IconData icon, Color color, Color bg, Color text, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: text)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({required IconData icon, required String title, required VoidCallback onTap, required Color textColor}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}