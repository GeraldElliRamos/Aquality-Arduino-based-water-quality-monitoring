import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import './edit_profile.dart';

class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  final _nameController = TextEditingController(text: 'User Name');
  final _emailController = TextEditingController(text: 'user@example.com');
  final _phoneController = TextEditingController(text: '+1 234 567 8900');
  String _userRole = '';
  String _memberSince = 'Jan 2026';
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final profile = await AuthService.getCurrentUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _nameController.text = profile['fullName'] ?? 'User Name';
          _emailController.text = profile['email'] ?? 'user@example.com';
          _phoneController.text = profile['phone'] ?? '';
          _userRole = profile['userType'] ?? '';
          final createdAt = profile['createdAt'];
          if (createdAt != null) {
            final dt = createdAt.toDate();
            _memberSince = '${_monthName(dt.month)} ${dt.year}';
          }
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingProfile = false);
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'tilapiaFarmer':
        return 'Tilapia Farmer';
      case 'fishPondOwner':
        return 'Fish Pond Owner';
      case 'lgu':
        return 'LGU (Local Government Unit)';
      default:
        return 'User';
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'tilapiaFarmer':
        return Icons.set_meal;
      case 'fishPondOwner':
        return Icons.water_damage;
      case 'lgu':
        return Icons.account_balance;
      default:
        return Icons.person;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'tilapiaFarmer':
        return const Color(0xFF16A34A);
      case 'fishPondOwner':
        return const Color(0xFF2563EB);
      case 'lgu':
        return const Color(0xFF9333EA);
      default:
        return Colors.grey;
    }
  }

  Future<void> _onRefresh() async {
    await _loadProfile();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile refreshed')));
    }
  }

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
    final textColor = isDark ? Colors.white : Colors.black;
    final roleColor = _roleColor(_userRole);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
      body: _isLoadingProfile
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : RefreshIndicator(
              onRefresh: _onRefresh,
              color: const Color(0xFF2563EB),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Avatar + Role Badge
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: roleColor, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _roleIcon(_userRole),
                                size: 14,
                                color: roleColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _roleLabel(_userRole),
                                style: TextStyle(
                                  color: roleColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Info
                  _buildInfoCard(
                    children: [
                      _buildPlainText(
                        label: 'Full Name',
                        value: _nameController.text,
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildPlainText(
                        label: 'Email',
                        value: _emailController.text,
                        icon: Icons.email_outlined,
                      ),
                      if (_phoneController.text.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildPlainText(
                          label: 'Phone',
                          value: _phoneController.text,
                          icon: Icons.phone_outlined,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Account Statistics
                  _buildInfoCard(
                    title: 'Account Statistics',
                    children: [
                      _buildStatRow('Member Since', _memberSince),
                      const Divider(height: 24),
                      _buildStatRow('Total Readings', '1,234'),
                      const Divider(height: 24),
                      _buildStatRow('Active Devices', '1'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Actions
                  _buildInfoCard(
                    title: 'Quick Actions',
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF2563EB),
                        ),
                        title: const Text('Edit Profile'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EditProfileView(
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
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF2563EB),
                        ),
                        title: const Text('Change Password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password change coming soon'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Logout
                  ElevatedButton.icon(
                    onPressed: () async {
                      await AuthService.logout();
                      if (mounted) {
                        Navigator.of(context).pushReplacementNamed('/login');
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
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({String? title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _buildPlainText({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
