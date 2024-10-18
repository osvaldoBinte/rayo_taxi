import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/features/notification/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelById/travel_by_id_alert_getx.dart';
import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';
import 'package:geolocator/geolocator.dart';

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

  final TravelByIdAlertGetx travelByIdController =
      Get.find<TravelByIdAlertGetx>();
  late StreamSubscription<ConnectivityResult> subscription;

  @override
  void initState() {
    super.initState();

    // Fetch the travel details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      travelByIdController.fetchCoDetails(
          TravelByIdEventDetailsEvent(idTravel: widget.idTravel));
    });
    // Observa los cambios en el estado del controlador
    ever(travelByIdController.state, (state) {
      if (state is TravelByIdAlertLoaded) {
        // Procesa los datos del viaje
        _processTravelData(state.travels[0]);
      } else if (state is TravelByIdAlertFailure) {
        // Maneja el error y muestra el mapa sin ruta
        print('Error al cargar los datos del viaje: ${state.error}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudieron cargar los datos del viaje.'),
              duration: Duration(seconds: 3),
            ),
          );
          // Asegúrate de mostrar el mapa aunque haya fallado la carga
          setState(() {});
        }
      }
    });

    // Escucha cambios en la conectividad
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se perdió la conectividad Wi-Fi'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        travelByIdController.fetchCoDetails(
            TravelByIdEventDetailsEvent(idTravel: widget.idTravel));
      }
    });
  }

  void _processTravelData(TravelAlertModel travel) {
    // Inicializa las ubicaciones de inicio y fin
    double? startLatitude = double.tryParse(travel.start_latitude);
    double? startLongitude = double.tryParse(travel.start_longitude);
    double? endLatitude = double.tryParse(travel.end_latitude);
    double? endLongitude = double.tryParse(travel.end_longitude);

    if (startLatitude != null &&
        startLongitude != null &&
        endLatitude != null &&
        endLongitude != null) {
      _startLocation = LatLng(startLatitude, startLongitude);
      _endLocation = LatLng(endLatitude, endLongitude);

      // Agrega marcadores
      _addMarker(_startLocation!, true);
      _addMarker(_endLocation!, false);

      // Traza la ruta
      _traceRoute();
    } else {
      print('Error: No se pudo obtener las coordenadas de inicio y fin.');
      // Mostrar el mapa sin ruta
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _traceRoute() async {
    if (_startLocation != null && _endLocation != null) {
      try {
        await _travelLocalDataSource.getRoute(_startLocation!, _endLocation!);
        String encodedPoints = await _travelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            _travelLocalDataSource.decodePolyline(encodedPoints);

        if (polylineCoordinates.isNotEmpty) {
          if (!mounted) return; // Verifica que el widget esté montado
          setState(() {
            _polylines.removeWhere(
                (polyline) => polyline.polylineId.value == 'route');
            _polylines.add(Polyline(
              polylineId: PolylineId('route'),
              points: polylineCoordinates,
              color: Colors.blue,
              width: 5,
            ));
          });
        } else {
          print('No se pudieron obtener puntos para la ruta.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No se pudo cargar la ruta.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        print('Error al trazar la ruta: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo cargar la ruta.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Ajusta la cámara para mostrar todos los marcadores
    if (_markers.isNotEmpty) {
      LatLngBounds bounds = _createLatLngBoundsFromMarkers();
      _mapController.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    } else {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(_center),
      );
    }
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

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Mostrar el mapa independientemente del estado
            _buildMap(),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: Icon(Icons.info_outline, size: 40),
                onPressed: () {
                  if (travelByIdController.state.value
                      is TravelByIdAlertLoaded) {
                    var travel = (travelByIdController.state.value
                            as TravelByIdAlertLoaded)
                        .travels[0];
                    var driverName = 'Sin conductor asignado';

                    if (travel.drivers!.isNotEmpty) {
                      driverName = travel.drivers![0].name;
                    }

                    QuickAlert.show(
                      context: context,
                      type: QuickAlertType.info,
                      title: 'Información del Viaje',
                      text:
                          'Conductor: $driverName\nFecha: ${travel.date}\nCosto: ${travel.cost}',
                      confirmBtnText: 'Cerrar',
                    );
                  } else {
                    QuickAlert.show(
                      context: context,
                      type: QuickAlertType.info,
                      title: 'Información del Viaje',
                      text: 'Sin información de conductor',
                      confirmBtnText: 'Cerrar',
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
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
  }
}
