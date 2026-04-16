import 'package:flutter/material.dart';
import '../services/language_service.dart';

class EditAdminProfileView extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final Function(String name, String email, String phone) onSave;

  const EditAdminProfileView({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    required this.onSave,
  });

  @override
  State<EditAdminProfileView> createState() => _EditAdminProfileViewState();
}

class _EditAdminProfileViewState extends State<EditAdminProfileView> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final languageService = LanguageService();

  String t(String key) => languageService.t(key);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _showConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('confirm_changes')),
        content: Text(t('are_you_sure_save')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
            child: Text(t('confirm')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onSave(
        _nameController.text,
        _emailController.text,
        _phoneController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('profile_updated'))),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blueColor = const Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(t('edit_admin_profile')),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Admin Shield Icon with Edit Badge
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: blueColor.withOpacity(0.1),
                    child: Icon(Icons.shield_rounded, size: 55, color: blueColor),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: blueColor,
                      child: const Icon(Icons.edit, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Unified Information Card (Screenshot Style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInlineField(
                      controller: _nameController,
                      label: 'Admin Full Name',
                      icon: Icons.badge_outlined,
                      isDark: isDark,
                      showDivider: true,
                    ),
                    _buildInlineField(
                      controller: _emailController,
                      label: 'Official Email',
                      icon: Icons.mark_email_read_outlined,
                      isDark: isDark,
                      showDivider: true,
                    ),
                    _buildInlineField(
                      controller: _phoneController,
                      label: 'Direct Contact Number',
                      icon: Icons.support_agent_outlined,
                      isDark: isDark,
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Primary Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _showConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'SAVE CHANGES',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                t('cancel'),
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required bool showDivider,
  }) {
    final blueColor = const Color(0xFF2563EB);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: controller,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              prefixIcon: Icon(icon, color: blueColor, size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 60,
            endIndent: 20,
            color: isDark ? Colors.white10 : Colors.grey.shade100,
          ),
      ],
    );
  }
}