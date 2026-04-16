import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import './faq.dart';
import '../widgets/firestore_diagnostics.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final themeService = ThemeService();
  final languageService = LanguageService();
  final Color primaryBlue = const Color(0xFF2563EB);

  String t(String key) => languageService.t(key);

  @override
  void initState() {
    super.initState();
    languageService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() => setState(() {});

  void _showLanguagePicker() {
    final isDark = themeService.isDarkMode;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black45;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final currentCode = languageService.languageCode;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.language, color: primaryBlue, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        t('select_language'),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    languageService.isEnglish
                        ? 'Choose your preferred language'
                        : 'Piliin ang iyong gustong wika',
                    style: TextStyle(fontSize: 13, color: subColor),
                  ),
                  const SizedBox(height: 20),
                  _LanguageOption(
                    flag: '\u{1F1FA}\u{1F1F8}',
                    label: t('english'),
                    sublabel: 'English',
                    code: 'en',
                    isSelected: currentCode == 'en',
                    isDark: isDark,
                    primaryBlue: primaryBlue,
                    onTap: () async {
                      await languageService.setLanguage('en');
                      setSheetState(() {});
                      if (ctx.mounted) Navigator.pop(ctx);
                      _showLanguageChangedSnackBar('English');
                    },
                  ),
                  const SizedBox(height: 10),
                  _LanguageOption(
                    flag: '\u{1F1F5}\u{1F1ED}',
                    label: t('tagalog'),
                    sublabel: 'Filipino / Tagalog',
                    code: 'tl',
                    isSelected: currentCode == 'tl',
                    isDark: isDark,
                    primaryBlue: primaryBlue,
                    onTap: () async {
                      await languageService.setLanguage('tl');
                      setSheetState(() {});
                      if (ctx.mounted) Navigator.pop(ctx);
                      _showLanguageChangedSnackBar('Tagalog');
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        t('cancel'),
                        style: TextStyle(color: subColor, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLanguageChangedSnackBar(String langName) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('${t('language_changed')} $langName'),
          ],
        ),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeService.isDarkMode;
    final Color bgColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);
    final Color cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subHeaderColor = isDark ? Colors.white54 : Colors.black45;

    final currentLangLabel =
        languageService.isTagalog ? 'Tagalog' : 'English';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          t('settings'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        leading: BackButton(color: textColor),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(t('aquaculture_management'), subHeaderColor),
              _buildGroupedCard(cardColor, [
                _buildSettingRow(
                  icon: Icons.waves,
                  title: t('pond_configurations'),
                  isDark: isDark,
                  textColor: textColor,
                  onTap: () {},
                ),
                _buildDivider(isDark),
                _buildSettingRow(
                  icon: Icons.notifications_active_outlined,
                  title: t('alert_thresholds'),
                  isDark: isDark,
                  textColor: textColor,
                  onTap: () {},
                ),
                _buildDivider(isDark),
                _buildSettingRow(
                  icon: Icons.sensors,
                  title: t('sensor_calibration'),
                  isDark: isDark,
                  textColor: textColor,
                  onTap: () {},
                ),
              ]),

              const SizedBox(height: 25),

              _buildSectionHeader(t('app_preferences'), subHeaderColor),
              _buildGroupedCard(cardColor, [
                _buildSettingRow(
                  icon: Icons.language,
                  title: t('language'),
                  isDark: isDark,
                  textColor: textColor,
                  value: currentLangLabel,
                  onTap: _showLanguagePicker,
                ),
                _buildDivider(isDark),
                _buildSettingRow(
                  icon: Icons.palette_outlined,
                  title: t('appearance'),
                  isDark: isDark,
                  textColor: textColor,
                  trailing: Switch.adaptive(
                    value: isDark,
                    activeTrackColor: primaryBlue,
                    onChanged: (_) =>
                        setState(() => themeService.toggleTheme()),
                  ),
                ),
              ]),

              const SizedBox(height: 25),

              _buildSectionHeader(t('support'), subHeaderColor),
              _buildGroupedCard(cardColor, [
                _buildSettingRow(
                  icon: Icons.help_outline,
                  title: t('faq_help'),
                  isDark: isDark,
                  textColor: textColor,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FAQView()),
                  ),
                ),
                _buildDivider(isDark),
                _buildSettingRow(
                  icon: Icons.info_outline,
                  title: t('about'),
                  isDark: isDark,
                  textColor: textColor,
                ),
                _buildDivider(isDark),
                _buildSettingRow(
                  icon: Icons.settings_input_antenna,
                  title: 'Firestore Diagnostics',
                  isDark: isDark,
                  textColor: textColor,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FirestoreDiagnostics()),
                  ),
                ),
                _buildDivider(isDark),
                _buildSettingRow(
                  icon: Icons.logout,
                  title: t('logout'),
                  isDark: isDark,
                  textColor: Colors.redAccent,
                  iconColor: Colors.redAccent,
                  showChevron: false,
                  onTap: () {
                    AuthService.logout();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                ),
              ]),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGroupedCard(Color color, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 54,
      thickness: 0.5,
      color: isDark ? Colors.white10 : Colors.black12,
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required bool isDark,
    required Color textColor,
    Color? iconColor,
    String? value,
    Widget? trailing,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    // Build the default trailing (value label + chevron)
    final defaultTrailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value != null)
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.grey,
              fontSize: 14,
            ),
          ),
        if (showChevron) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
        ],
      ],
    );

    // Use InkWell instead of ListTile so the whole row — including the
    // trailing area — reliably fires onTap. ListTile blocks its own onTap
    // whenever an interactive widget (Switch, etc.) is in the trailing slot.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? (isDark ? Colors.white70 : Colors.black54),
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              trailing ?? defaultTrailing,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Language option tile ─────────────────────────────────────────────────────

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String label;
  final String sublabel;
  final String code;
  final bool isSelected;
  final bool isDark;
  final Color primaryBlue;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.sublabel,
    required this.code,
    required this.isSelected,
    required this.isDark,
    required this.primaryBlue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? primaryBlue : (isDark ? Colors.white12 : Colors.black12);
    final bgColor = isSelected
        ? primaryBlue.withValues(alpha: isDark ? 0.18 : 0.07)
        : Colors.transparent;
    final labelColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black45;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Icon(Icons.check_circle, color: primaryBlue, size: 22,
                      key: const ValueKey('checked'))
                  : Icon(Icons.circle_outlined,
                      color: isDark ? Colors.white24 : Colors.black12,
                      size: 22,
                      key: const ValueKey('unchecked')),
            ),
          ],
        ),
      ),
    );
  }
}