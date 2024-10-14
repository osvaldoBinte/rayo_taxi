import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MidireccionPage extends StatefulWidget {
  @override
  _TravelRouteState createState() => _TravelRouteState();
}

class _TravelRouteState extends State<MidireccionPage> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  LatLng? _driverLocation;
  LatLng _center = const LatLng(20.676666666667, -103.39182);
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Por favor, habilita los servicios de ubicación')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Los permisos de ubicación están denegados')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Los permisos de ubicación están denegados permanentemente')),
      );
      return;
    }

    // Crear los ajustes de ubicación
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0, // Actualizar lo más frecuentemente posible
    );

    // Suscribirse al stream de ubicación
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (!mounted) return;

      // Actualizar el marcador del conductor inmediatamente
      setState(() {
        _driverLocation = LatLng(position.latitude, position.longitude);
        _addMarker(_driverLocation!, isDriver: true);

        // Mover la cámara hacia la nueva ubicación del conductor
        _mapController.animateCamera(
          CameraUpdate.newLatLng(_driverLocation!),
        );
      });
    });
  }

  void _addMarker(LatLng latLng, {bool isDriver = false}) {
    if (!mounted) return;
    setState(() {
      if (isDriver) {
        _markers.removeWhere((m) => m.markerId.value == 'driver');
        _markers.add(
          Marker(
            markerId: MarkerId('driver'),
            position: latLng,
            infoWindow: InfoWindow(title: 'Conductor'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
        _driverLocation = latLng;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _driverLocation ?? _center,
                zoom: 12.0,
              ),
              markers: _markers,
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              liteModeEnabled: false, // Habilitamos el modo normal
            ),
          ],
        ),
      ),
    );
  }
}
