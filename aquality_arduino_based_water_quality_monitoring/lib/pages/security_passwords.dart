import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isObscure = true;
  bool _isUpdating = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _handleUpdate() async {
    if (_currentPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      _showSnack("Please fill in all fields", Colors.orange);
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnack("New passwords do not match", Colors.red);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Update'),
        content: const Text('Are you sure you want to update your password?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isUpdating = true);
      try {
        await AuthService.updateUserPassword(
          _currentPasswordController.text, 
          _newPasswordController.text
        );
        
        if (mounted) {
          _showSnack("Success! Password updated in Firebase.", Colors.green);
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.pop(context); 
        }
      } catch (e) {
        if (mounted) {
          _showSnack("Update Failed: ${e.toString()}", Colors.red);
        }
      } finally {
        if (mounted) setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security & Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildField(_currentPasswordController, 'Current Password'),
            const SizedBox(height: 16),
            _buildField(_newPasswordController, 'New Password'),
            const SizedBox(height: 16),
            _buildField(_confirmPasswordController, 'Confirm New Password'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _handleUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 15)
                ),
                child: _isUpdating 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      obscureText: _isObscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _isObscure = !_isObscure),
        ),
      ),
    );
  }
}