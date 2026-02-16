import 'dart:ui';
import 'package:geolocator/geolocator.dart';

class LocationService {

  // পারমিশন চেক করার হেল্পার
  bool _isPermissionEnable(LocationPermission locationPermission) {
    return locationPermission == LocationPermission.whileInUse ||
        locationPermission == LocationPermission.always;
  }

  // পারমিশন এবং GPS হ্যান্ডেল করা
  Future<bool> handleLocationPermission({VoidCallback? onSuccess}) async {
    final LocationPermission locationPermission = await Geolocator.checkPermission();

    if (_isPermissionEnable(locationPermission)) {
      final bool isGpsEnabled = await Geolocator.isLocationServiceEnabled();
      if (isGpsEnabled) {
        onSuccess?.call();
        return true;
      } else {
        await Geolocator.openLocationSettings();
      }
    } else {
      final LocationPermission permission = await Geolocator.requestPermission();
      if (_isPermissionEnable(permission)) {
        return await handleLocationPermission(onSuccess: onSuccess);
      }
    }
    return false;
  }

  // রিয়েল টাইম লোকেশন স্ট্রিম পাওয়ার মেথড
  Stream<Position> getRealTimeLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3, // প্রতি ৩ মিটার মুভমেন্টে ডাটা দিবে
      ),
    );
  }
}