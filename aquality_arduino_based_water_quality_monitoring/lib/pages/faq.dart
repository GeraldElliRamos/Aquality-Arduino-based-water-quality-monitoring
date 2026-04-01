import 'package:flutter/material.dart';
import '../services/language_service.dart';

class FAQView extends StatefulWidget {
  const FAQView({super.key});

  @override
  State<FAQView> createState() => _FAQViewState();
}

class _FAQViewState extends State<FAQView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  final _lang = LanguageService();

  String t(String key) => _lang.t(key);

  @override
  void initState() {
    super.initState();
    _lang.addListener(_onLangChanged);
  }

  @override
  void dispose() {
    _lang.removeListener(_onLangChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onLangChanged() => setState(() {});

  List<FAQCategory> get _categories => [
        FAQCategory(
          title: t('faq_general'),
          icon: Icons.info_outline,
          color: const Color(0xFF2563EB),
          questions: [
            FAQItem(question: t('faq_q_what_is'),     answer: t('faq_a_what_is')),
            FAQItem(question: t('faq_q_update_freq'), answer: t('faq_a_update_freq')),
            FAQItem(question: t('faq_q_offline'),     answer: t('faq_a_offline')),
          ],
        ),
        FAQCategory(
          title: t('faq_parameters'),
          icon: Icons.science,
          color: const Color(0xFF10B981),
          questions: [
            FAQItem(question: t('faq_q_temp'),     answer: t('faq_a_temp')),
            FAQItem(question: t('faq_q_ph'),        answer: t('faq_a_ph')),
            FAQItem(question: t('faq_q_turbidity'), answer: t('faq_a_turbidity')),
            FAQItem(question: t('faq_q_ammonia'),   answer: t('faq_a_ammonia')),
            FAQItem(question: t('faq_q_ammonia2'),  answer: t('faq_a_ammonia2')),
          ],
        ),
        FAQCategory(
          title: t('faq_alerts'),
          icon: Icons.notifications,
          color: const Color(0xFFF59E0B),
          questions: [
            FAQItem(question: t('faq_q_problem'),   answer: t('faq_a_problem')),
            FAQItem(question: t('faq_q_customize'), answer: t('faq_a_customize')),
            FAQItem(question: t('faq_q_clear'),     answer: t('faq_a_clear')),
          ],
        ),
        FAQCategory(
          title: t('faq_data'),
          icon: Icons.table_chart,
          color: const Color(0xFF8B5CF6),
          questions: [
            FAQItem(question: t('faq_q_history'), answer: t('faq_a_history')),
            FAQItem(question: t('faq_q_export'),  answer: t('faq_a_export')),
            FAQItem(question: t('faq_q_files'),   answer: t('faq_a_files')),
          ],
        ),
        FAQCategory(
          title: t('faq_troubleshoot'),
          icon: Icons.build,
          color: const Color(0xFFEF4444),
          questions: [
            FAQItem(question: t('faq_q_no_data'), answer: t('faq_a_no_data')),
            FAQItem(question: t('faq_q_frozen'),  answer: t('faq_a_frozen')),
            FAQItem(question: t('faq_q_dark'),    answer: t('faq_a_dark')),
          ],
        ),
      ];

  List<FAQCategory> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    return _categories.map((category) {
      final filtered = category.questions.where((faq) {
        final q = _searchQuery.toLowerCase();
        return faq.question.toLowerCase().contains(q) ||
            faq.answer.toLowerCase().contains(q);
      }).toList();
      return FAQCategory(
        title: category.title,
        icon: category.icon,
        color: category.color,
        questions: filtered,
      );
    }).where((c) => c.questions.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('faq_title')),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: t('search_faq'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _searchCtrl.clear();
                          _searchQuery = '';
                        }),
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
          Expanded(
            child: _filteredCategories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 64,
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(t('no_results'),
                            style: TextStyle(
                              fontSize: 18,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                            )),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, i) =>
                        _buildCategorySection(_filteredCategories[i], isDark),
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
                child: Icon(category.icon, color: category.color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(category.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
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
          title: Text(faq.question,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          children: [
            Text(faq.answer,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                )),
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
  FAQCategory({required this.title, required this.icon, required this.color, required this.questions});
}

class FAQItem {
  final String question;
  final String answer;
  FAQItem({required this.question, required this.answer});
}