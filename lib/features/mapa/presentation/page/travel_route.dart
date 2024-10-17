import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/mapa/data/datasources/travel_local_data_source.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rayo_taxi/features/travel/presentetion/getx/EndTravel/endTravel_getx.dart';
import 'package:rayo_taxi/features/travel/presentetion/getx/StartTravel/startTravel_getx.dart';
import 'package:rayo_taxi/main.dart';

import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/start_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/end_travel_usecase.dart';

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

  bool _journeyStarted = false;
  bool _isButtonEnabled = false;
  bool _journeyCompleted = false;
  final double _proximityThreshold = 50;

  final StarttravelGetx _startTravelController = Get.find<StarttravelGetx>();
  final EndtravelGetx _endTravelController = Get.find<EndtravelGetx>();

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

      _traceRouteStartToEnd(); // Trazar ruta desde inicio hasta destino
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al convertir coordenadas a números')),
        );
      });
    }

    // Ahora, manejamos el id_status
    String idStatusStr = travelAlert.id_status.toString();
    int idStatus = int.tryParse(idStatusStr) ?? 0;

    if (idStatus == 4) {
      // El viaje ya ha sido iniciado
      setState(() {
        _journeyStarted = true;
        _journeyCompleted = false;

        // Eliminamos el marcador 'start'
        _markers.removeWhere((m) => m.markerId.value == 'start');

        // Eliminamos las polilíneas relacionadas con el inicio
        _polylines.removeWhere(
            (polyline) => polyline.polylineId.value == 'start_to_end');
        _polylines.removeWhere(
            (polyline) => polyline.polylineId.value == 'driver_to_start');

        // Forzamos la actualización de la ruta
        _lastDriverPositionForRouteUpdate = null;
        _updateDriverRouteIfNeeded();
      });
    } else if (idStatus == 3) {
      // El viaje ha sido aceptado pero no iniciado
      _journeyStarted = false;
      _journeyCompleted = false;
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

      _checkProximityAndEnableButton();
      _updateDriverRouteIfNeeded();
    });
  }

 void _checkProximityAndEnableButton() {
  if (_driverLocation != null) {
    double distance;
    if (!_journeyStarted) {
      // Antes de iniciar el viaje, comprobar proximidad al punto de inicio
      if (_startLocation != null) {
        distance = Geolocator.distanceBetween(
          _driverLocation!.latitude,
          _driverLocation!.longitude,
          _startLocation!.latitude,
          _startLocation!.longitude,
        );

        if (distance <= _proximityThreshold && !_isButtonEnabled) {
          setState(() {
            _isButtonEnabled = true;
          });
        } else if (distance > _proximityThreshold && _isButtonEnabled) {
          setState(() {
            _isButtonEnabled = false;
          });
        }
      }
    } else if (_journeyStarted && !_journeyCompleted) {
      // Durante el viaje, comprobar proximidad al destino
      if (_endLocation != null) {
        distance = Geolocator.distanceBetween(
          _driverLocation!.latitude,
          _driverLocation!.longitude,
          _endLocation!.latitude,
          _endLocation!.longitude,
        );

        if (distance <= _proximityThreshold && !_isButtonEnabled) {
          setState(() {
            _isButtonEnabled = true;
          });
        } else if (distance > _proximityThreshold && _isButtonEnabled) {
          setState(() {
            _isButtonEnabled = false;
          });
        }
      }
    } else {
      // Viaje completado, el botón debe estar deshabilitado
      if (_isButtonEnabled) {
        setState(() {
          _isButtonEnabled = false;
        });
      }
    }
  }
}

  void _updateDriverRouteIfNeeded() {
    if (_driverLocation == null) return;

    if (_journeyStarted && !_journeyCompleted) {
      _traceRouteDriverToEnd();
    } else if (!_journeyStarted) {
      _traceRouteDriverToStart();
    }
  }

  Future<void> _traceRouteStartToEnd() async {
    if (_startLocation != null && _endLocation != null) {
      try {
        await _travelLocalDataSource.getRoute(_startLocation!, _endLocation!);
        String encodedPoints = await _travelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            _travelLocalDataSource.decodePolyline(encodedPoints);
        setState(() {
          _polylines.removeWhere(
              (polyline) => polyline.polylineId.value == 'start_to_end');
          _polylines.add(Polyline(
            polylineId: PolylineId('start_to_end'),
            points: polylineCoordinates,
            color: Colors.blue,
            width: 5,
          ));
        });
      } catch (e) {
        print('Error al trazar la ruta de inicio a destino: $e');
      }
    }
  }

  Future<void> _traceRouteDriverToStart() async {
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
              (polyline) => polyline.polylineId.value == 'driver_to_start');
          _polylines.add(Polyline(
            polylineId: PolylineId('driver_to_start'),
            points: polylineCoordinates,
            color: Colors.red,
            width: 5,
          ));
        });
      } catch (e) {
        print('Error al trazar la ruta del conductor al inicio: $e');
      }
    }
  }

  Future<void> _traceRouteDriverToEnd() async {
    if (_driverLocation != null && _endLocation != null) {
      try {
        await _driverTravelLocalDataSource.getRoute(
            _driverLocation!, _endLocation!);
        String encodedPoints =
            await _driverTravelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            _driverTravelLocalDataSource.decodePolyline(encodedPoints);
        setState(() {
          _polylines.removeWhere(
              (polyline) => polyline.polylineId.value == 'driver_to_end');
          _polylines.add(Polyline(
            polylineId: PolylineId('driver_to_end'),
            points: polylineCoordinates,
            color: Colors.red,
            width: 5,
          ));
        });
      } catch (e) {
        print('Error al trazar la ruta del conductor al destino: $e');
      }
    }
  }

  void _cancelJourney() {
    setState(() {
      _journeyStarted = false;
      _journeyCompleted = false;
      _polylines.clear(); // Limpiamos las polilíneas
      _isButtonEnabled = false;
      _addMarker(_startLocation!, true);
      _traceRouteStartToEnd();
      _traceRouteDriverToStart();
    });
  }

  void _startTravel() {
    String travelId =
        widget.travelList.isNotEmpty ? widget.travelList[0].id.toString() : '';

    if (travelId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se encontró el ID del viaje')),
      );

      return;
    }

    _startTravelController
        .starttravel(StartravelEvent(id_travel: widget.travelList[0].id));

    _startTravelController.starttravelState.listen((state) {
      if (state is StarttravelLoading) {
        // Mostrar indicador de carga si es necesario
      } else if (state is AcceptedtravelSuccessfully) {
        // Viaje iniciado correctamente
        setState(() {
          _journeyStarted = true;
          _isButtonEnabled = false;
          // Actualizar la interfaz de usuario según sea necesario
          // Eliminar marcador 'start'
          _markers.removeWhere((m) => m.markerId.value == 'start');
          // Eliminar polilíneas
          _polylines.removeWhere(
              (polyline) => polyline.polylineId.value == 'start_to_end');
          _polylines.removeWhere(
              (polyline) => polyline.polylineId.value == 'driver_to_start');
          // Forzar actualización de ruta
          _lastDriverPositionForRouteUpdate = null;
          _updateDriverRouteIfNeeded();
        });

        Get.snackbar(
          'Éxito',
          'Viaje iniciado correctamente',
          backgroundColor: Theme.of(context).colorScheme.Success,
        );
      } else if (state is StarttravelError) {
        Get.snackbar(
          'Error al iniciar viaje',
          'viaje ya fue iniciado ${state.message}',
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    });
  }

  void _endTravel() {
    String travelId =
        widget.travelList.isNotEmpty ? widget.travelList[0].id.toString() : '';

    if (travelId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se encontró el ID del viaje')),
      );
      return;
    }

    _endTravelController
        .endtravel(EndTravelEvent(id_travel: widget.travelList[0].id));

    _endTravelController.endtravelState.listen((state) {
      if (state is EndtravelLoading) {
        // Mostrar indicador de carga si es necesario
      } else if (state is EndtravelSuccessfully) {
        // Viaje terminado correctamente
        setState(() {
          _journeyCompleted = true;
          _isButtonEnabled = false;
          // Actualizar la interfaz de usuario según sea necesario
        });
       Get.snackbar(
          'Éxito',
          'Viaje terminado correctamente',
          backgroundColor: Theme.of(context).colorScheme.Success,
        );
      } else if (state is EndtravelError) {
       
         Get.snackbar(
          'Error al terminal el viaje',
          'viaje ya fue terminado ${state.message}',
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String buttonLabel;
    Function()? onButtonPressed;

     if (!_journeyStarted) {
    buttonLabel = 'Iniciar Viaje';
    onButtonPressed = _isButtonEnabled ? _startTravel : null;
  } else if (_journeyStarted && !_journeyCompleted) {
    buttonLabel = 'Terminar Viaje';
    onButtonPressed = _isButtonEnabled ? _endTravel : null;
  } else {
    buttonLabel = 'Viaje Completado';
    onButtonPressed = null;
  }

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
              bottom: 80,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _journeyStarted
                        ? () {
                            _cancelJourney(); // Lógica para cancelar el viaje
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.buttonColormap,
                    ),
                    child: Text('Cancelar Viaje'),
                  ),
                  ElevatedButton(
                    onPressed: onButtonPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.buttonColormap,
                    ),
                    child: Text(buttonLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
