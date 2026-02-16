import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';

class MyLocationScreen extends StatefulWidget {
  const MyLocationScreen({super.key});

  @override
  State<MyLocationScreen> createState() => _MyLocationScreenState();
}

class _MyLocationScreenState extends State<MyLocationScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final LocationService _locationService = LocationService();
  StreamSubscription? _locationSubscriber;

  bool _isTracking = false;
  final List<LatLng> _pathPoints = [];
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  // ট্র্যাকিং শুরু
  Future<void> _toggleTracking() async {
    if (_isTracking) {
      _locationSubscriber?.cancel();
      setState(() => _isTracking = false);
    } else {
      bool hasPermission = await _locationService.handleLocationPermission();
      if (hasPermission) {
        setState(() {
          _isTracking = true;
          _pathPoints.clear();
          _polylines.clear();
          _markers.clear();
        });

        _locationSubscriber = _locationService.getRealTimeLocationStream().listen((Position position) {
          _updateMap(position);
        });
      }
    }
  }

  // ম্যাপ আপডেট লজিক
  void _updateMap(Position position) async {
    LatLng currentLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _pathPoints.add(currentLatLng);

      // পলিলাইন ড্র করা
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('live_track'),
          points: _pathPoints,
          color: Colors.blueAccent,
          width: 6,
          jointType: JointType.round,
        ),
      );

      // মার্কার আপডেট (বর্তমান পজিশন)
      _markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: currentLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: "You are here"),
        ),
      );
    });

    // ক্যামেরা অটোমেটিক ইউজারের সাথে মুভ করবে
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: currentLatLng, zoom: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Polyline Tracking')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(24.253724327647177, 89.92152362727028),
              zoom: 16,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) => _mapController.complete(controller),
          ),

          // কন্ট্রোল বাটন
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: _isTracking ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: _toggleTracking,
              icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
              label: Text(_isTracking ? "Stop Recording Path" : "Start Tracking Path"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationSubscriber?.cancel();
    super.dispose();
  }
}