import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

enum UserType { tilapiaFarmer, fishPondOwner, lgu }

class RoleSelectionView extends StatefulWidget {
  const RoleSelectionView({super.key});

  @override
  State<RoleSelectionView> createState() => _RoleSelectionViewState();
}

class _RoleSelectionViewState extends State<RoleSelectionView> {
  UserType? _selectedUserType;
  bool _isSaving = false;
  bool _isFromGoogle = false;
  bool _isGoogleNewUser = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _isFromGoogle = args['source'] == 'google';
      _isGoogleNewUser = args['isNewUser'] == true;
    } else {
      _isFromGoogle = args == 'google';
      _isGoogleNewUser = _isFromGoogle;
    }
  }

  String _userTypeLabel(UserType type) {
    switch (type) {
      case UserType.tilapiaFarmer:
        return 'Tilapia Farmer';
      case UserType.fishPondOwner:
        return 'Fish Pond Owner';
      case UserType.lgu:
        return 'LGU (Local Government Unit)';
    }
  }

  String _userTypeDescription(UserType type) {
    switch (type) {
      case UserType.tilapiaFarmer:
        return 'I raise tilapia and want to monitor my farming conditions.';
      case UserType.fishPondOwner:
        return 'I own a fish pond and want to track water quality.';
      case UserType.lgu:
        return 'I represent a local government unit overseeing aquaculture.';
    }
  }

  IconData _userTypeIcon(UserType type) {
    switch (type) {
      case UserType.tilapiaFarmer:
        return Icons.set_meal;
      case UserType.fishPondOwner:
        return Icons.water_damage;
      case UserType.lgu:
        return Icons.account_balance;
    }
  }

  String _userTypeValue(UserType type) {
    switch (type) {
      case UserType.tilapiaFarmer:
        return 'tilapiaFarmer';
      case UserType.fishPondOwner:
        return 'fishPondOwner';
      case UserType.lgu:
        return 'lgu';
    }
  }

  void _navigateByRole(String role) {
    String route;
    switch (role) {
      case 'fishPondOwner':
        route = '/app-owner';
        break;
      case 'lgu':
        route = '/app-lgu';
        break;
      default:
        route = '/app';
    }
    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }

  Future<void> _continue() async {
    if (_selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your role to continue.'),
          backgroundColor: Color(0xFF2563EB),
        ),
      );
      return;
    }

    if (_isFromGoogle) {
      setState(() => _isSaving = true);
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final roleValue = _userTypeValue(_selectedUserType!);

          if (_isGoogleNewUser) {
            final user = FirebaseAuth.instance.currentUser;
            final fallbackEmail = user?.email?.trim().toLowerCase() ?? '';
            final prefillUsername = fallbackEmail.isNotEmpty
                ? fallbackEmail.split('@').first
                : '';

            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/signup', arguments: {
                'selectedUserType': _selectedUserType,
                'isGoogleSignup': true,
                'prefillName': user?.displayName ?? '',
                'prefillEmail': fallbackEmail,
                'prefillUsername': prefillUsername,
              });
            }
          } else {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .set({'userType': roleValue}, SetOptions(merge: true));
            AuthService.userRole.value = roleValue;
            if (mounted) _navigateByRole(roleValue);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving role: $e')));
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    } else {
      Navigator.of(context).pushNamed('/signup', arguments: _selectedUserType);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
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
        automaticallyImplyLeading: !_isFromGoogle,
        shape: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.people_alt_outlined,
                color: Colors.white,
                size: 40,
              ),
            ),
            Text(
              'Who are you?',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Select your role so we can personalize\nyour Aquality experience.',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ...UserType.values.map((type) => _buildRadioOption(type, isDark)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _continue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            if (!_isFromGoogle)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Login'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(UserType type, bool isDark) {
    final isSelected = _selectedUserType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedUserType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.08)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _userTypeIcon(type),
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userTypeLabel(type),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF2563EB) : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _userTypeDescription(type),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Radio<UserType>(
              value: type,
              groupValue: _selectedUserType,
              onChanged: (val) => setState(() => _selectedUserType = val),
              activeColor: const Color(0xFF2563EB),
            ),
          ],
        ),
      ),
    );
  }
}

