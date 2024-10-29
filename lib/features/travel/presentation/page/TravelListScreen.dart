import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/notification/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';

class MapScreen22 extends StatefulWidget {
  final List<TravelAlertModel> travelList;

  MapScreen22({required this.travelList});

  @override
  _MapScreen22State createState() => _MapScreen22State();
}

class _MapScreen22State extends State<MapScreen22> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _startLocation;
  LatLng? _endLocation;
  LatLng _center = const LatLng(20.676666666667, -103.39182);
  TravelLocalDataSource _travelLocalDataSource = TravelLocalDataSourceImp();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
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
        setState(() {
          _startLocation = LatLng(startLatitude, startLongitude);
          _endLocation = LatLng(endLatitude, endLongitude);
        });

        _addMarker(_startLocation!, true);
        _addMarker(_endLocation!, false);

        await _traceRoute();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al convertir coordenadas a números')),
          );
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Opcional: Mover la cámara a la ubicación inicial
    if (_startLocation != null) {
      _mapController?.moveCamera(
        CameraUpdate.newLatLngZoom(_startLocation!, 14.0),
      );
    }
  }

  void _addMarker(LatLng latLng, bool isStartPlace) {
    if (!mounted) return;

    MarkerId markerId = isStartPlace ? MarkerId('start') : MarkerId('destination');
    String title = isStartPlace ? 'Inicio' : 'Destino';

    // Verificar si el marcador ya existe y está en la misma posición
    Marker? existingMarker = _markers.firstWhere(
      (m) => m.markerId == markerId,
      orElse: () => Marker(markerId: MarkerId('')),
    );

    if (existingMarker.markerId != MarkerId('')) {
      if (existingMarker.position == latLng) return; // No hay cambios
      _markers.remove(existingMarker);
    }

    setState(() {
      _markers.add(
        Marker(
          markerId: markerId,
          position: latLng,
          infoWindow: InfoWindow(title: title),
        ),
      );
      if (isStartPlace) {
        _startLocation = latLng;
      } else {
        _endLocation = latLng;
      }
    });
  }

  List<LatLng> _simplifyPolyline(List<LatLng> polyline, double tolerance) {
    if (polyline.length < 3) return polyline;
    List<LatLng> simplified = [];
    simplified.add(polyline.first);
    for (int i = 1; i < polyline.length - 1; i++) {
      // Implementa aquí un algoritmo de simplificación como Douglas-Peucker
      // Este es un ejemplo simplificado sin lógica real de simplificación
      simplified.add(polyline[i]);
    }
    simplified.add(polyline.last);
    return simplified;
  }

  Future<void> _traceRoute() async {
    if (_startLocation != null && _endLocation != null) {
      try {
        await _travelLocalDataSource.getRoute(_startLocation!, _endLocation!);
        String encodedPoints = await _travelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            _travelLocalDataSource.decodePolyline(encodedPoints);

        // Simplificar la polilínea para mejorar el rendimiento
        List<LatLng> simplifiedCoordinates = _simplifyPolyline(polylineCoordinates, 0.01);

        setState(() {
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: PolylineId('route'),
            points: simplifiedCoordinates,
            color: Colors.blue,
            width: 5,
          ));
        });
      } catch (e) {
        print('Error al trazar la ruta: $e');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al trazar la ruta')),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (!_isLoading)
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _startLocation ?? _center,
                  zoom: 12.0,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
              )
            else
              Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
