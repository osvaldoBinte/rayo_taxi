import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/mapa/data/datasources/travel_local_data_source.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rayo_taxi/main.dart';

class TravelRoute extends StatefulWidget {
  final List<TravelAlertModel> travelList;

  TravelRoute({required this.travelList});

  @override
  _TravelRouteState createState() => _TravelRouteState();
}

class _TravelRouteState extends State<TravelRoute> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _startLocation;
  LatLng? _endLocation;
  LatLng? _driverLocation;
  LatLng _center = const LatLng(20.676666666667, -103.39182);
  TravelLocalDataSource _travelLocalDataSource = TravelLocalDataSourceImp();
  TravelLocalDataSource _driverTravelLocalDataSource =
      TravelLocalDataSourceImp();
  StreamSubscription<Position>? _positionStreamSubscription;

  LatLng? _lastDriverPositionForRouteUpdate;
  final double _routeUpdateDistanceThreshold = 5;

  @override
  void initState() {
    super.initState();

    if (widget.travelList.isNotEmpty) {
      var travelAlert = widget.travelList[0];

      double? startLatitude = double.tryParse(travelAlert.start_latitude);
      double? startLongitude = double.tryParse(travelAlert.start_longitude);
      double? endLatitude = double.tryParse(travelAlert.end_latitude);
      double? endLongitude = double.tryParse(travelAlert.end_longitude);

      if (startLatitude != null &&
          startLongitude != null &&
          endLatitude != null &&
          endLongitude != null) {
        _startLocation = LatLng(startLatitude, startLongitude);
        _endLocation = LatLng(endLatitude, endLongitude);

        _addMarker(_startLocation!, true);
        _addMarker(_endLocation!, false);

        _traceRoute();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al convertir coordenadas a números')),
          );
        });
      }
    }

    _getCurrentLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    LatLngBounds bounds = _createLatLngBoundsFromMarkers();
    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  LatLngBounds _createLatLngBoundsFromMarkers() {
    if (_markers.isEmpty) {
      return LatLngBounds(
        northeast: _center,
        southwest: _center,
      );
    }

    List<LatLng> positions = _markers.map((m) => m.position).toList();
    double x0, x1, y0, y1;
    x0 = x1 = positions[0].latitude;
    y0 = y1 = positions[0].longitude;
    for (LatLng pos in positions) {
      if (pos.latitude > x1) x1 = pos.latitude;
      if (pos.latitude < x0) x0 = pos.latitude;
      if (pos.longitude > y1) y1 = pos.longitude;
      if (pos.longitude < y0) y0 = pos.longitude;
    }
    return LatLngBounds(
      northeast: LatLng(x1, y1),
      southwest: LatLng(x0, y0),
    );
  }

  void _addMarker(LatLng latLng, bool isStartPlace, {bool isDriver = false}) {
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
      } else if (isStartPlace) {
        _markers.removeWhere((m) => m.markerId.value == 'start');
        _markers.add(
          Marker(
            markerId: MarkerId('start'),
            position: latLng,
            infoWindow: InfoWindow(title: 'Inicio'),
          ),
        );
        _startLocation = latLng;
      } else {
        _markers.removeWhere((m) => m.markerId.value == 'destination');
        _markers.add(
          Marker(
            markerId: MarkerId('destination'),
            position: latLng,
            infoWindow: InfoWindow(title: 'Destino'),
          ),
        );
        _endLocation = latLng;
      }
    });
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

    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (!mounted) return;

      setState(() {
        _driverLocation = LatLng(position.latitude, position.longitude);
        _addMarker(_driverLocation!, false, isDriver: true);
      });

      _updateDriverRouteIfNeeded();
    });
  }

  void _updateDriverRouteIfNeeded() {
    if (_driverLocation == null || _startLocation == null) return;

    if (_lastDriverPositionForRouteUpdate == null ||
        Geolocator.distanceBetween(
              _lastDriverPositionForRouteUpdate!.latitude,
              _lastDriverPositionForRouteUpdate!.longitude,
              _driverLocation!.latitude,
              _driverLocation!.longitude,
            ) >
            _routeUpdateDistanceThreshold) {
      _lastDriverPositionForRouteUpdate = _driverLocation;
      _traceDriverRoute();
    }
  }

  Future<void> _traceRoute() async {
    if (_startLocation != null && _endLocation != null) {
      try {
        await _travelLocalDataSource.getRoute(_startLocation!, _endLocation!);
        String encodedPoints = await _travelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            _travelLocalDataSource.decodePolyline(encodedPoints);
        setState(() {
          _polylines
              .removeWhere((polyline) => polyline.polylineId.value == 'route');
          _polylines.add(Polyline(
            polylineId: PolylineId('route'),
            points: polylineCoordinates,
            color: Colors.blue,
            width: 5,
          ));
        });
      } catch (e) {
        print('Error al trazar la ruta: $e');
      }
    }
  }

  Future<void> _traceDriverRoute() async {
    if (_driverLocation != null && _startLocation != null) {
      try {
        await _driverTravelLocalDataSource.getRoute(
            _driverLocation!, _startLocation!);
        String encodedPoints =
            await _driverTravelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            _driverTravelLocalDataSource.decodePolyline(encodedPoints);
        setState(() {
          _polylines.removeWhere(
              (polyline) => polyline.polylineId.value == 'driver_route');
          _polylines.add(Polyline(
            polylineId: PolylineId('driver_route'),
            points: polylineCoordinates,
            color: Colors.red,
            width: 5,
          ));
        });
      } catch (e) {
        print('Error al trazar la ruta del conductor: $e');
      }
    }
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _startLocation ?? _center,
              zoom: 12.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.info_outline, size: 40),
              onPressed: () {
                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.info,
                  title: 'Información del Viaje',
                  text: widget.travelList.isNotEmpty
                      ? 'Cliente: ${widget.travelList[0].client}\nCosto: ${widget.travelList[0].cost}'
                      : 'Sin información de cliente',
                  confirmBtnText: 'Cerrar',
                );
              },
            ),
          ),
          Positioned(
            bottom: 80, // Ajusta esta posición según sea necesario
            right: 10,
            child: ElevatedButton(
              onPressed: () {
                // Acción del botón
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.buttonColormap,
              ),
              child: Text('Iniciar Viaje'),
            ),
          ),
        ],
      ),
    ),
  );
}
}