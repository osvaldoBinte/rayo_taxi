import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
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

  final String _taxiImage = 'assets/images/taxi/taxi_norte.png';
    LatLng? _previousLocation;
final int _routeUpdateThresholdDistance = 100; // en metros
final Duration _minRouteUpdateInterval = Duration(seconds: 30);
DateTime? _lastRouteUpdateTime;
LatLng? _lastRouteUpdateLocation;

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

    final prefs = await SharedPreferences.getInstance();
    final lastLat = prefs.getString('lastDriverLat');
    final lastLng = prefs.getString('lastDriverLng');
    final lastUpdateTime = prefs.getString('lastUpdateTime');

    if (lastLat != null && lastLng != null && idStatusString == "3") {
      final lastKnownLocation = {
        'latitude': double.parse(lastLat),
        'longitude': double.parse(lastLng)
      };
      
      final lastLatLng = LatLng(
        double.parse(lastLat),
        double.parse(lastLng)
      );
      
      driverLocation.value = lastLatLng;
      
      _updateDriverMarker(lastLatLng);
      
      _updateEstimatedArrivalTime(lastLatLng);
      if (startLocation.value != null) {
        _addDriverToStartPolyline();
      }
      
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
}void _updateDriverMarker(LatLng location) async {
  try {
    final markerId = MarkerId('driver');
    final updatedMarkers = Set<Marker>.from(markers);
    updatedMarkers.removeWhere((m) => m.markerId == markerId);

    double bearing = 0.0;
    if (_previousLocation != null) {
      bearing = _calculateBearing(_previousLocation!, location);
    } else if (idStatus.value == 3 && startLocation.value != null) {
      bearing = _calculateBearing(location, startLocation.value!);
    } else if (idStatus.value == 4 && endLocation.value != null) {
      bearing = _calculateBearing(location, endLocation.value!);
    }
    
    _previousLocation = location;

    final marker = Marker(
      markerId: markerId,
      position: location,
      icon: await gmaps.BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(80, 80)),
        _taxiImage,
      ),
      flat: true,
      rotation: bearing,
      anchor: const Offset(0.5, 0.5),
      consumeTapEvents: true,
    );

    updatedMarkers.add(marker);
    markers.value = updatedMarkers;

    print('TaxiInfo Marcador del conductor actualizado con rotación: $bearing');
  } catch (e) {
    print('TaxiInfo Error actualizando marcador: $e');
  }
}
 LatLng? _getPointInPolyline(List<LatLng> points, double fraction) {
    if (points.isEmpty) return null;
    if (points.length == 1) return points[0];
    
    double totalDistance = 0;
    List<double> distances = [];
    
    for (int i = 0; i < points.length - 1; i++) {
      double segmentDistance = _calculateDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude
      );
      totalDistance += segmentDistance;
      distances.add(segmentDistance);
    }
    
    double targetDistance = totalDistance * fraction;
    double currentDistance = 0;
    
    for (int i = 0; i < distances.length; i++) {
      if (currentDistance + distances[i] > targetDistance) {
        double segmentFraction = (targetDistance - currentDistance) / distances[i];
        return LatLng(
          points[i].latitude + (points[i + 1].latitude - points[i].latitude) * segmentFraction,
          points[i].longitude + (points[i + 1].longitude - points[i].longitude) * segmentFraction
        );
      }
      currentDistance += distances[i];
    }
    
    return points.last;
  }


    double _calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * pi / 180;
    double lat2 = end.latitude * pi / 180;
    double long1 = start.longitude * pi / 180;
    double long2 = end.longitude * pi / 180;

    double dLon = (long2 - long1);

    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    double bearing = atan2(y, x);
    bearing = bearing * 180 / pi;
    bearing = (bearing + 360) % 360;

    return bearing;
  }


   void _updateMarkersAndRoute(bool showDestination) {
    markers.clear();
    polylines.clear();

    if (startLocation.value != null) {
      _addMarker(startLocation.value!, true);
    }

    if (showDestination && endLocation.value != null) {
      _addMarker(endLocation.value!, false);
      _traceRoute();
    }

    if (driverLocation.value != null && startLocation.value != null) {
      _addDriverToStartPolyline();
    }
  }
Future<void> _addDriverToStartPolyline() async {
  if (driverLocation.value != null && startLocation.value != null) {
    try {
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
    
    // Guardar la ubicación actual
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastDriverLat', position.latitude.toString());
    await prefs.setString('lastDriverLng', position.longitude.toString());
    
    _updateDriverMarker(newLocation);
    
    if (shouldFollowDriver.value && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          newLocation,
          14.0,
        ),
      );
    }
    
    if (endLocation.value != null) {
      // Solo actualizar la ruta si es necesario
      if (_shouldUpdateRoute(newLocation)) {
        await _updateRouteFromCurrentLocation(newLocation);
        _lastRouteUpdateTime = DateTime.now();
        _lastRouteUpdateLocation = newLocation;
      }
      
      // Siempre actualizar el tiempo estimado (es una operación local rápida)
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

    // Siempre actualizar el marcador del conductor
    _updateDriverMarker(newDriverLocation);
    
    if (idStatus.value == 3) {
      // Actualizar el tiempo estimado siempre es rápido y no requiere API
      _updateEstimatedArrivalTime(newDriverLocation);
      
      // Solo actualizar polyline si es necesario
      if (_shouldUpdateRoute(newDriverLocation)) {
        markers.removeWhere((m) => m.markerId == MarkerId('destination'));
        polylines.removeWhere((p) => p.polylineId == PolylineId('route'));
        await _addDriverToStartPolyline();
        
        // Recordar cuándo y dónde se actualizó la ruta
        _lastRouteUpdateTime = DateTime.now();
        _lastRouteUpdateLocation = newDriverLocation;
      }
    }
    
    if (shouldFollowDriver.value && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          newDriverLocation,
          14.0,
        ),
      );
    }
    
    update();
  } catch (e) {
    print('TaxiInfo Error al procesar la ubicación del conductor: $e');
  }
}bool _shouldUpdateRoute(LatLng currentLocation) {
  // Si es la primera actualización, siempre trazar la ruta
  if (_lastRouteUpdateTime == null || _lastRouteUpdateLocation == null) {
    return true;
  }
  
  // Comprobar si ha pasado suficiente tiempo desde la última actualización
  bool timeThresholdMet = DateTime.now().difference(_lastRouteUpdateTime!) > _minRouteUpdateInterval;
  
  // Si no ha pasado suficiente tiempo, no actualizar
  if (!timeThresholdMet) {
    return false;
  }
  
  // Comprobar si la distancia ha cambiado significativamente
  double distance = _calculateDistance(
    _lastRouteUpdateLocation!.latitude,
    _lastRouteUpdateLocation!.longitude,
    currentLocation.latitude,
    currentLocation.longitude
  );
  
  // Solo actualizar si se ha movido más de la distancia umbral
  return distance > _routeUpdateThresholdDistance;
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
  final markerId = isStartPlace ? MarkerId('start') : MarkerId('destination');
  final String title = isStartPlace ? 'Punto de recogida' : 'Destino';
  
  // Crear la URL de la imagen estática de Google Maps
  final String staticMapUrl = 'https://maps.googleapis.com/maps/api/staticmap?'
    'center=${latLng.latitude},${latLng.longitude}'
    '&zoom=18'
    '&size=150x150'
    '&maptype=roadmap'
    '&markers=color:red%7C${latLng.latitude},${latLng.longitude}'
    '&key=AIzaSyBAVJDSpCXiLRhVTq-MA3RgZqbmxm1wD1I';  // Reemplaza con tu API key

  markers.removeWhere((m) => m.markerId == markerId);
  markers.add(
    Marker(
      markerId: markerId,
      position: latLng,
      icon: await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        isStartPlace ? 'assets/images/mapa/origen.png' : 'assets/images/mapa/destino.png',
      ),
       onTap: () {
          _showLocationPreview(latLng, title);
        }
    ),
  );
}void _showLocationPreview(LatLng location, String title) {
  final colorScheme = Theme.of(Get.context!).colorScheme;
  final String streetViewUrl = 'https://maps.googleapis.com/maps/api/streetview?'
    'size=600x400'
    '&location=${location.latitude},${location.longitude}'
    '&fov=90'
    '&heading=70'
    '&pitch=0'
    '&key=AIzaSyBAVJDSpCXiLRhVTq-MA3RgZqbmxm1wD1I';

  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: Get.width * 0.85,
        decoration: BoxDecoration(
          color: colorScheme.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera
            Container(
              padding: EdgeInsets.fromLTRB(20, 16, 8, 16),
              decoration: BoxDecoration(
                color: colorScheme.backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.textButton,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.CurvedNavigationIcono2),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            // Contenedor de imagen
            Container(
              height: Get.height * 0.3,
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.loaderbaseColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      streetViewUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: colorScheme.loaderbaseColor,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.loader),
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.loaderbaseColor,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: colorScheme.icongrey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Vista no disponible',
                                style: TextStyle(
                                  color: colorScheme.snackBartext2,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Overlay con coordenadas
                    
                  ],
                ),
              ),
            ),
            // Botones de acción
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.buttonColormap,
                      foregroundColor: colorScheme.textButton,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    barrierColor: Colors.black54,
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
        print('Error al trazar la ruta $e');
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
