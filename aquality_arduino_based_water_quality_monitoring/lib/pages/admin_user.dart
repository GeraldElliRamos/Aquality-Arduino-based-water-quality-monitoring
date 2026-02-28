import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AdminUserView extends StatefulWidget {
  const AdminUserView({super.key});

  @override
  State<AdminUserView> createState() => _AdminUserViewState();
}

class _AdminUserViewState extends State<AdminUserView> {
  final _nameController = TextEditingController(text: 'Admin User');
  final _emailController = TextEditingController(text: 'admin@aquality.com');
  final _phoneController = TextEditingController(text: '+1 234 567 8900');
  bool _isEditing = false;

  // Branding colors stay constant
  final Color primaryBlue = const Color(0xFF1E40AF);
  final Color accentBlue = const Color(0xFF3B82F6);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('System Overview'),
                  const SizedBox(height: 12),
                  _buildStatsGrid(isDark),
                  const SizedBox(height: 32),
                  _buildSectionLabel('Administrative Profile'),
                  const SizedBox(height: 12),
                  _buildProfileCard(isDark),
                  const SizedBox(height: 32),
                  _buildSectionLabel('Quick Actions'),
                  const SizedBox(height: 12),
                  _buildActionsList(isDark),
                  const SizedBox(height: 40),
                  _buildLogoutButton(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryBlue,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryBlue, accentBlue],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.shield_rounded, size: 45, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'SYSTEM ADMINISTRATOR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isEditing ? Icons.check_circle : Icons.edit, color: Colors.white),
          onPressed: () {
            setState(() => _isEditing = !_isEditing);
            if (!_isEditing) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.blueGrey.shade400,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.1,
      children: [
        _buildCompactStat('45', 'Total Users', Icons.people_alt_rounded, Colors.blue, isDark),
        _buildCompactStat('12', 'Active Nodes', Icons.router_rounded, Colors.green, isDark),
        _buildCompactStat('15.2k', 'Readings', Icons.bar_chart_rounded, Colors.orange, isDark),
        _buildCompactStat('99.9%', 'Uptime', Icons.bolt_rounded, Colors.purple, isDark),
      ],
    );
  }

  Widget _buildCompactStat(String value, String label, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade400,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: color.withOpacity(0.7), size: 22),
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInlineField(_nameController, 'Full Name', Icons.person_outline, isDark),
          Divider(height: 32, thickness: 0.5, color: Theme.of(context).dividerColor),
          _buildInlineField(_emailController, 'Email', Icons.mail_outline, isDark),
          Divider(height: 32, thickness: 0.5, color: Theme.of(context).dividerColor),
          _buildInlineField(_phoneController, 'Phone', Icons.smartphone_outlined, isDark),
        ],
      ),
    );
  }

  Widget _buildInlineField(TextEditingController controller, String label, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: accentBlue),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              TextField(
                controller: controller,
                enabled: _isEditing,
                style: TextStyle(
                  fontSize: 15, 
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.only(top: 4),
                  border: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsList(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildActionTile(Icons.admin_panel_settings_outlined, 'Admin Dashboard', '/admin'),
          Divider(height: 1, indent: 16, endIndent: 16, color: Theme.of(context).dividerColor),
          _buildActionTile(Icons.settings_outlined, 'System Settings', '/settings'),
          Divider(height: 1, indent: 16, endIndent: 16, color: Theme.of(context).dividerColor),
          _buildActionTile(Icons.lock_reset_rounded, 'Security & Password', null),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String? route) {
    return ListTile(
      leading: Icon(icon, size: 22, color: accentBlue.withOpacity(0.8)),
      title: Text(
        title, 
        style: TextStyle(
          fontSize: 14, 
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        )
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () {
        if (route != null) {
          Navigator.pushNamed(context, route);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon')));
        }
      },
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () {
          AuthService.logout();
          Navigator.of(context).pushReplacementNamed('/login');
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        label: const Text(
          'SIGN OUT OF SESSION',
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800, letterSpacing: 1.1),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.red.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}