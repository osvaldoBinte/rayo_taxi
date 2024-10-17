import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/home_page.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/mapa/data/datasources/travel_local_data_source.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rayo_taxi/features/travel/presentetion/getx/AcceptedTravel/acceptedTravel_getx.dart';
import 'package:rayo_taxi/features/travel/presentetion/getx/TravelById/travel_by_id_alert_getx.dart';
import 'package:rayo_taxi/main.dart';

class AcceptTravelPage extends StatefulWidget {
  final int? idTravel; // Agregar el idTravel como parámetro

  AcceptTravelPage(
      {required this.idTravel}); // Constructor que recibe el idTravel

  @override
  _AcceptTravelPageState createState() => _AcceptTravelPageState();
}

class _AcceptTravelPageState extends State<AcceptTravelPage> {
  late GoogleMapController _mapController;
  final AcceptedtravelGetx _acceptedGetx = Get.find<AcceptedtravelGetx>();

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
  try {
    _mapController = controller;
    if (_markers.isNotEmpty) {
      LatLngBounds bounds = _createLatLngBoundsFromMarkers();
      _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } else {
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
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


  LatLngBounds _createLatLngBoundsFromMarkers() {
    if (_markers.isEmpty) {
      return LatLngBounds(northeast: _center, southwest: _center);
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
    return LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
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
                return Center(child: CircularProgressIndicator());
              }
            } else {
              return Center(
                  child: Text("No hay datos del viaje disponibles."));
            }
          }),
            // Botón flotante en el mapa
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Obx(() {
                    if (travelByIdController.state.value
                        is TravelByIdAlertLoaded) {
                      TravelAlertModel travel = (travelByIdController
                              .state.value as TravelByIdAlertLoaded)
                          .travels[0];

                      if (travel.id_status == 3) {
                        return Column(
                          children: [
                            Text(
                              'Viaje ya aceptado',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: null,
                              child: Text('Aceptar Viaje'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 50, vertical: 20),
                                textStyle: TextStyle(fontSize: 18),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return ElevatedButton(
                          onPressed: () async {
                            await _acceptedGetx.acceptedtravel(
                                AcceptedTravelEvent(
                                    id_travel: widget.idTravel));
                          },
                          child: Text('Aceptar Viaje'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.buttonColormap,
                            padding: EdgeInsets.symmetric(
                                horizontal: 50, vertical: 20),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                        );
                      }
                    } else if (travelByIdController.state.value
                        is TravelByIdAlertLoading) {
                      return Center(child: CircularProgressIndicator());
                    } else if (travelByIdController.state.value
                        is TravelByIdAlertFailure) {
                      return Center(
                          child:
                              Text('Error al cargar los detalles del viaje'));
                    } else {
                      return SizedBox(); // O cualquier otro widget que consideres apropiado
                    }
                  }),

                  // Observar cambios de estado en AcceptedTravelGetx
                  Obx(() {
                    if (_acceptedGetx.acceptedtravelState.value
                        is AcceptedtravelSuccessfully) {
                      Get.snackbar(
                        'Éxito',
                        'Viaje aceptado correctamente',
                        backgroundColor: Theme.of(context).colorScheme.Success,
                      );

                      Future.delayed(Duration(seconds: 1), () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                          (Route<dynamic> route) => false,
                        );
                      });
                    } else if (_acceptedGetx.acceptedtravelState.value
                        is AcceptedtravelError) {
                      Get.snackbar(
                        'Error',
                        'Ocurrió un error: viaje ya fue aceptado o falló la solicitud',
                        backgroundColor: Theme.of(context).colorScheme.error,
                      );
                    }
                    return Container();
                  }),
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
