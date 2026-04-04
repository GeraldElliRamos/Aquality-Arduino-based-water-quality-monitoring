import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  // These controllers are essential to avoid 'undefined' errors
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

  // This helper method fixes the '_showSnack' red errors
  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: color, 
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
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

    setState(() => _isUpdating = true);
    try {
      // Connects to Firebase re-authentication logic in AuthService
      await AuthService.updateUserPassword(
        _currentPasswordController.text, 
        _newPasswordController.text
      );
      
      if (mounted) {
        _showSnack("Password updated successfully!", Colors.green);
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString(), Colors.red);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detect system brightness
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Adaptive Theme Colors
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    const accentBlue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Security & Password', 
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Premium Card Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  _buildAdaptiveField(_currentPasswordController, 'Current Password', Icons.lock_outline, isDark),
                  const SizedBox(height: 20),
                  _buildAdaptiveField(_newPasswordController, 'New Password', Icons.vpn_key_outlined, isDark),
                  const SizedBox(height: 20),
                  _buildAdaptiveField(_confirmPasswordController, 'Confirm Password', Icons.check_circle_outline, isDark),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Updated Premium Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _handleUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isUpdating 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('UPDATE PASSWORD', 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdaptiveField(TextEditingController ctrl, String label, IconData icon, bool isDark) {
    return TextField(
      controller: ctrl,
      obscureText: _isObscure,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
        suffixIcon: IconButton(
          icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, 
            color: isDark ? Colors.white38 : Colors.black26),
          onPressed: () => setState(() => _isObscure = !_isObscure),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
      ),
    );
  }
}