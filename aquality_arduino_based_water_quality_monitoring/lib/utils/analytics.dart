import 'dart:math';


class RollingBuffer {
  final int capacity;
  final List<double> _buf = [];
  RollingBuffer(this.capacity);

  void add(double v) {
    _buf.add(v);
    if (_buf.length > capacity) _buf.removeAt(0);
  }

  List<double> get items => List.unmodifiable(_buf);

  bool get isEmpty => _buf.isEmpty;
}

/// Exponential weighted moving average
double ewma(double prev, double value, double alpha) => alpha * value + (1 - alpha) * prev;

double movingAverage(List<double> window) => window.isEmpty ? 0 : window.reduce((a, b) => a + b) / window.length;

/// Median Absolute Deviation based anomaly detection.
/// Returns true if `value` is an outlier compared to `window` using modified z-score.
bool isAnomalousMAD(List<double> window, double value, {double thresh = 3.5}) {
  if (window.isEmpty) return false;
  final w = List.of(window)..sort();
  final mid = (w.length / 2).floor();
  final median = w[mid];
  final deviations = w.map((v) => (v - median).abs()).toList()..sort();
  final mad = deviations[(deviations.length / 2).floor()];
  if (mad == 0) return (value - median).abs() > thresh;
  final modifiedZ = 0.6745 * (value - median) / mad;
  return modifiedZ.abs() > thresh;
}

/// Simple CUSUM detector. Returns true on detection.
bool cusumDetect(List<double> window, double value, {double k = 0.5, double h = 5.0}) {
  double sPos = 0, sNeg = 0;
  final all = [...window, value];
  final mean = all.isEmpty ? value : all.reduce((a, b) => a + b) / all.length;
  for (final x in all) {
    sPos = max(0, sPos + x - mean - k);
    sNeg = max(0, sNeg - x + mean - k);
    if (sPos > h || sNeg > h) return true;
  }
  return false;
}
