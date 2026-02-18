import 'package:flutter/material.dart';

class FAQView extends StatefulWidget {
  const FAQView({super.key});

  @override
  State<FAQView> createState() => _FAQViewState();
}

class _FAQViewState extends State<FAQView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<FAQCategory> _categories = [
    FAQCategory(
      title: 'General',
      icon: Icons.info_outline,
      color: const Color(0xFF2563EB),
      questions: [
        FAQItem(
          question: 'What is Aquality?',
          answer:
              'Aquality is a water quality monitoring system for tilapia ponds. It uses Arduino-based sensors to measure key water parameters in real-time and helps you maintain optimal conditions for fish health.',
        ),
        FAQItem(
          question: 'How often is data updated?',
          answer:
              'The app refreshes data every 30 seconds automatically. You can also manually refresh by pulling down on the dashboard screen.',
        ),
        FAQItem(
          question: 'Can I use Aquality offline?',
          answer:
              'Aquality requires an internet connection to communicate with the Arduino sensors. However, historical data is cached locally for quick access.',
        ),
      ],
    ),
    FAQCategory(
      title: 'Parameters',
      icon: Icons.science,
      color: const Color(0xFF10B981),
      questions: [
        FAQItem(
          question: 'What is the ideal temperature for tilapia?',
          answer:
              'Tilapia thrive in water temperatures between 26-30°C (78-86°F). Temperatures outside this range can stress the fish and affect growth rates.',
        ),
        FAQItem(
          question: 'Why is pH level important?',
          answer:
              'pH measures water acidity/alkalinity. Tilapia prefer slightly alkaline water (pH 7-9). Extreme pH values can harm fish health and affect their ability to absorb nutrients.',
        ),
        FAQItem(
          question: 'What does dissolved oxygen (DO) mean?',
          answer:
              'Dissolved oxygen is the amount of oxygen available in water for fish to breathe. Tilapia need at least 5 mg/L, with 5-8 mg/L being optimal for healthy growth.',
        ),
        FAQItem(
          question: 'How dangerous is chlorine?',
          answer:
              'Chlorine is highly toxic to fish even at very low levels. Keep chlorine below 0.003 mg/L. If using tap water, let it sit for 24 hours or use a dechlorinator.',
        ),
        FAQItem(
          question: 'What is ammonia and why is it harmful?',
          answer:
              'Ammonia (NH₃) is a toxic waste product from fish metabolism and decomposing organic matter. Keep NH₃ below 0.02 mg/L to prevent fish stress, disease, and mortality.',
        ),
      ],
    ),
    FAQCategory(
      title: 'Alerts',
      icon: Icons.notifications,
      color: const Color(0xFFF59E0B),
      questions: [
        FAQItem(
          question: 'How do I know if there\'s a problem?',
          answer:
              'The app sends alerts when parameters go outside safe ranges. Critical alerts (red) require immediate action, warnings (yellow) need attention soon, and info alerts (blue) are for general updates.',
        ),
        FAQItem(
          question: 'Can I customize alert thresholds?',
          answer:
              'Currently, alert thresholds are set based on standard tilapia farming best practices. Custom threshold settings will be available in a future update.',
        ),
        FAQItem(
          question: 'How do I clear or dismiss alerts?',
          answer:
              'Alerts automatically clear when the parameter returns to the safe range. You can view all alerts history in the Alerts tab.',
        ),
      ],
    ),
    FAQCategory(
      title: 'Data & Export',
      icon: Icons.table_chart,
      color: const Color(0xFF8B5CF6),
      questions: [
        FAQItem(
          question: 'How far back can I view historical data?',
          answer:
              'Historical data is available for the past 30 days. You can filter by 24 hours, 7 days, 30 days, or select a custom date range in the History tab.',
        ),
        FAQItem(
          question: 'How do I export data? (Admin only)',
          answer:
              'Admin users can export data as CSV files from the History tab or Settings. The exported file includes all parameters with timestamps.',
        ),
        FAQItem(
          question: 'Where are exported files saved?',
          answer:
              'Exported CSV files are saved to your device\'s Documents/Aquality folder. You can access them through your file manager.',
        ),
      ],
    ),
    FAQCategory(
      title: 'Troubleshooting',
      icon: Icons.build,
      color: const Color(0xFFEF4444),
      questions: [
        FAQItem(
          question: 'The app shows "No data available"',
          answer:
              'This means the sensors are not sending data. Check if the Arduino device is powered on and connected to the internet. Verify all sensor connections.',
        ),
        FAQItem(
          question: 'Data seems inaccurate or frozen',
          answer:
              'Try refreshing the dashboard by pulling down. If data remains frozen, check the Arduino device status and sensor calibration.',
        ),
        FAQItem(
          question: 'Dark mode isn\'t working',
          answer:
              'Toggle dark mode from Settings > Appearance > Dark Mode. If it still doesn\'t work, try restarting the app.',
        ),
      ],
    ),
  ];

  List<FAQCategory> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    
    return _categories.map((category) {
      final filteredQuestions = category.questions.where((faq) {
        final query = _searchQuery.toLowerCase();
        return faq.question.toLowerCase().contains(query) ||
            faq.answer.toLowerCase().contains(query);
      }).toList();
      
      return FAQCategory(
        title: category.title,
        icon: category.icon,
        color: category.color,
        questions: filteredQuestions,
      );
    }).where((category) => category.questions.isNotEmpty).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & FAQ'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Search FAQ...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchCtrl.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.grey.shade800 : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // FAQ list
          Expanded(
            child: _filteredCategories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, categoryIndex) {
                      final category = _filteredCategories[categoryIndex];
                      return _buildCategorySection(category, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(FAQCategory category, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                category.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...category.questions.map((faq) => _buildFAQTile(faq, isDark)),
      ],
    );
  }

  Widget _buildFAQTile(FAQItem faq, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: ExpansionTileThemeData(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            iconColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            collapsedIconColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        child: ExpansionTile(
          title: Text(
            faq.question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          children: [
            Text(
              faq.answer,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FAQCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<FAQItem> questions;

  FAQCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.questions,
  });
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}
