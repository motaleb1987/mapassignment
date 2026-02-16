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
  LatLng? _initialPosition;
  final List<LatLng> _pathPoints = [];
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _setInitialLocation();
  }

  // Current location find
  Future<void> _setInitialLocation() async {
    bool hasPermission = await _locationService.handleLocationPermission();
    if (hasPermission) {
      Position? position = await _locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _initialPosition = LatLng(position.latitude, position.longitude);
        });

        // Camera position changed
        final GoogleMapController controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _initialPosition!, zoom: 16),
          ),
        );
      }
    }
  }

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

  void _updateMap(Position position) async {
    LatLng currentLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _pathPoints.add(currentLatLng);
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('live_track'),
          points: _pathPoints,
          color: Colors.blueAccent,
          width: 5,
          jointType: JointType.round,
        ),
      );

      _markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: currentLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: "I am here"),
        ),
      );
    });

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
      appBar: AppBar(title: const Text('Live Tracking')),
      body: _initialPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition!,
              zoom: 16,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) => _mapController.complete(controller),
          ),
          Positioned(
            bottom: 60,
            left: 50,
            right: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: _isTracking ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: _toggleTracking,
              icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
              label: Text(_isTracking ? "Stop" : "Start"),
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