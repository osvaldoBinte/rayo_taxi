import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/mapa/data/datasources/travel_local_data_source.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rayo_taxi/features/travel/presentetion/getx/TravelById/travel_by_id_alert_getx.dart';

class TravelIdPage extends StatefulWidget {
  final int? idTravel; // Agregar el idTravel como parámetro

  TravelIdPage({required this.idTravel}); // Constructor que recibe el idTravel

  @override
  _TravelRouteState createState() => _TravelRouteState();
}

class _TravelRouteState extends State<TravelIdPage> {
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

  final TravelByIdAlertGetx travelByIdController =
      Get.find<TravelByIdAlertGetx>();
  late StreamSubscription<ConnectivityResult> subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      travelByIdController.fetchCoDetails(
          TravelByIdEventDetailsEvent(idTravel: widget.idTravel));
    });

    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se perdió la conectividad Wi-Fi'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        travelByIdController.fetchCoDetails(
            TravelByIdEventDetailsEvent(idTravel: widget.idTravel));
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

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    subscription.cancel();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Usar Obx para observar los cambios en el estado de GetX
            Obx(() {
              if (travelByIdController.state.value is TravelByIdAlertLoading) {
                return Center(child: CircularProgressIndicator());
              } else if (travelByIdController.state.value
                  is TravelByIdAlertFailure) {
                return Center(
                    child: Text((travelByIdController.state.value
                            as TravelByIdAlertFailure)
                        .error));
              } else if (travelByIdController.state.value
                  is TravelByIdAlertLoaded) {
                TravelAlertModel travel =
                    (travelByIdController.state.value as TravelByIdAlertLoaded)
                        .travels[0];

                // Mover la lógica de _traceRoute fuera del ciclo de construcción
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_startLocation == null && _endLocation == null) {
                    double? startLatitude =
                        double.tryParse(travel.start_latitude);
                    double? startLongitude =
                        double.tryParse(travel.start_longitude);
                    double? endLatitude = double.tryParse(travel.end_latitude);
                    double? endLongitude =
                        double.tryParse(travel.end_longitude);

                    if (startLatitude != null &&
                        startLongitude != null &&
                        endLatitude != null &&
                        endLongitude != null) {
                      _startLocation = LatLng(startLatitude, startLongitude);
                      _endLocation = LatLng(endLatitude, endLongitude);

                      _addMarker(_startLocation!, true);
                      _addMarker(_endLocation!, false);

                      _traceRoute();
                    }
                  }
                });

                return GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _startLocation ?? _center,
                    zoom: 12.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                );
              } else {
                return Center(
                    child: Text("No hay datos del viaje disponibles."));
              }
            }),
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
                    text: travelByIdController.state.value
                            is TravelByIdAlertLoaded
                        ? 'Fecha: ${(travelByIdController.state.value as TravelByIdAlertLoaded).travels[0].client}\nFecha: ${(travelByIdController.state.value as TravelByIdAlertLoaded).travels[0].date}\nCosto: ${(travelByIdController.state.value as TravelByIdAlertLoaded).travels[0].cost}'
                        : 'Sin información de cliente',
                    confirmBtnText: 'Cerrar',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
