import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

class ExportService {
  static Future<String> exportToCSV() async {
    // Mock data - in production this would come from a database
    final data = _generateMockData();
    
    // Convert to CSV
    String csv = const ListToCsvConverter().convert(data);
    
    // Get the directory to save the file
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/aquality_readings_${DateTime.now().millisecondsSinceEpoch}.csv';
    
    // Write the file
    final file = File(path);
    await file.writeAsString(csv);
    
    return path;
  }

  static List<List<dynamic>> _generateMockData() {
    final now = DateTime.now();
    final headers = ['Timestamp', 'Temperature (°C)', 'pH Level', 'Chlorine (mg/L)', 'Dissolved Oxygen (mg/L)', 'Ammonia (mg/L)', 'Status'];
    
    final rows = <List<dynamic>>[headers];
    
    // Generate 100 mock readings
    for (int i = 0; i < 100; i++) {
      final timestamp = now.subtract(Duration(hours: i));
      rows.add([
        timestamp.toIso8601String(),
        (28 + (i % 3) * 0.5).toStringAsFixed(2),
        (6.8 + (i % 5) * 0.05).toStringAsFixed(2),
        (0.008 + (i % 4) * 0.001).toStringAsFixed(3),
        (6.2 + (i % 6) * 0.2).toStringAsFixed(2),
        (0.15 + (i % 7) * 0.02).toStringAsFixed(3),
        i % 10 == 0 ? 'Warning' : 'Optimal',
      ]);
    }
    
    return rows;
  }

  static Future<void> shareCSV(String filePath) async {
    // In production, use share_plus package to share the file
    // For now, this is a placeholder
    throw UnimplementedError('Share functionality requires share_plus package');
  }
}
