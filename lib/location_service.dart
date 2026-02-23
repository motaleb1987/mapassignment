import 'dart:ui';
import 'package:geolocator/geolocator.dart';

class LocationService {

  // Location permission check
  bool _isPermissionEnable(LocationPermission locationPermission) {
    return locationPermission == LocationPermission.whileInUse ||
        locationPermission == LocationPermission.always;
  }

  // Gps permission handle
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

  // Current location
  Future<Position?> getCurrentLocation() async {
    final bool isSuccess = await handleLocationPermission();
    if (isSuccess) {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    }
    return null;
  }


  // get real time location
  Stream<Position> getRealTimeLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
      ),
    );
  }
}