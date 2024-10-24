import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps; // Alias asignado
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart'; // Importación del paquete Lottie
import 'package:rayo_taxi/features/clients/presentation/pages/home_page.dart';
import 'package:rayo_taxi/features/notification/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelById/travel_by_id_alert_getx.dart';
import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';

class AcceptTravelPage extends StatefulWidget {
  final int? idTravel; // Agregar el idTravel como parámetro

  AcceptTravelPage({required this.idTravel}); // Constructor que recibe el idTravel

  @override
  _AcceptTravelPageState createState() => _AcceptTravelPageState();
}

class _AcceptTravelPageState extends State<AcceptTravelPage> {
  late maps.GoogleMapController _mapController; // Usar el alias aquí
  // Eliminado: final AcceptedtravelGetx _acceptedGetx = Get.find<AcceptedtravelGetx>();

  Set<maps.Marker> _markers = {}; // Usar el alias aquí
  Set<maps.Polyline> _polylines = {}; // Usar el alias aquí
  LatLng? _startLocation;
  LatLng? _endLocation;
  LatLng? _driverLocation;
  LatLng _center = const LatLng(20.676666666667, -103.39182);
  TravelLocalDataSource _travelLocalDataSource = TravelLocalDataSourceImp();
  TravelLocalDataSource _driverTravelLocalDataSource = TravelLocalDataSourceImp();
  StreamSubscription<Position>? _positionStreamSubscription;

  final TravelByIdAlertGetx travelByIdController = Get.find<TravelByIdAlertGetx>();
  late StreamSubscription<ConnectivityResult> subscription;

  @override
  void initState() {
    super.initState();

    // Escuchar cambios en el controlador de TravelById
    ever(travelByIdController.state, (state) {
      if (state is TravelByIdAlertLoaded) {
        TravelAlertModel travel = state.travels[0];

        double? startLatitude = double.tryParse(travel.start_latitude);
        double? startLongitude = double.tryParse(travel.start_longitude);
        double? endLatitude = double.tryParse(travel.end_latitude);
        double? endLongitude = double.tryParse(travel.end_longitude);

        if (startLatitude != null &&
            startLongitude != null &&
            endLatitude != null &&
            endLongitude != null) {
          setState(() {
            _startLocation = LatLng(startLatitude, startLongitude);
            _endLocation = LatLng(endLatitude, endLongitude);

            _addMarker(_startLocation!, true);
            _addMarker(_endLocation!, false);

            _traceRoute();
          });
        }
      } else if (state is TravelByIdAlertFailure) {
        print('Error al cargar los detalles del viaje: ${state.error}');
      }
    });

    // Iniciar la búsqueda de detalles del viaje
    travelByIdController.fetchCoDetails(
        TravelByIdEventDetailsEvent(idTravel: widget.idTravel));

    // Suscripción a cambios de conectividad
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
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
          _polylines.removeWhere((polyline) => polyline.polylineId.value == 'route');
          _polylines.add(maps.Polyline( // Usar el alias aquí
            polylineId: maps.PolylineId('route'),
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

  void _onMapCreated(maps.GoogleMapController controller) { // Usar el alias aquí
    try {
      _mapController = controller;
      if (_markers.isNotEmpty) {
        maps.LatLngBounds bounds = _createLatLngBoundsFromMarkers(); // Usar el alias aquí
        _mapController.animateCamera(maps.CameraUpdate.newLatLngBounds(bounds, 50)); // Usar el alias aquí
      } else {
        _mapController.animateCamera(
          maps.CameraUpdate.newCameraPosition(
            maps.CameraPosition(
              target: _center,
              zoom: 12.0,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error al crear el mapa: $e');
    }
  }

  maps.LatLngBounds _createLatLngBoundsFromMarkers() { // Usar el alias aquí
    if (_markers.isEmpty) {
      return maps.LatLngBounds(northeast: _center, southwest: _center);
    }

    List<maps.LatLng> positions = _markers.map((m) => m.position).toList(); // Usar el alias aquí
    double x0, x1, y0, y1;
    x0 = x1 = positions[0].latitude;
    y0 = y1 = positions[0].longitude;
    for (maps.LatLng pos in positions) { // Usar el alias aquí
      if (pos.latitude > x1) x1 = pos.latitude;
      if (pos.latitude < x0) x0 = pos.latitude;
      if (pos.longitude > y1) y1 = pos.longitude;
      if (pos.longitude < y0) y0 = pos.longitude;
    }
    return maps.LatLngBounds(
        northeast: maps.LatLng(x1, y1), 
        southwest: maps.LatLng(x0, y0)
    ); // Usar el alias aquí
  }

  void _addMarker(maps.LatLng latLng, bool isStartPlace, {bool isDriver = false}) { // Usar el alias aquí
    if (!mounted) return;
    setState(() {
      if (isDriver) {
        _markers.removeWhere((m) => m.markerId.value == 'driver');
        _markers.add(
          maps.Marker(
            markerId: maps.MarkerId('driver'),
            position: latLng,
            infoWindow: maps.InfoWindow(title: 'Conductor'),
            icon: maps.BitmapDescriptor.defaultMarkerWithHue(
                maps.BitmapDescriptor.hueBlue), // Usar el alias aquí
          ),
        );
        _driverLocation = latLng;
      } else if (isStartPlace) {
        _markers.removeWhere((m) => m.markerId.value == 'start');
        _markers.add(
          maps.Marker(
            markerId: maps.MarkerId('start'),
            position: latLng,
            infoWindow: maps.InfoWindow(title: 'Inicio'),
          ),
        );
        _startLocation = latLng;
      } else {
        _markers.removeWhere((m) => m.markerId.value == 'destination');
        _markers.add(
          maps.Marker(
            markerId: maps.MarkerId('destination'),
            position: latLng,
            infoWindow: maps.InfoWindow(title: 'Destino'),
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
      appBar: AppBar(
        title: Text(
          'Accept Travel',
          style: TextStyle(
              fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Mapa con detalles del viaje
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
                if (_startLocation != null && _endLocation != null) {
                  return maps.GoogleMap( // Usar el alias aquí
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: maps.CameraPosition( // Usar el alias aquí
                      target: _startLocation ?? _center,
                      zoom: 12.0,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              } else {
                return Center(
                    child: Text("No hay datos del viaje disponibles."));
              }
            }),
            // Botón flotante en el mapa con animación de Lottie
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  // Animación de Lottie encima del botón
                  Transform.scale(
                    scaleX: -1.0, // Voltear horizontalmente
                    child: Lottie.network(
                      'https://lottie.host/embed/4ecd5649-5787-4c77-b4a2-d6da04cfc6a2/l5yP7By7rb.json',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 10), // Espacio entre la animación y el botón
                  ElevatedButton(
                    onPressed: () {
                      // Navegar a HomePage y eliminar todas las rutas anteriores
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: Text('Regresar a la aplicación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor, // Ajusta el color según tu tema
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
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
