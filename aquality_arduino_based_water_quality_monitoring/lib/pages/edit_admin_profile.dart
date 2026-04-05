import 'package:flutter/material.dart';

/// Edit Admin Profile Screen
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
        title: const Text('Confirm Changes'),
        content: const Text('Are you sure you want to save your changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
            ),
            child: const Text('Confirm'),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Admin Profile'),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                child: const Icon(Icons.shield, size: 60, color: Color(0xFF2563EB)),
              ),
            ),
            const SizedBox(height: 32),
            _buildEditableTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildEditableTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            _buildEditableTextField(
              controller: _phoneController,
              label: 'Phone',
              icon: Icons.phone_outlined,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showConfirmationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

