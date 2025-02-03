import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/data/datasources/socket_driver_data_source.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/data/datasources/mapa_local_data_source.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:shared_preferences/shared_preferences.dart';

class CurrentTravelController extends GetxController {
  StreamSubscription? _socketLocationSubscription;
  final List<TravelAlertModel> travelList;
  late SocketDriverDataSourceImpl socketDriver;
  StreamSubscription? _locationSubscription;
  Rx<Map<String, dynamic>?> lastLocation = Rx<Map<String, dynamic>?>(null);

  CurrentTravelController({required this.travelList}) {
    socketDriver = SocketDriverDataSourceImpl();
  }
  RxBool shouldFollowDriver = true.obs;

  RxSet<Marker> markers = <Marker>{}.obs;
  RxSet<Polyline> polylines = <Polyline>{}.obs;
  Rx<LatLng?> startLocation = Rx<LatLng?>(null);
  Rx<LatLng?> endLocation = Rx<LatLng?>(null);
  RxBool isLoading = true.obs;
  RxInt waitingFor = 0.obs;
  RxInt idStatus = 0.obs;
  RxBool isIdStatusSix = false.obs;
  RxBool isIdStatusOne = false.obs;
  // RxString waitingFor = ''.obs;
  Rx<Map<String, dynamic>?> lastDriverLocation = Rx<Map<String, dynamic>?>(null);

  GoogleMapController? mapController;
  final LatLng center = const LatLng(20.676666666667, -103.39182);
  final TravelLocalDataSource travelLocalDataSource =
      TravelLocalDataSourceImp();
  StreamSubscription<Position>? positionStreamSubscription;
  RxBool isTrackingDriver = true.obs;

  Rx<LatLng?> driverLocation = Rx<LatLng?>(null);
  RxString estimatedArrivalTime = "calculando...".obs;
  ValueNotifier<double> travelDuration = ValueNotifier(0.0);
  RxString travelPrice = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeMap();
    _initializeSocket();
  }

 void _initializeSocket() async {
  print('TaxiInfo Iniciando socket...');
  socketDriver.connect();

  if (travelList.isNotEmpty) {
    String travelId = travelList[0].id.toString();
    String idStatusString = travelList[0].id_status.toString();

    // Intentamos cargar la última ubicación conocida
    final prefs = await SharedPreferences.getInstance();
    final lastLat = prefs.getString('lastDriverLat');
    final lastLng = prefs.getString('lastDriverLng');
    final lastUpdateTime = prefs.getString('lastUpdateTime');

    if (lastLat != null && lastLng != null && idStatusString == "3") {
      final lastKnownLocation = {
        'latitude': double.parse(lastLat),
        'longitude': double.parse(lastLng)
      };
      _handleDriverLocationUpdate(lastKnownLocation);
    }

    if (idStatusString == "3") {
      isTrackingDriver.value = true;
      markers.removeWhere((m) => m.markerId == MarkerId('destination'));
      polylines.removeWhere((p) => p.polylineId == PolylineId('route'));
      
      Future.delayed(const Duration(seconds: 1), () {
        print('TaxiInfo Uniéndose al viaje: $travelId');
        socketDriver.joinTravel(travelId);
      });

      _locationSubscription = socketDriver.locationUpdates.listen((location) {
        if (isTrackingDriver.value) {
          _handleDriverLocationUpdate(location);
        }
      }, onError: (error) {
        print('TaxiInfo Error en suscripción: $error');
      });
    } else if (idStatusString == "4") {
      isTrackingDriver.value = false;
      _startRealtimeLocation();
    }
  }
}
   void _updateMarkersAndRoute(bool showDestination) {
    // Limpiamos marcadores y rutas existentes
    markers.clear();
    polylines.clear();

    // Siempre añadimos el marcador de inicio
    if (startLocation.value != null) {
      _addMarker(startLocation.value!, true);
    }

    // Solo añadimos el marcador de destino y la ruta si showDestination es true
    if (showDestination && endLocation.value != null) {
      _addMarker(endLocation.value!, false);
      _traceRoute();
    }

    // Si hay una ubicación del conductor, añadimos la polyline hacia el punto de inicio
    if (driverLocation.value != null && startLocation.value != null) {
      _addDriverToStartPolyline();
    }
  }
Future<void> _addDriverToStartPolyline() async {
  if (driverLocation.value != null && startLocation.value != null) {
    try {
      // Usamos el mismo servicio que usamos para la ruta principal
      await travelLocalDataSource.getRoute(
        driverLocation.value!,
        startLocation.value!
      );
      String encodedPoints = await travelLocalDataSource.getEncodedPoints();
      List<LatLng> polylineCoordinates = travelLocalDataSource.decodePolyline(encodedPoints);

      polylines.add(
        Polyline(
          polylineId: const PolylineId('driverToStart'),
          points: polylineCoordinates,
          color: Colors.black,
          width: 5,
        ),
      );
    } catch (e) {
      print('Error al trazar la ruta del conductor: $e');
    }
  }
}

  void _startRealtimeLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return;
  }

  markers.removeWhere((m) => m.markerId == MarkerId('start'));

  positionStreamSubscription = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ),
  ).listen((Position position) async {
    final newLocation = LatLng(position.latitude, position.longitude);
    driverLocation.value = newLocation;
    _updateDriverMarker(newLocation);
    
    // Agregar la animación de la cámara
    if (shouldFollowDriver.value && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          newLocation,
          16.0, // Puedes ajustar el nivel de zoom según necesites
        ),
      );
    }
    
    if (endLocation.value != null) {
      await _updateRouteFromCurrentLocation(newLocation);
      _updateEstimatedArrivalTime(newLocation);
    }
  });
}

  Future<void> _updateRouteFromCurrentLocation(LatLng currentLocation) async {
    if (endLocation.value != null) {
      try {
        await travelLocalDataSource.getRoute(
            currentLocation, endLocation.value!);
        String encodedPoints = await travelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            travelLocalDataSource.decodePolyline(encodedPoints);

        polylines.clear();
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylineCoordinates,
            color: Colors.black,
            width: 5,
          ),
        );
      } catch (e) {
        print('Error actualizando ruta: $e');
      }
    }
  }

 void _handleDriverLocationUpdate(Map<String, dynamic> locationData) async {
  try {
    print('TaxiInfo Recibiendo actualización de ubicación: $locationData');
    
    final newDriverLocation = LatLng(
      double.parse(locationData['latitude'].toString()),
      double.parse(locationData['longitude'].toString())
    );
    
    print('TaxiInfo Nueva ubicación del conductor: ${newDriverLocation.latitude}, ${newDriverLocation.longitude}');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastDriverLat', newDriverLocation.latitude.toString());
    await prefs.setString('lastDriverLng', newDriverLocation.longitude.toString());
    await prefs.setString('lastUpdateTime', DateTime.now().toIso8601String());
    
    driverLocation.value = newDriverLocation;
    _updateDriverMarker(newDriverLocation);
    _updateEstimatedArrivalTime(newDriverLocation);
    
    if (idStatus.value == 3) {
      markers.removeWhere((m) => m.markerId == MarkerId('destination'));
      polylines.removeWhere((p) => p.polylineId == PolylineId('route'));
      await _addDriverToStartPolyline();
    }
    
    if (shouldFollowDriver.value && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          newDriverLocation,
          16.0,
        ),
      );
    }
    
    update();
  } catch (e) {
    print('TaxiInfo Error al procesar la ubicación del conductor: $e');
  }
}



  void _updateDriverMarker(LatLng location) async {
    try {
      final markerId = MarkerId('driver');
      final updatedMarkers = Set<Marker>.from(markers);

      updatedMarkers.removeWhere((m) => m.markerId == markerId);

      final marker = Marker(
        markerId: markerId,
        position: location,
        // infoWindow: InfoWindow(title: 'Conductor'),
        icon: await gmaps.BitmapDescriptor.fromAssetImage(
          ImageConfiguration(size: Size(80, 80)),
          'assets/images/viajes/taxi2.png',
        ),
        flat: true,
        consumeTapEvents: true,
      );

      updatedMarkers.add(marker);
      markers.value = updatedMarkers;

      print('TaxiInfo Marcador del conductor actualizado');
    } catch (e) {
      print('TaxiInfo Error actualizando marcador: $e');
    }
  }

  void _updateEstimatedArrivalTime(LatLng driverLocation) {
    if (startLocation.value != null) {
      final distance = _calculateDistance(
          driverLocation.latitude,
          driverLocation.longitude,
          startLocation.value!.latitude,
          startLocation.value!.longitude);

      final averageSpeed = 30.0 * 1000 / 3600;
      final estimatedSeconds = distance / averageSpeed;
      final minutes = (estimatedSeconds / 60).round();

      if (minutes < 1) {
        estimatedArrivalTime.value = "menos de un minuto";
      } else {
        estimatedArrivalTime.value = "$minutes minutos";
      }
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }

  @override
  void onClose() {
    _locationSubscription?.cancel();
    positionStreamSubscription?.cancel();
    socketDriver.disconnect();
    super.onClose();
  }

  void updateFromNotification(TravelAlertModel updatedTravel) {
    try {
      isIdStatusSix.value = updatedTravel.id_status == 6;
      waitingFor.value = updatedTravel.waiting_for ?? 0;
      String newStatus = updatedTravel.id_status.toString();

      if (newStatus == "3") {
        isTrackingDriver.value = true;
        _locationSubscription?.cancel();
        positionStreamSubscription?.cancel();
        if (socketDriver.socketId == null) {
          _initializeSocket();
        }
        if (startLocation.value != null) {
          _addMarker(startLocation.value!, true);
        }
      } else if (newStatus == "4") {
        isTrackingDriver.value = false;
        _locationSubscription?.cancel();
        socketDriver.disconnect();
        _startRealtimeLocation();
      } else {
        _locationSubscription?.cancel();
        positionStreamSubscription?.cancel();
        socketDriver.disconnect();
      }
    } catch (e) {
      print('TaxiInfo Error en updateFromNotification: $e');
    }
  }

Future<void> _initializeMap() async {
  if (travelList.isNotEmpty) {
    var travelAlert = travelList[0];
    isIdStatusSix.value = travelAlert.id_status == 6;
    isIdStatusOne.value = travelAlert.id_status == 1;
    waitingFor.value = travelAlert.waiting_for ?? 0;

    double? startLatitude = double.tryParse(travelAlert.start_latitude);
    double? startLongitude = double.tryParse(travelAlert.start_longitude);
    double? endLatitude = double.tryParse(travelAlert.end_latitude);
    double? endLongitude = double.tryParse(travelAlert.end_longitude);

    if (startLatitude != null && startLongitude != null && 
        endLatitude != null && endLongitude != null) {
      startLocation.value = LatLng(startLatitude, startLongitude);
      endLocation.value = LatLng(endLatitude, endLongitude);

      // Solo agregamos los marcadores y la ruta si no es un viaje aceptado (status != 3)
      if (travelAlert.id_status != 3) {
        _addMarker(startLocation.value!, true);
        _addMarker(endLocation.value!, false);
        await _traceRoute();
      } else {
        _addMarker(startLocation.value!, true);
      }
    } else {
      Get.snackbar('Error', 'Error al convertir coordenadas a números');
    }

    waitingFor.value = travelAlert.waiting_for;
    idStatus.value = travelAlert.id_status;
  }
  isLoading.value = false;
}

  void _addMarker(LatLng latLng, bool isStartPlace) async {
    final String assetPath = isStartPlace
        ? 'assets/images/mapa/origen.png'
        : 'assets/images/mapa/destino.png';

    MarkerId markerId =
        isStartPlace ? MarkerId('start') : MarkerId('destination');
    String title = isStartPlace ? 'Inicio' : 'Destino';

    markers.removeWhere((m) => m.markerId == markerId);
    markers.add(
      Marker(
          markerId: markerId,
          position: latLng,
          infoWindow: InfoWindow(title: title),
          icon: await gmaps.BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(10, 10)),
            assetPath,
          )),
    );
  }

  Future<void> _traceRoute() async {
    if (startLocation.value != null && endLocation.value != null) {
      try {
        await travelLocalDataSource.getRoute(
            startLocation.value!, endLocation.value!);
        String encodedPoints = await travelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            travelLocalDataSource.decodePolyline(encodedPoints);

        polylines.clear();
        polylines.add(
          Polyline(
            polylineId: PolylineId('route'),
            points: polylineCoordinates,
            color: Colors.black,
            width: 5,
          ),
        );
      } catch (e) {
        Get.snackbar('Error', 'Error al trazar la ruta');
      }
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (startLocation.value != null) {
      mapController?.moveCamera(
        CameraUpdate.newLatLngZoom(startLocation.value!, 14.0),
      );
    }
  }

  void updateWaitingFor(int newStatus) {
    waitingFor.value = newStatus;
  }

  void updateIdStatus(int newStatus) {
    idStatus.value = newStatus;
  }
}
