import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'edit_admin_profile.dart';

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

    const primaryBlue = Color(0xFF2563EB);
    // Dynamic colors for dark mode support
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final subTextColor = isDark ? Colors.blueGrey.shade200 : Colors.grey;
    final mainTextColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Aquality Admin'),
        centerTitle: true,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(
                          Icons.account_circle,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nameController.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'System Administrator',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
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
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildBlueStat(
                        'Total Ponds',
                        '12',
                        Icons.water_drop,
                        primaryBlue,
                        cardBgColor,
                        mainTextColor,
                      ),
                      const SizedBox(width: 16),
                      _buildBlueStat(
                        'Active IoT',
                        '08',
                        Icons.router,
                        Colors.indigoAccent,
                        cardBgColor,
                        mainTextColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildBlueSectionHeader('Profile Details', subTextColor),
                  _buildBlueCard(
                    bgColor: cardBgColor,
                    children: [
                      _buildBlueTile(
                        Icons.alternate_email,
                        'Email Address',
                        _emailController.text,
                        primaryBlue,
                        subTextColor,
                        mainTextColor,
                      ),
                      Divider(
                        indent: 50,
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                      _buildBlueTile(
                        Icons.phone_android,
                        'Contact Number',
                        _phoneController.text,
                        primaryBlue,
                        subTextColor,
                        mainTextColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _buildBlueSectionHeader('Management Tools', subTextColor),
                  _buildBlueCard(
                    bgColor: cardBgColor,
                    children: [
                      _buildBlueAction(
                        context,
                        Icons.analytics_outlined,
                        'Analyze Water History',
                        '/history',
                        mainTextColor,
                      ),
                      Divider(
                        indent: 50,
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                      _buildBlueAction(
                        context,
                        Icons.settings_input_component,
                        'Sensor Thresholds',
                        '/thresholds',
                        mainTextColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        AuthService.logout();
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('LOGOUT SYSTEM'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            cardBgColor, // Changes to dark blue in night mode
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        side: const BorderSide(
                          color: Colors.redAccent,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlueSectionHeader(String title, Color textColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 10),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBlueStat(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlueCard({
    required List<Widget> children,
    required Color bgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildBlueTile(
    IconData icon,
    String label,
    String value,
    Color color,
    Color labelColor,
    Color valColor,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: TextStyle(fontSize: 11, color: labelColor)),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: valColor,
        ),
      ),
    );
  }

  Widget _buildBlueAction(
    BuildContext context,
    IconData icon,
    String title,
    String route,
    Color textColor,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent.withOpacity(0.7)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: () => Navigator.of(context).pushNamed(route),
    );
  }
}
