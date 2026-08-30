import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/app_theme.dart';

class LocationSelection {
  const LocationSelection(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    this.initialLatitude,
    this.initialLongitude,
    super.key,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _defaultCenter = LatLng(31.5204, 74.3587);
  late LatLng _selected;
  GoogleMapController? _mapController;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _selected =
        widget.initialLatitude != null && widget.initialLongitude != null
        ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
        : _defaultCenter;
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Location services are turned off.');
        setState(() => _isLoadingLocation = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is required to use your current location.',
        );
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentLocation = LatLng(position.latitude, position.longitude);
      if (!mounted) return;

      setState(() {
        _selected = currentLocation;
        _isLoadingLocation = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 16),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingLocation = false);
      _showMessage('Unable to fetch your current location.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose delivery location')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _selected, zoom: 14),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_selected != _defaultCenter) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: _selected, zoom: 14),
                  ),
                );
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onTap: (latLng) => setState(() => _selected = latLng),
            markers: {
              Marker(
                markerId: const MarkerId('selected_location'),
                position: _selected,
                infoWindow: const InfoWindow(title: 'Selected location'),
              ),
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loadCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use current location'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(
                      context,
                      LocationSelection(
                        _selected.latitude,
                        _selected.longitude,
                      ),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Use this location'),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoadingLocation)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Loading current location...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
