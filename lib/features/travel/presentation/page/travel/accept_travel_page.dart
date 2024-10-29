import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:quickalert/quickalert.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/home_page.dart';
import 'package:rayo_taxi/features/notification/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelById/travel_by_id_alert_getx.dart';
import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';

class AcceptTravelPage extends StatefulWidget {
  final int? idTravel;

  AcceptTravelPage({required this.idTravel});

  @override
  _AcceptTravelPageState createState() => _AcceptTravelPageState();
}

class _AcceptTravelPageState extends State<AcceptTravelPage> {
  Completer<gmaps.GoogleMapController> _controller = Completer();
  gmaps.GoogleMapController? _mapController;
  Set<gmaps.Marker> _markers = {};
  Set<gmaps.Polyline> _polylines = {};
  gmaps.LatLng? _startLocation;
  gmaps.LatLng? _endLocation;
  gmaps.LatLng? _driverLocation;
  gmaps.LatLng _center = const gmaps.LatLng(20.676666666667, -103.39182);
  TravelLocalDataSource _travelLocalDataSource = TravelLocalDataSourceImp();
  StreamSubscription<Position>? _positionStreamSubscription;

  final TravelByIdAlertGetx travelByIdController =
      Get.find<TravelByIdAlertGetx>();
  late StreamSubscription<ConnectivityResult> subscription;
  
  // Make idStatus an observable variable
  RxInt idStatus = 0.obs;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      travelByIdController.fetchCoDetails(
        TravelByIdEventDetailsEvent(idTravel: widget.idTravel),
      );
    });

    // Check if the state is already loaded
    if (travelByIdController.state.value is TravelByIdAlertLoaded) {
      final state = travelByIdController.state.value as TravelByIdAlertLoaded;
      _handleLoadedState(state);
    }

    // Listen to state changes
    ever<TravelByIdAlertState>(travelByIdController.state, (state) {
      if (state is TravelByIdAlertLoaded) {
        _handleLoadedState(state);
      } else if (state is TravelByIdAlertFailure) {
        print('Error loading travel details: ${state.error}');
      }
    });

    // Subscribe to connectivity changes
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        travelByIdController.fetchCoDetails(
          TravelByIdEventDetailsEvent(idTravel: widget.idTravel),
        );
      }
    });
  }

  void _handleLoadedState(TravelByIdAlertLoaded state) {
    TravelAlertModel travel = state.travels[0];
    print('id from _handleLoadedState: ${travel.id_status}');
    print('status from _handleLoadedState: ${travel.status}');

    double? startLatitude = double.tryParse(travel.start_latitude);
    double? startLongitude = double.tryParse(travel.start_longitude);
    double? endLatitude = double.tryParse(travel.end_latitude);
    double? endLongitude = double.tryParse(travel.end_longitude);

    // Update idStatus without setState
    idStatus.value = travel.id_status ?? 0;

    // Update locations and map markers
    if (startLatitude != null &&
        startLongitude != null &&
        endLatitude != null &&
        endLongitude != null) {
      _startLocation = gmaps.LatLng(startLatitude, startLongitude);
      _endLocation = gmaps.LatLng(endLatitude, endLongitude);

      _addMarker(_startLocation!, true);
      _addMarker(_endLocation!, false);

      _traceRoute();

      // Update camera position
      if (_mapController != null) {
        _updateCameraPosition();
      } else {
        _controller.future.then((controller) {
          _mapController = controller;
          _updateCameraPosition();
        });
      }
    }
  }

  Future<void> _traceRoute() async {
    if (_startLocation != null && _endLocation != null) {
      try {
        await _travelLocalDataSource.getRoute(_startLocation!, _endLocation!);
        String encodedPoints = await _travelLocalDataSource.getEncodedPoints();
        List<gmaps.LatLng> polylineCoordinates = _travelLocalDataSource
            .decodePolyline(encodedPoints)
            .map((point) => gmaps.LatLng(point.latitude, point.longitude))
            .toList();
        setState(() {
          _polylines
              .removeWhere((polyline) => polyline.polylineId.value == 'route');
          _polylines.add(gmaps.Polyline(
            polylineId: gmaps.PolylineId('route'),
            points: polylineCoordinates,
            color: Colors.blue,
            width: 5,
          ));
        });
      } catch (e) {
        print('Error tracing route: $e');
      }
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    subscription.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(gmaps.GoogleMapController controller) {
    try {
      _mapController = controller;
      _controller.complete(controller);
      if (_markers.isNotEmpty) {
        _updateCameraPosition();
      } else {
        _mapController!.animateCamera(
          gmaps.CameraUpdate.newCameraPosition(
            gmaps.CameraPosition(
              target: _center,
              zoom: 12.0,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error creating map: $e');
    }
  }

  void _updateCameraPosition() {
    if (_markers.isNotEmpty && _mapController != null) {
      gmaps.LatLngBounds bounds = _createLatLngBoundsFromMarkers();
      _mapController!
          .animateCamera(gmaps.CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  gmaps.LatLngBounds _createLatLngBoundsFromMarkers() {
    if (_markers.isEmpty) {
      return gmaps.LatLngBounds(northeast: _center, southwest: _center);
    }

    List<gmaps.LatLng> positions = _markers.map((m) => m.position).toList();
    double x0, x1, y0, y1;
    x0 = x1 = positions[0].latitude;
    y0 = y1 = positions[0].longitude;
    for (gmaps.LatLng pos in positions) {
      if (pos.latitude > x1) x1 = pos.latitude;
      if (pos.latitude < x0) x0 = pos.latitude;
      if (pos.longitude > y1) y1 = pos.longitude;
      if (pos.longitude < y0) y0 = pos.longitude;
    }
    return gmaps.LatLngBounds(
        northeast: gmaps.LatLng(x1, y1), southwest: gmaps.LatLng(x0, y0));
  }

  void _addMarker(gmaps.LatLng latLng, bool isStartPlace,
      {bool isDriver = false}) {
    if (!mounted) return;
    setState(() {
      if (isDriver) {
        _markers.removeWhere((m) => m.markerId.value == 'driver');
        _markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId('driver'),
            position: latLng,
            infoWindow: gmaps.InfoWindow(title: 'Conductor'),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                gmaps.BitmapDescriptor.hueBlue),
          ),
        );
        _driverLocation = latLng;
      } else if (isStartPlace) {
        _markers.removeWhere((m) => m.markerId.value == 'start');
        _markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId('start'),
            position: latLng,
            infoWindow: gmaps.InfoWindow(title: 'Inicio'),
          ),
        );
        _startLocation = latLng;
      } else {
        _markers.removeWhere((m) => m.markerId.value == 'destination');
        _markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId('destination'),
            position: latLng,
            infoWindow: gmaps.InfoWindow(title: 'Destino'),
          ),
        );
        _endLocation = latLng;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Stack(
          children: [
            // Always display the map
            gmaps.GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: gmaps.CameraPosition(
                target: _startLocation ?? _center,
                zoom: 12.0,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
            ),
            // Show a loading indicator if locations are not ready
            if (_startLocation == null || _endLocation == null)
              Center(child: CircularProgressIndicator()),
            // Image and text based on idStatus
            Obx(() {
              String statusText;
              String gifPath;

              if (idStatus.value == 3) {
                statusText =
                    'Viaje aceptado, espera al conductor en la ubicación acordada';
                gifPath = 'assets/images/viajes/viaje-aceptado.gif';
              } else if (idStatus.value == 4) {
                statusText = 'Viaje en curso';
                gifPath = 'assets/images/viajes/viaje-en-curso.gif';
              } else if (idStatus.value == 5) {
                statusText = 'Viaje fue terminado';
                gifPath = 'assets/images/viajes/viaje-finalizado.gif';
              } else {
                statusText = 'Estado desconocido';
                gifPath = 'assets/images/viajes/viaje-desconocido.gif';
              }

              return Positioned(
                bottom: 100,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    Text(
                      statusText,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Container(
                      height: 200,
                      width: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          gifPath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            // Button to return to the application
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to HomePage and remove all previous routes
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => HomePage(
                                  selectedIndex: 1,
                                )),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: Text('Regresar a la aplicación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context)
                          .primaryColor, // Adjust the color according to your theme
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            // Information button
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
                        ? 'Cliente: ${(travelByIdController.state.value as TravelByIdAlertLoaded).travels[0].client}\nFecha: ${(travelByIdController.state.value as TravelByIdAlertLoaded).travels[0].date}\nCosto: ${(travelByIdController.state.value as TravelByIdAlertLoaded).travels[0].cost}'
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
