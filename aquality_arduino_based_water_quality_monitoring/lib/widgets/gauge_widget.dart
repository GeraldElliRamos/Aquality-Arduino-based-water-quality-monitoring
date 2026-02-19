import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/format_utils.dart';

/// Reusable gauge widget showing parameter status with circular progress
class GaugeWidget extends StatefulWidget {
  final String title;
  final double value;
  final double minSafe;
  final double maxSafe;
  final String unit;
  final String status;
  final Color statusColor;
  final Color gaugeColor;
  final VoidCallback? onTap;

  const GaugeWidget({
    super.key,
    required this.title,
    required this.value,
    required this.minSafe,
    required this.maxSafe,
    required this.unit,
    required this.status,
    required this.statusColor,
    required this.gaugeColor,
    this.onTap,
  });

  @override
  State<GaugeWidget> createState() => _GaugeWidgetState();
}

class _GaugeWidgetState extends State<GaugeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: _calculateProgress()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(GaugeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: _animation.value, end: _calculateProgress())
          .animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  double _calculateProgress() {
    final range = widget.maxSafe - widget.minSafe;
    if (range <= 0) return 0;

    if (widget.value < widget.minSafe) {
      return max(0, ((widget.value - (widget.minSafe - range * 0.2)) / (range * 1.4)));
    } else if (widget.value > widget.maxSafe) {
      return min(1, ((widget.value - widget.minSafe) / (range * 1.4)));
    } else {
      return ((widget.value - widget.minSafe) / range);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.grey.shade700
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              width: 120,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: GaugePainter(
                      progress: _animation.value,
                      color: widget.gaugeColor,
                      backgroundColor: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade200,
                      statusColor: widget.statusColor,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            FormatUtils.formatParamValue(widget.value),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.unit,
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
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.statusColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                widget.status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.statusColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Range: ${FormatUtils.formatRange(widget.minSafe, widget.maxSafe)}',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for gauge visualization
class GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final Color statusColor;

  GaugePainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.statusColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    // Background gauge
    paint.color = backgroundColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi,
      pi,
      false,
      paint,
    );

    // Progress gauge
    paint.color = statusColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi,
      pi * progress,
      false,
      paint,
    );

    // Center circle
    paint
      ..style = PaintingStyle.fill
      ..color = statusColor.withOpacity(0.1);
    canvas.drawCircle(center, radius - 10, paint);
  }

  @override
  bool shouldRepaint(GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.statusColor != statusColor;
  }
}
