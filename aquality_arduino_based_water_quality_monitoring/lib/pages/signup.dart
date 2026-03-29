import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../widgets/dialogs.dart';
import 'role_selection.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  UserType? _selectedUserType;
  bool _isGoogleSignup = false;
  bool _didInitArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is UserType) {
      _selectedUserType = args;
    } else if (args is Map<String, dynamic>) {
      final roleArg = args['selectedUserType'];
      if (roleArg is UserType) {
        _selectedUserType = roleArg;
      }

      _isGoogleSignup = args['isGoogleSignup'] == true;

      _nameCtrl.text = (args['prefillName'] as String? ?? '').trim();
      _emailCtrl.text = (args['prefillEmail'] as String? ?? '').trim();
      _userCtrl.text = (args['prefillUsername'] as String? ?? '').trim();
    }

    _didInitArgs = true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name is required';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Username is required';
    if (v.trim().length < 3) return 'Username must be at least 3 characters';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
      return 'Only letters, numbers, and underscores allowed';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (_isGoogleSignup) return null;
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'Password must contain an uppercase letter';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Password must contain a number';
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (_isGoogleSignup) return null;
    if (v != _passCtrl.text) return 'Passwords do not match';
    return null;
  }

  void _navigateByRole() {
    final role = _selectedUserType?.name ?? 'tilapiaFarmer';
    switch (role) {
      case 'fishPondOwner':
        Navigator.of(context).pushReplacementNamed('/app-owner');
        break;
      case 'lgu':
        Navigator.of(context).pushReplacementNamed('/app-lgu');
        break;
      default:
        Navigator.of(context).pushReplacementNamed('/app');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ErrorSnackBar.show(context, 'Please agree to the Terms and Conditions');
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isGoogleSignup) {
        await AuthService.completeGoogleSignupProfile(
          fullName: _nameCtrl.text.trim(),
          username: _userCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          userType: _selectedUserType?.name ?? 'tilapiaFarmer',
        );
      } else {
        await AuthService.signUp(
          fullName: _nameCtrl.text.trim(),
          username: _userCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          userType: _selectedUserType?.name ?? 'tilapiaFarmer',
        );
      }
      if (mounted) {
        SuccessSnackBar.show(
          context,
          _isGoogleSignup
              ? 'Google account profile completed!'
              : 'Account created successfully!',
        );
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    } catch (e) {
      if (!mounted) return;
      if (e is AuthException) {
        ErrorSnackBar.show(context, e.message);
      } else if (e is FirebaseAuthException) {
        ErrorSnackBar.show(context, _firebaseMessage(e.code));
      } else {
        ErrorSnackBar.show(context, 'An unexpected error occurred.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _firebaseMessage(String code) {
    switch (code) {
      case 'email-already-in-use': return 'An account with this email already exists.';
      case 'invalid-email': return 'The email address is not valid.';
      case 'weak-password': return 'Password is too weak. Please use a stronger one.';
      case 'operation-not-allowed': return 'Email/password accounts are not enabled.';
      default: return 'Sign up failed. Please try again.';
    }
  }

  String _roleLabel(UserType type) {
    switch (type) {
      case UserType.tilapiaFarmer: return 'Tilapia Farmer';
      case UserType.fishPondOwner: return 'Fish Pond Owner';
      case UserType.lgu: return 'LGU (Local Government Unit)';
    }
  }

  IconData _roleIcon(UserType type) {
    switch (type) {
      case UserType.tilapiaFarmer: return Icons.set_meal;
      case UserType.fishPondOwner: return Icons.water_damage;
      case UserType.lgu: return Icons.account_balance;
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
    );
  }

  InputDecoration _passwordDecoration({required String label, required bool obscure, required bool isDark, required VoidCallback onToggle}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
        onPressed: onToggle,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        titleTextStyle: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text('Create Account', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Join us to start monitoring', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (_selectedUserType != null)
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(isDark ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2563EB)),
                    ),
                    child: Row(
                      children: [
                        Icon(_roleIcon(_selectedUserType!), color: const Color(0xFF2563EB), size: 18),
                        const SizedBox(width: 8),
                        Text(_roleLabel(_selectedUserType!), style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600, fontSize: 14)),
                        const Spacer(),
                        const Text('Change', style: TextStyle(color: Color(0xFF2563EB), fontSize: 12)),
                        const Icon(Icons.chevron_right, color: Color(0xFF2563EB), size: 16),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              TextFormField(controller: _nameCtrl, enabled: !_isLoading, validator: _validateName, textInputAction: TextInputAction.next, decoration: _inputDecoration('Full Name', Icons.person_outline, isDark)),
              const SizedBox(height: 16),
              TextFormField(controller: _emailCtrl, enabled: !_isLoading, validator: _validateEmail, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: _inputDecoration('Email', Icons.email_outlined, isDark)),
              const SizedBox(height: 16),
              TextFormField(controller: _userCtrl, enabled: !_isLoading, validator: _validateUsername, textInputAction: TextInputAction.next, decoration: _inputDecoration('Username', Icons.alternate_email, isDark)),
              if (!_isGoogleSignup) ...[
                const SizedBox(height: 16),
                TextFormField(controller: _passCtrl, enabled: !_isLoading, obscureText: _obscurePassword, validator: _validatePassword, textInputAction: TextInputAction.next, decoration: _passwordDecoration(label: 'Password', obscure: _obscurePassword, isDark: isDark, onToggle: () => setState(() => _obscurePassword = !_obscurePassword))),
                const SizedBox(height: 16),
                TextFormField(controller: _confirmPassCtrl, enabled: !_isLoading, obscureText: _obscureConfirmPassword, validator: _validateConfirmPassword, textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _submit(), decoration: _passwordDecoration(label: 'Confirm Password', obscure: _obscureConfirmPassword, isDark: isDark, onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword))),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(value: _agreeToTerms, onChanged: _isLoading ? null : (v) => setState(() => _agreeToTerms = v ?? false), activeColor: const Color(0xFF2563EB)),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isLoading ? null : () => setState(() => _agreeToTerms = !_agreeToTerms),
                      child: Text('I agree to the Terms and Conditions', style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text(_isGoogleSignup ? 'Complete Google Sign Up' : 'Create Account', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                  TextButton(onPressed: _isLoading ? null : () => Navigator.of(context).pop(), child: const Text('Login')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}