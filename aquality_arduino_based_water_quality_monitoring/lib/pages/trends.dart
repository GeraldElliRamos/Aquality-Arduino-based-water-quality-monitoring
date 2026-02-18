import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'parameter_detail.dart';
// ignore_for_file: unused_import

class TrendsView extends StatefulWidget {
  const TrendsView({super.key});
  @override
  State<TrendsView> createState() => _TrendsViewState();
}

class _TrendsViewState extends State<TrendsView> with SingleTickerProviderStateMixin {
  String _range = '24h';
  String _selectedParam = 'pH Level';

  final Map<String, List<double>> sampleData = {
    'Temperature': [],
    'pH Level': [],
    'Chlorine': [],
    'Dissolved Oxygen': [],
    'Ammonia': [],
  };

  late final IoTDataService iotService;
  StreamSubscription<IoTReading>? _sub;
  late AnimationController _animationController;

  // Debounce: batch rapid stream events, redraw at most every 500 ms
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();

    iotService = PlaceholderIoTService();
    _sub = iotService.readings().listen((r) {
      // Update data buffer immediately (no rebuild yet)
      final list = sampleData.putIfAbsent(r.param, () => []);
      list.add(r.value);
      if (list.length > 30) list.removeAt(0);

      // Coalesce redraws: only rebuild once per 500 ms
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _sub?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = sampleData[_selectedParam] ?? [];
    final color = _paramColor(_selectedParam);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Parameter Trends', style: TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: ['24h', '7d', '30d'].map((r) {
                  final selected = r == _range;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _range = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF2563EB) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: selected ? Colors.transparent : Colors.grey.shade300),
                        ),
                        child: Text(r, style: TextStyle(color: selected ? Colors.white : Colors.black87)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Temperature', 'pH Level', 'Chlorine', 'Dissolved Oxygen', 'Ammonia']
                .map((p) => GestureDetector(
                      onTap: () => setState(() => _selectedParam = p),
                      child: Container(
                        width: (MediaQuery.of(context).size.width - 72) / 2,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        decoration: BoxDecoration(
                          color: _selectedParam == p ? _paramColor(p).withOpacity(0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _selectedParam == p ? _paramColor(p) : Colors.grey.shade200),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(p, style: TextStyle(fontWeight: FontWeight.w600, color: _selectedParam == p ? _paramColor(p) : Colors.black87)),
                        ]),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(children: [
                      SizedBox(
                        height: 220,
                        child: points.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.show_chart, size: 48, color: Colors.grey.shade300),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Waiting for data...',
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                    ),
                                  ],
                                ),
                              )
                            : Semantics(
                                button: true,
                                label: 'Trends chart for $_selectedParam. Double tap to open details.',
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    final meta = _paramMeta(_selectedParam);
                                    final latest = points.isNotEmpty ? points.last.toString() : '0';
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ParameterDetailView(
                                          title: _selectedParam,
                                          value: latest,
                                          unit: meta['unit'] as String,
                                          range: meta['range'] as String,
                                          icon: meta['icon'] as IconData,
                                          color: meta['color'] as Color,
                                        ),
                                      ),
                                    );
                                  },
                                  // RepaintBoundary isolates chart repaints from the rest of the tree
                                  child: RepaintBoundary(
                                    child: AnimatedBuilder(
                                      animation: _animationController,
                                      builder: (context, child) {
                                        return LineChart(
                                          _buildChartData(points, color),
                                          duration: const Duration(milliseconds: 300),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                      ),
              const SizedBox(height: 16),
              Row(children: [
                _summaryBox('Current', points.isNotEmpty ? _format(points.last) : '-', background: Colors.blue.shade50, icon: Icons.show_chart),
                const SizedBox(width: 8),
                _summaryBox('Average', points.isNotEmpty ? _format(_avg(points)) : '-', background: Colors.grey.shade50, icon: Icons.analytics_outlined),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                _summaryBox('Minimum', points.isNotEmpty ? _format(_min(points)) : '-', background: Colors.cyan.shade50, icon: Icons.arrow_downward),
                const SizedBox(width: 8),
                _summaryBox('Maximum', points.isNotEmpty ? _format(_max(points)) : '-', background: Colors.orange.shade50, icon: Icons.arrow_upward),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(List<double> points, Color lineColor) {
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i]));
    }

    final minY = points.isEmpty ? 0.0 : _min(points);
    final maxY = points.isEmpty ? 10.0 : _max(points);
    final range = maxY - minY;
    final padding = range * 0.1;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY - minY) / 4,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: points.length > 10 ? (points.length / 5).floorToDouble() : 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= points.length || value < 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${value.toInt() + 1}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: (maxY - minY) / 4,
            getTitlesWidget: (value, meta) {
              return Text(
                _format(value),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      minX: 0,
      maxX: points.length > 1 ? (points.length - 1).toDouble() : 10,
      minY: minY - padding,
      maxY: maxY + padding,
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => lineColor.withOpacity(0.9),
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${_format(spot.y)}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: 'Reading ${spot.x.toInt() + 1}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
        getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: lineColor.withOpacity(0.5),
                strokeWidth: 2,
                dashArray: [5, 5],
              ),
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: lineColor,
                  );
                },
              ),
            );
          }).toList();
        },
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: lineColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: lineColor,
                strokeWidth: 0,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                lineColor.withOpacity(0.15),
                lineColor.withOpacity(0.05),
                lineColor.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryBox(String label, String value, {required Color background, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? background.withOpacity(0.08) : background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Color _paramColor(String p) {
    switch (p) {
      case 'Temperature':
        return Colors.orange;
      case 'pH Level':
        return Colors.purple;
      case 'Chlorine':
        return Colors.amber.shade700;
      case 'Dissolved Oxygen':
        return Colors.blue;
      case 'Ammonia':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Map<String, Object> _paramMeta(String p) {
    switch (p) {
      case 'Temperature':
        return {'unit': '°C', 'range': '27-30°C', 'icon': Icons.thermostat, 'color': Colors.orange};
      case 'pH Level':
        return {'unit': '', 'range': '6.5-9.0', 'icon': Icons.water_drop, 'color': Colors.purple};
      case 'Chlorine':
        return {'unit': 'mg/L', 'range': '<0.02 mg/L', 'icon': Icons.warning_amber_rounded, 'color': Colors.amber.shade700};
      case 'Dissolved Oxygen':
        return {'unit': 'mg/L', 'range': '>5 mg/L', 'icon': Icons.air, 'color': Colors.blue};
      case 'Ammonia':
        return {'unit': 'mg/L', 'range': '<0.3 mg/L', 'icon': Icons.waves, 'color': Colors.green};
      default:
        return {'unit': '', 'range': '-', 'icon': Icons.show_chart, 'color': Colors.blue};
    }
  }

  String _format(num v) {
    if (v is double) return v.toStringAsFixed(v >= 10 ? 1 : 2);
    return v.toString();
  }

  double _avg(List<double> list) => list.isEmpty ? 0 : list.reduce((a, b) => a + b) / list.length;
  double _min(List<double> list) => list.isEmpty ? 0 : list.reduce((a, b) => a < b ? a : b);
  double _max(List<double> list) => list.isEmpty ? 0 : list.reduce((a, b) => a > b ? a : b);
}


class IoTReading {
  final String param;
  final double value;
  final DateTime timestamp;
  IoTReading({required this.param, required this.value, DateTime? timestamp}) : timestamp = timestamp ?? DateTime.now();
}

abstract class IoTDataService {
  Stream<IoTReading> readings();
}

class PlaceholderIoTService implements IoTDataService {
  final _rnd = Random();

  @override
  Stream<IoTReading> readings() {
    // Emit a reading every 800ms with varying params and realistic ranges
    const params = ['Temperature', 'pH Level', 'Chlorine', 'Dissolved Oxygen', 'Ammonia'];
    return Stream<IoTReading>.periodic(const Duration(milliseconds: 800), (_) {
      final p = params[_rnd.nextInt(params.length)];
      double value;
      switch (p) {
        case 'Temperature':
          value = 24 + _rnd.nextDouble() * 6 - 3; // around 24-30 +/- small noise
          break;
        case 'pH Level':
          value = 6.5 + _rnd.nextDouble() * 1.5 - 0.25; // 6.25-8-ish
          break;
        case 'Chlorine':
          value = _rnd.nextDouble() * 2.0; // 0-2
          break;
        case 'Dissolved Oxygen':
          value = 5 + _rnd.nextDouble() * 6; // 5-11
          break;
        case 'Ammonia':
          value = _rnd.nextDouble() * 1.5; // 0-1.5
          break;
        default:
          value = _rnd.nextDouble() * 10;
      }
      return IoTReading(param: p, value: double.parse(value.toStringAsFixed(2)));
    });
  }
}
