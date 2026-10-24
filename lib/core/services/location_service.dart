import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Device location helper: asks for permission when needed and returns the
/// current position, or null when location is off/denied/unavailable.
class LocationService {
  /// Requests location permission if it has not been decided yet.
  static Future<bool> ensurePermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Location permission notice: $e');
      return false;
    }
  }

  static Future<Position?> currentPosition({Duration timeout = const Duration(seconds: 12)}) async {
    try {
      if (!await ensurePermission()) return null;
      if (!await Geolocator.isLocationServiceEnabled()) {
        return await Geolocator.getLastKnownPosition();
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high, timeLimit: timeout),
      );
    } catch (e) {
      debugPrint('Current location unavailable, trying last known: $e');
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }
}
