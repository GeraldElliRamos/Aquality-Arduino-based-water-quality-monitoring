import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import './edit_profile.dart';

class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  final _nameController  = TextEditingController(text: 'User Name');
  final _emailController = TextEditingController(text: 'user@example.com');
  final _phoneController = TextEditingController(text: '');
  String _userRole     = '';
  String _memberSince  = 'Jan 2026';
  bool   _isLoadingProfile = true;
  final  _lang = LanguageService();

  String t(String key) => _lang.t(key);

  @override
  void initState() {
    super.initState();
    _lang.addListener(_onLangChanged);
    _loadProfile();
  }

  @override
  void dispose() {
    _lang.removeListener(_onLangChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onLangChanged() => setState(() {});

  Future<void> _loadProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final profile = await AuthService.getCurrentUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _nameController.text  = profile['fullName'] ?? 'User Name';
          _emailController.text = profile['email']    ?? 'user@example.com';
          _phoneController.text = profile['phone']    ?? '';
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
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[month - 1];
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'tilapiaFarmer':  return t('tilapia_farmer');
      case 'fishPondOwner':  return t('fish_pond_owner');
      case 'lgu':            return t('lgu_member');
      default:               return t('user');
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'tilapiaFarmer': return Icons.set_meal;
      case 'fishPondOwner': return Icons.water_damage;
      case 'lgu':           return Icons.account_balance;
      default:              return Icons.person;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'tilapiaFarmer': return const Color(0xFF16A34A);
      case 'fishPondOwner': return const Color(0xFF2563EB);
      case 'lgu':           return const Color(0xFF9333EA);
      default:              return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final roleColor  = _roleColor(_userRole);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 220,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: roleColor,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [roleColor, roleColor.withBlue(200)],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white24, shape: BoxShape.circle),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.person, size: 50, color: roleColor),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white38),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_roleIcon(_userRole), size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    _roleLabel(_userRole).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white, fontSize: 11,
                                      fontWeight: FontWeight.bold, letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildModernCard(
                            title: t('personal_information'),
                            children: [
                              _buildInfoTile(Icons.person_outline,  t('full_name'),     _nameController.text,  roleColor),
                              _buildInfoTile(Icons.email_outlined,  t('email_address'), _emailController.text, roleColor),
                              if (_phoneController.text.isNotEmpty)
                                _buildInfoTile(Icons.phone_outlined, t('phone_number'), _phoneController.text, roleColor),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _buildModernCard(
                            title: t('activity_insights'),
                            children: [
                              _buildStatRow(t('member_since'),   _memberSince),
                              const Divider(height: 24),
                              _buildStatRow(t('total_readings'), '1,234'),
                              const Divider(height: 24),
                              _buildStatRow(t('active_ponds'),   '1'),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _buildModernCard(
                            title: t('account_actions'),
                            children: [
                              _buildActionTile(
                                context,
                                icon: Icons.edit_note_rounded,
                                title: t('edit_profile'),
                                color: const Color(0xFF2563EB),
                                onTap: () => _navigateToEdit(context),
                              ),
                              _buildActionTile(
                                context,
                                icon: Icons.security_rounded,
                                title: t('security_password'),
                                color: const Color(0xFF6366F1),
                                onTap: () {},
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () async {
                                await AuthService.logout();
                                if (context.mounted) {
                                  Navigator.of(context).pushReplacementNamed('/login');
                                }
                              },
                              icon: const Icon(Icons.logout_rounded, color: Colors.red),
                              label: Text(
                                t('logout_system'),
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileView(
          initialName:  _nameController.text,
          initialEmail: _emailController.text,
          initialPhone: _phoneController.text,
          onSave: (name, email, phone) {
            setState(() {
              _nameController.text  = name;
              _emailController.text = email;
              _phoneController.text = phone;
            });
          },
        ),
      ),
    );
  }

  Widget _buildModernCard({required String title, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade400)),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context,
      {required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}