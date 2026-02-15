import 'package:flutter/material.dart';

class InfoTooltip extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? iconColor;
  final double iconSize;

  const InfoTooltip({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.iconColor,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Tooltip(
      message: message,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        height: 1.4,
      ),
      preferBelow: true,
      verticalOffset: 16,
      waitDuration: const Duration(milliseconds: 200),
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor ?? defaultColor,
      ),
    );
  }
}

class HelpIcon extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onTap;

  const HelpIcon({
    super.key,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap ??
          () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Help'),
                content: Text(tooltip),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Got it'),
                  ),
                ],
              ),
            );
          },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.blue.shade900.withOpacity(0.3)
              : Colors.blue.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.help_outline,
          size: 16,
          color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
        ),
      ),
    );
  }
}
