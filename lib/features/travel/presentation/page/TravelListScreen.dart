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
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _startLocation;
  LatLng? _endLocation;
  LatLng _center = const LatLng(20.676666666667, -103.39182);
  TravelLocalDataSource _travelLocalDataSource = TravelLocalDataSourceImp();

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
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Opcional: Mover la cámara a la ubicación inicial
    if (_startLocation != null) {
      _mapController.moveCamera(
        CameraUpdate.newLatLngZoom(_startLocation!, 14.0),
      );
    }
  }

  void _addMarker(LatLng latLng, bool isStartPlace) {
    if (!mounted) return;
    setState(() {
      if (isStartPlace) {
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

  Future<void> _traceRoute() async {
    if (_startLocation != null && _endLocation != null) {
      try {
        await _travelLocalDataSource.getRoute(_startLocation!, _endLocation!);
        String encodedPoints = await _travelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            _travelLocalDataSource.decodePolyline(encodedPoints);
        setState(() {
          _polylines.clear();
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
            ),
            // Puedes agregar otros widgets aquí si es necesario
          ],
        ),
      ),
    );
  }
}