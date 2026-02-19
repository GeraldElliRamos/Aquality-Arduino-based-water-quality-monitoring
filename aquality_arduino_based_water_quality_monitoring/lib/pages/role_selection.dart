import 'package:flutter/material.dart';

enum UserType { tilapiaFarmer, fishPondOwner, lgu }

class RoleSelectionView extends StatefulWidget {
  const RoleSelectionView({super.key});

  @override
  State<RoleSelectionView> createState() => _RoleSelectionViewState();
}

class _RoleSelectionViewState extends State<RoleSelectionView> {
  UserType? _selectedUserType;

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

  void _continue() {
    if (_selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your role to continue.'),
          backgroundColor: Color(0xFF2563EB),
        ),
      );
      return;
    }

    // Pass selected role to signup page
    Navigator.of(context).pushNamed('/signup', arguments: _selectedUserType);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Icon
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

            // Role options
            ...UserType.values.map((type) => _buildRadioOption(type, isDark)),

            const SizedBox(height: 32),

            // Continue button
            ElevatedButton(
              onPressed: _continue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // Back to login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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
              ? const Color(0xFF2563EB).withOpacity(isDark ? 0.2 : 0.08)
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
                    color: const Color(0xFF2563EB).withOpacity(0.12),
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
