import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../widgets/dialogs.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) return 'Username is required';
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  void _navigateByRole() {
    final role = AuthService.userRole.value;
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
    setState(() => _isLoading = true);

    try {
      await AuthService.login(
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) {
        SuccessSnackBar.show(context, 'Welcome back!');
        _navigateByRole();
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

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.signInWithGoogle();
      if (mounted) {
        SuccessSnackBar.show(context, 'Welcome!');
        if (result.needsRoleSelection) {
          Navigator.of(context).pushReplacementNamed(
            '/role-selection',
            arguments: {
              'source': 'google',
              'isNewUser': result.isNewUser,
            },
          );
        } else {
          _navigateByRole();
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (e is AuthException) {
        ErrorSnackBar.show(context, e.message);
      } else {
        ErrorSnackBar.show(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _firebaseMessage(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return 'Login failed. Please check your credentials.';
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────
  void _showForgotPasswordDialog() {
    final resetCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSending = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> sendReset() async {
              final input = resetCtrl.text.trim();
              if (input.isEmpty) {
                ErrorSnackBar.show(
                    context, 'Please enter your username or email.');
                return;
              }
              setDialogState(() => isSending = true);
              try {
                final maskedEmail = await AuthService.resetPassword(input);
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                _showResetSuccessDialog(maskedEmail);
              } catch (e) {
                if (!mounted) return;
                final msg = e is AuthException
                    ? e.message
                    : 'Failed to send reset email. Try again.';
                ErrorSnackBar.show(context, msg);
              } finally {
                setDialogState(() => isSending = false);
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.lock_reset, color: Color(0xFF2563EB), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Reset Password',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Enter your username or email. We'll send a password reset link to your registered email.",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetCtrl,
                    enabled: !isSending,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => sendReset(),
                    decoration: InputDecoration(
                      labelText: 'Username or Email',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSending ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSending ? null : sendReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isSending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Send Reset Link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showResetSuccessDialog(String maskedEmail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_outlined,
                  color: Colors.green, size: 44),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reset Link Sent!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'A password reset link has been sent to\n$maskedEmail\n\nCheck your inbox and follow the instructions.',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Login'),
          titleTextStyle: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          centerTitle: true,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          shape: Border(
            bottom: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Transform.scale(
                  scale: 1.5,
                  child: SizedBox(
                    height: 80,
                    child: Image.asset(
                      'assets/images/AqualityLogoCrop.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue monitoring',
                  style: TextStyle(
                    color:
                        isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Username
                TextFormField(
                  controller: _userCtrl,
                  enabled: !_isLoading,
                  validator: _validateUsername,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passCtrl,
                  enabled: !_isLoading,
                  obscureText: _obscurePassword,
                  validator: _validatePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 8),

                // Forgot Password — now opens real dialog
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        _isLoading ? null : _showForgotPasswordDialog,
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 12),

                // Google Sign-In
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.login,
                      size: 20, color: Color(0xFF2563EB)),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context)
                              .pushNamed('/role-selection'),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
