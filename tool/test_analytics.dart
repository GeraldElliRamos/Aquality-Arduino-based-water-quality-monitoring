import 'dart:io';
import '../aquality_arduino_based_water_quality_monitoring/lib/utils/analytics.dart';

void main() {
  final buffer = <double>[];
  const bufferSize = 30;
  double prevEwma = 10.0;

  // Generate mock samples: stable readings, then a spike, then back
  final samples = <double>[];
  for (var i = 0; i < 25; i++) {
    samples.add(10.0 + (i % 3 == 0 ? 0.5 : -0.25));
  }
  samples.addAll([25.0, 26.0, 24.0, 10.2, 9.8, 9.9]);

  print('idx,sample,smoothed,isMAD,isCUSUM');
  for (var i = 0; i < samples.length; i++) {
    final s = samples[i];
    if (buffer.length >= bufferSize) buffer.removeAt(0);
    buffer.add(s);
    prevEwma = ewma(prevEwma, s, 0.2);
    final mad = isAnomalousMAD(buffer, prevEwma);
    final cs = cusumDetect(buffer, prevEwma);
    print('${i + 1},${s.toStringAsFixed(2)},${prevEwma.toStringAsFixed(3)},${mad ? 'Y' : 'N'},${cs ? 'Y' : 'N'}');
  }

  exit(0);
}
