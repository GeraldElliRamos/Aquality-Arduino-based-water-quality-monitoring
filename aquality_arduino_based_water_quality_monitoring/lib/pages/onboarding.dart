import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserType { tilapiaFarmer, fishPondOwner, lgu }

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  UserType? _selectedUserType;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.water_drop,
      title: 'Welcome to Aquality',
      description:
          'Monitor your tilapia pond water quality in real-time with precision sensors.',
      color: const Color(0xFF2563EB),
    ),
    OnboardingPage(
      icon: Icons.show_chart,
      title: 'Track Trends',
      description:
          'View historical data and trends to understand your pond\'s health patterns.',
      color: const Color(0xFF10B981),
    ),
    OnboardingPage(
      icon: Icons.notifications_active,
      title: 'Get Alerts',
      description:
          'Receive instant notifications when water parameters go outside safe ranges.',
      color: const Color(0xFFF59E0B),
    ),
    OnboardingPage(
      icon: Icons.analytics,
      title: 'Detailed Insights',
      description:
          'Tap any parameter card to see detailed statistics, charts, and recent readings.',
      color: const Color(0xFF8B5CF6),
    ),
    OnboardingPage(
      icon: Icons.settings,
      title: 'Customize Settings',
      description:
          'Switch between light and dark themes, export data, and manage your profile.',
      color: const Color(0xFF6366F1),
    ),
  ];

  // Total pages = info pages + 1 user type page
  int get _totalPages => _pages.length + 1;
  bool get _isLastPage => _currentPage == _totalPages - 1;
  bool get _isUserTypePage => _currentPage == _pages.length;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_isUserTypePage && _selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your role to continue.'),
          backgroundColor: Color(0xFF2563EB),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (_selectedUserType != null) {
      await prefs.setString('user_type', _selectedUserType!.name);
    }

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (hidden on user type page)
            Align(
              alignment: Alignment.topRight,
              child: _isUserTypePage
                  ? const SizedBox(height: 48)
                  : TextButton(
                      onPressed: () {
                        // Skip straight to the user type page
                        _pageController.animateToPage(
                          _pages.length,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalPages,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  if (index < _pages.length) {
                    return _buildPage(_pages[index]);
                  } else {
                    return _buildUserTypePage(isDark);
                  }
                },
              ),
            ),

            // Indicator dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFF2563EB)
                          : (isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_isLastPage) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isLastPage ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 64, color: page.color),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypePage(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Who are you?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your role so we can personalize your experience.',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ...UserType.values.map((type) => _buildRadioOption(type, isDark)),
        ],
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
              : (isDark ? const Color(0xFF1E2A3A) : Colors.white),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _userTypeIcon(type),
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                size: 20,
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

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
