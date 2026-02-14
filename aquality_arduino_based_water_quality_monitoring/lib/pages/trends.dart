import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class TrendsView extends StatefulWidget {
  const TrendsView({super.key});
  @override
  State<TrendsView> createState() => _TrendsViewState();
}

class _TrendsViewState extends State<TrendsView> {
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

  @override
  void initState() {
    super.initState();
    iotService = PlaceholderIoTService();
    _sub = iotService.readings().listen((r) {
      setState(() {
        final list = sampleData.putIfAbsent(r.param, () => []);
        list.add(r.value);
        if (list.length > 30) list.removeAt(0);
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              SizedBox(height: 220, child: CustomPaint(painter: LineChartPainter(points: points, lineColor: color), child: Container(padding: const EdgeInsets.all(8)))),
              const SizedBox(height: 12),
              Row(children: [
                _summaryBox('Current', points.isNotEmpty ? _format(points.last) : '-', background: Colors.blue.shade50),
                const SizedBox(width: 8),
                _summaryBox('Average', points.isNotEmpty ? _format(_avg(points)) : '-', background: Colors.grey.shade50),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                _summaryBox('Minimum', points.isNotEmpty ? _format(_min(points)) : '-', background: Colors.cyan.shade50),
                const SizedBox(width: 8),
                _summaryBox('Maximum', points.isNotEmpty ? _format(_max(points)) : '-', background: Colors.orange.shade50),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _summaryBox(String label, String value, {required Color background}) {
    return Expanded(
      child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ])),
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

  String _format(num v) {
    if (v is double) return v.toStringAsFixed(v >= 10 ? 1 : 2);
    return v.toString();
  }

  double _avg(List<double> list) => list.isEmpty ? 0 : list.reduce((a, b) => a + b) / list.length;
  double _min(List<double> list) => list.isEmpty ? 0 : list.reduce((a, b) => a < b ? a : b);
  double _max(List<double> list) => list.isEmpty ? 0 : list.reduce((a, b) => a > b ? a : b);
}

class LineChartPainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;
  LineChartPainter({required this.points, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()..color = Colors.grey.shade200..strokeWidth = 1;
    final paintLine = Paint()..color = lineColor..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final paintFill = Paint()..color = lineColor.withOpacity(0.06);
    final paintDot = Paint()..color = lineColor;

    final int gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final y = size.height * i / gridLines;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    if (points.isEmpty) return;

    final minV = points.reduce((a, b) => a < b ? a : b);
    final maxV = points.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);

    final stepX = points.length > 1 ? size.width / (points.length - 1) : 0.0;
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final dx = i * stepX;
      final normalized = (points[i] - minV) / range;
      final dy = size.height - (normalized * size.height);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    final fillPath = Path.from(path)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    for (int i = 0; i < points.length; i++) {
      final dx = i * stepX;
      final normalized = (points[i] - minV) / range;
      final dy = size.height - (normalized * size.height);
      canvas.drawCircle(Offset(dx, dy), 3.5, paintDot);
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor;
  }
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
