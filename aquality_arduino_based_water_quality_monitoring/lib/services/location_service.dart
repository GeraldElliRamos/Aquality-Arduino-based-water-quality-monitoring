import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';

/// Service to handle location permissions and coordinates
class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  /// Get current user location with permission handling
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled.');
        return null;
      }
      debugPrint('✅ Location services enabled');

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('   Current permission: $permission');

      if (permission == LocationPermission.denied) {
        // Request permission if not granted
        debugPrint('   Requesting location permission...');
        permission = await Geolocator.requestPermission();
        debugPrint('   Permission result: $permission');
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permissions are denied by user.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permissions are permanently denied.');
        // User can enable in settings
        await Geolocator.openLocationSettings();
        return null;
      }

      // Get current position
      debugPrint('   Fetching position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      debugPrint('✅ Location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      return null;
    }
  }

  /// Stream of position updates for real-time location tracking.
  /// `distanceFilter` is in meters — set to an appropriate value to avoid
  /// frequent updates (default 50m).
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.best,
    int distanceFilter = 50,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Get location with high accuracy (for one-time fetch)
  Future<Position?> getHighAccuracyLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      return position;
    } catch (e) {
      debugPrint('Error getting high accuracy location: $e');
      return null;
    }
  }

  /// Get location name (city, country) from coordinates
  Future<String> getLocationName(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.administrativeArea ?? 'Unknown';
        final country = place.country ?? 'Unknown';
        return '$city, $country';
      }
      return 'Unknown Location';
    } catch (e) {
      debugPrint('Error getting location name: $e');
      return 'Location Unknown';
    }
  }

  /// Check if location permission is granted
  Future<bool> isLocationPermissionGranted() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Get distance between two coordinates in meters
  double getDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
