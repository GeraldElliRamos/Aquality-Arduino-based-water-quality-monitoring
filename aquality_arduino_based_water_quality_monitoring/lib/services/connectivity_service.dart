import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Service to monitor network connectivity status
class ConnectivityService {
  static final ConnectivityService _instance =
      ConnectivityService._internal();

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier(true);
  final ValueNotifier<String> connectionTypeNotifier =
      ValueNotifier('unknown');

  /// Initialize connectivity monitoring
  Future<void> init() async {
    try {
      // Check initial connectivity
      await _updateConnectivity();

      // Listen for connectivity changes
      _connectivity.onConnectivityChanged.listen((result) async {
        await _updateConnectivity();
      });
    } catch (e) {
      debugPrint('Connectivity service init error: $e');
    }
  }

  /// Update connectivity status
  Future<void> _updateConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      
      final isOnline = result != ConnectivityResult.none;
      final connectionType = _getConnectionTypeString(result);
      
      isOnlineNotifier.value = isOnline;
      connectionTypeNotifier.value = connectionType;
      
      if (isOnline) {
        debugPrint('✓ Online ($connectionType)');
      } else {
        debugPrint('✗ Offline');
      }
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }
  }

  /// Get human-readable connection type string
  String _getConnectionTypeString(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.mobile:
        return 'Mobile';
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'None';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
    }
  }

  /// Check if device is currently online
  bool get isOnline => isOnlineNotifier.value;

  /// Get current connection type
  String get connectionType => connectionTypeNotifier.value;

  /// Dispose resources
  void dispose() {
    isOnlineNotifier.dispose();
    connectionTypeNotifier.dispose();
  }
}
