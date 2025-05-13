import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/common/constants/constants.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/data/datasources/socket_driver_data_source.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/data/datasources/mapa_local_data_source.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:rayo_taxi/features/travel/presentation/page/addTravel/map_data_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'dart:io' show Platform;

class CurrentTravelController extends GetxController with WidgetsBindingObserver {
  final List<TravelAlertModel> travelList;
  late SocketDriverDataSourceImpl socketDriver;
  StreamSubscription? _locationSubscription;
  Rx<Map<String, dynamic>?> lastLocation = Rx<Map<String, dynamic>?>(null);

  // Variables para control de socket
  RxBool _isSocketConnected = false.obs;
  RxBool _isRoomJoined = false.obs;
  RxBool _isSocketOperationInProgress = false.obs;
  int _socketConnectionAttempts = 0;
  Timer? _reconnectTimer;
  bool _forceReconnectOnNextResume = false;

  CurrentTravelController({required this.travelList}) {
    // Crear una nueva instancia del socket cada vez que se inicia el controlador
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
  final MapDataController travelLocalDataSource = Get.find<MapDataController>();
  Rx<Map<String, dynamic>?> lastDriverLocation = Rx<Map<String, dynamic>?>(null);

  GoogleMapController? mapController;
  final LatLng center = const LatLng(20.676666666667, -103.39182);
 
  StreamSubscription<Position>? positionStreamSubscription;
  RxBool isTrackingDriver = true.obs;

  Rx<LatLng?> driverLocation = Rx<LatLng?>(null);
  RxString estimatedArrivalTime = "calculando...".obs;
  ValueNotifier<double> travelDuration = ValueNotifier(0.0);
  RxString travelPrice = ''.obs;

  String get _taxiImage => Platform.isIOS 
    ? 'assets/images/taxi/taxi_norte_ios.png' 
    : 'assets/images/taxi/taxi_norte.png';
  LatLng? _previousLocation;
  int _updatesReceived = 0;
  DateTime? _lastUpdateTime;

@override
void onInit() {
  super.onInit();
  WidgetsBinding.instance.addObserver(this);
  _initializeMap();
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeSocket();
  });
}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        print('TaxiInfo: App resumed - Verificando socket');
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        print('TaxiInfo: App paused - Preparando para segundo plano');
        _handleAppPaused();
        break;
      default:
        break;
    }
  }

  void _handleAppResumed() {
    if (travelList.isEmpty) return;
    
    // Verificar si ha pasado más de 10 segundos desde la última actualización
    bool needsForcedReconnect = false;
    if (_lastUpdateTime != null) {
      final elapsed = DateTime.now().difference(_lastUpdateTime!);
      needsForcedReconnect = elapsed.inSeconds > 10;
      print('TaxiInfo: ${elapsed.inSeconds} segundos desde última actualización');
    }
    
    // Solo reconectar socket si estamos exactamente en estado 3
    if (idStatus.value == 3) {
      print('TaxiInfo: Reconectando en estado 3');
      
      // Forzar reconexión completa si ha pasado mucho tiempo o si está marcado
      if (needsForcedReconnect || _forceReconnectOnNextResume) {
        _forceReconnectOnNextResume = false;
        
        print('TaxiInfo: Forzando reconexión completa');
        _isSocketConnected.value = false;
        _isRoomJoined.value = false;
        
        // Crear una nueva instancia del socket para refrescar la conexión
        socketDriver.disconnect();
        socketDriver = SocketDriverDataSourceImpl();
      }
      
      _reconnectSocketIfNeeded();
    } else if (idStatus.value == 4) {
      // En estado 4, reiniciar la ubicación en tiempo real
      _startRealtimeLocation();
    } else {
      // Asegurarse de que el socket esté desconectado en otros estados
      _disconnectSocket();
    }
  }

  void _handleAppPaused() {
    // Marcar para forzar reconexión cuando vuelva a primer plano
    _forceReconnectOnNextResume = true;
    print('TaxiInfo: Marcando para forzar reconexión en próximo resume');
    
    // Desconectar socket cuando la app va a segundo plano
    _disconnectSocket();
    
    // Cancelar stream de posición en estado 4
    if (idStatus.value == 4) {
      positionStreamSubscription?.cancel();
    }
  }

  void _reconnectSocketIfNeeded() {
    // Solo conectar si estamos exactamente en estado 3
    if (idStatus.value != 3) {
      print('TaxiInfo: No en estado 3, no se reconecta el socket');
      _disconnectSocket();
      return;
    }
    
    if (_isSocketOperationInProgress.value) {
      print('TaxiInfo: Operación en progreso, ignorando reconexión');
      return;
    }
    
    if (travelList.isEmpty) return;
    
    String travelId = travelList[0].id.toString();
    
    if (!_isSocketConnected.value) {
      _connectSocket(travelId);
    } else if (!_isRoomJoined.value) {
      _joinRoom(travelId);
    } else {
      print('TaxiInfo: Ya conectado y unido a la sala $travelId');
      
      // Verificar si las actualizaciones están llegando
      if (_lastUpdateTime != null) {
        final elapsed = DateTime.now().difference(_lastUpdateTime!);
        if (elapsed.inSeconds > 10) {
          print('TaxiInfo: No se han recibido actualizaciones en ${elapsed.inSeconds} segundos, forzando reconexión');
          _disconnectSocket();
          _connectSocket(travelId);
        }
      }
    }
  }

  void _connectSocket(String travelId) {
    // Verificar nuevamente que estemos en estado 3
    if (idStatus.value != 3) {
      print('TaxiInfo: No en estado 3, cancelando conexión de socket');
      return;
    }
    
    if (_isSocketOperationInProgress.value) return;
    
    _isSocketOperationInProgress.value = true;
    _socketConnectionAttempts++;
    
    print('TaxiInfo: Iniciando conexión al socket (intento: $_socketConnectionAttempts) para viaje $travelId');
    
    try {
      // Desconectar primero si hay una conexión previa
      if (socketDriver.socket.connected) {
        socketDriver.socket.disconnect();
      }
      
      // Limpiar suscripciones anteriores
      _locationSubscription?.cancel();
      _locationSubscription = null;
      
      // Configurar eventos del socket
      socketDriver.socket.onConnect((_) {
        print('TaxiInfo: Socket conectado con ID: ${socketDriver.socketId}');
        _isSocketConnected.value = true;
        _isSocketOperationInProgress.value = false;
        
        // Verificar estado antes de unirse a la sala
        if (idStatus.value == 3 && !_isRoomJoined.value) {
          _joinRoom(travelId);
        } else if (idStatus.value != 3) {
          // Si el estado cambió mientras nos conectábamos, desconectar
          print('TaxiInfo: Estado cambió a ${idStatus.value}, desconectando');
          _disconnectSocket();
        }
      });
      
      socketDriver.socket.onDisconnect((_) {
        print('TaxiInfo: Socket desconectado');
        _isSocketConnected.value = false;
        _isRoomJoined.value = false;
        
        // Limpiar suscripción
        _locationSubscription?.cancel();
        _locationSubscription = null;
        
        // Intentar reconectar si seguimos en estado 3
        if (idStatus.value == 3) {
          _reconnectTimer?.cancel();
          _reconnectTimer = Timer(Duration(seconds: 5), () {
            _reconnectSocketIfNeeded();
          });
        }
      });
      
      socketDriver.socket.onError((error) {
        print('TaxiInfo: Error de conexión - $error');
        _isSocketOperationInProgress.value = false;
      });
      
      // Iniciar conexión
      socketDriver.connect();
      
      // Timeout para asegurar que la bandera se libere incluso si hay problemas
      Future.delayed(const Duration(seconds: 5), () {
        _isSocketOperationInProgress.value = false;
      });
    } catch (e) {
      print('TaxiInfo: Error al conectar socket - $e');
      _isSocketOperationInProgress.value = false;
    }
  }

  void _joinRoom(String travelId) {
    // Verificar nuevamente que estemos en estado 3
    if (idStatus.value != 3) {
      print('TaxiInfo: No en estado 3, cancelando unión a sala');
      return;
    }
    
    if (_isSocketOperationInProgress.value || _isRoomJoined.value || travelId.isEmpty) return;
    
    if (!_isSocketConnected.value) {
      print('TaxiInfo: No conectado, no se puede unir a la sala');
      return;
    }
    
    _isSocketOperationInProgress.value = true;
    print('TaxiInfo: Uniéndose a la sala $travelId');
    
    try {
      socketDriver.joinTravel(travelId);
      _isRoomJoined.value = true;
      print('TaxiInfo: Unido a la sala $travelId - configurando suscripción');
      
      // Configurar suscripción DESPUÉS de unirse a la sala
      _setupLocationSubscription();
      
    } catch (e) {
      print('TaxiInfo: Error al unirse a la sala - $e');
    } finally {
      _isSocketOperationInProgress.value = false;
    }
  }

  void _disconnectSocket() {
    // Cancelar timers primero
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    if (!_isSocketConnected.value) return;
    
    print('TaxiInfo: Desconectando socket');
    try {
      _locationSubscription?.cancel();
      _locationSubscription = null;
      socketDriver.disconnect();
      _isSocketConnected.value = false;
      _isRoomJoined.value = false;
    } catch (e) {
      print('TaxiInfo: Error al desconectar socket - $e');
    }
  }

  void _setupLocationSubscription() {
    // Solo configurar suscripción si estamos en estado 3
    if (idStatus.value != 3) {
      print('TaxiInfo: No en estado 3, no se configura suscripción');
      return;
    }
    
    // Cancelar suscripción anterior si existe
    _locationSubscription?.cancel();
    
    print('TaxiInfo: Configurando nueva suscripción a actualizaciones de ubicación');
    
    _locationSubscription = socketDriver.locationUpdates.listen(
      (location) {
        if (isTrackingDriver.value && idStatus.value == 3) {
          print('TaxiInfo: Recibida actualización de ubicación: $location');
          _handleDriverLocationUpdate(location);
          
          // Configurar timer para verificar actualizaciones futuras
          _setupUpdateMonitor();
        }
      }, 
      onError: (error) {
        print('TaxiInfo: Error en suscripción - $error');
      },
      onDone: () {
        print('TaxiInfo: Suscripción terminada');
        
        // Si se cierra el stream pero deberíamos seguir conectados, reconectar
        if (idStatus.value == 3) {
          Future.delayed(Duration(seconds: 2), () {
            if (idStatus.value == 3 && !_isSocketOperationInProgress.value) {
              print('TaxiInfo: Stream cerrado, reconectando');
              _reconnectSocketIfNeeded();
            }
          });
        }
      },
      cancelOnError: false
    );
    
    print('TaxiInfo: Suscripción configurada correctamente');
  }

  void _setupUpdateMonitor() {
    // Verificar si las actualizaciones dejan de llegar
    Future.delayed(Duration(seconds: 15), () {
      if (idStatus.value == 3 && _isSocketConnected.value && _isRoomJoined.value) {
        if (_lastUpdateTime != null) {
          final elapsed = DateTime.now().difference(_lastUpdateTime!);
          if (elapsed.inSeconds > 12) {
            print('TaxiInfo: Sin actualizaciones por ${elapsed.inSeconds} segundos, reconectando');
            
            if (travelList.isNotEmpty) {
              String travelId = travelList[0].id.toString();
              _disconnectSocket();
              Future.delayed(Duration(seconds: 1), () {
                _connectSocket(travelId);
              });
            }
          }
        }
      }
    });
  }

  void _initializeSocket() async {
    print('TaxiInfo: Evaluando si iniciar socket...');
    
    if (travelList.isEmpty) return;
    
    String travelId = travelList[0].id.toString();
    int travelIdStatus = travelList[0].id_status;

    // Solo inicializar socket en estado 3
    if (travelIdStatus == 3) {
      print('TaxiInfo: En estado 3, iniciando socket para viaje $travelId...');
      isTrackingDriver.value = true;
      
      // Limpiar marcador de destino y actualizar marcador de origen
      markers.removeWhere((m) => m.markerId == MarkerId('destination'));
      if (startLocation.value != null) {
        _addMarker(startLocation.value!, true);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final lastLat = prefs.getString('lastDriverLat');
      final lastLng = prefs.getString('lastDriverLng');
      
      if (lastLat != null && lastLng != null) {
        final lastLatLng = LatLng(
          double.parse(lastLat),
          double.parse(lastLng)
        );
        
        driverLocation.value = lastLatLng;
        _updateDriverMarker(lastLatLng);
        _updateEstimatedArrivalTime(lastLatLng);
      }
      
      // Conectar el socket para estado 3
      _connectSocket(travelId);
    } else if (travelIdStatus == 4) {
      print('TaxiInfo: En estado 4, usando localización en tiempo real (sin socket)');
      // En estado 4, solo usar ubicación en tiempo real
      isTrackingDriver.value = false;
      _startRealtimeLocation();
    } else {
      print('TaxiInfo: En estado $travelIdStatus, no se inicia socket');
      // Para otros estados, asegurarse de que el socket esté desconectado
      _disconnectSocket();
    }
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

  void _startRealtimeLocation() async {
    // Cancelar suscripción anterior si existe
    positionStreamSubscription?.cancel();
    
    print('TaxiInfo: Iniciando seguimiento de ubicación en tiempo real (estado 4)');
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('TaxiInfo: Servicios de ubicación desactivados');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('TaxiInfo: Permiso de ubicación denegado');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('TaxiInfo: Permiso de ubicación denegado permanentemente');
      return;
    }

    // Asegurarse de que se muestren ambos marcadores en estado 4
    markers.clear(); // Limpiar marcadores primero
    
    if (startLocation.value != null) {
      _addMarker(startLocation.value!, true);
    }
    
    if (endLocation.value != null) {
      _addMarker(endLocation.value!, false);
    }
    
    // Establecer configuración de ubicación con alta precisión y actualizaciones frecuentes
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Actualizar cada 5 metros
      timeLimit: Duration(seconds: 10), // Tiempo máximo para obtener ubicación
    );
    
    positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      print('TaxiInfo: Nueva posición del usuario (estado 4): ${position.latitude}, ${position.longitude}');
      
      final newLocation = LatLng(position.latitude, position.longitude);
      driverLocation.value = newLocation;
      
      // Guardar la ubicación actual
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastDriverLat', position.latitude.toString());
      await prefs.setString('lastDriverLng', position.longitude.toString());
      
      // En estado 4, el marcador "driver" representa la ubicación del usuario
      _updateUserLocationMarker(newLocation);
      
      if (shouldFollowDriver.value && mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            newLocation,
            15.0, // Zoom un poco más cercano para navegación
          ),
        );
      }
      
      // Actualizar tiempo estimado al destino
      if (endLocation.value != null) {
        _updateEstimatedTimeToDestination(newLocation);
      }
    }, onError: (error) {
      print('TaxiInfo: Error obteniendo ubicación en tiempo real: $error');
    });
  }

  void _updateUserLocationMarker(LatLng location) async {
    try {
      final markerId = MarkerId('driver');
      final updatedMarkers = Set<Marker>.from(markers);
      updatedMarkers.removeWhere((m) => m.markerId == markerId);

      double bearing = 0.0;
      if (_previousLocation != null) {
        bearing = _calculateBearing(_previousLocation!, location);
      } else if (endLocation.value != null) {
        // Si no hay ubicación previa, orientar hacia el destino
        bearing = _calculateBearing(location, endLocation.value!);
      }
      
      _previousLocation = location;

      // Usar un ícono diferente cuando estamos en estado 4 (viaje en curso)
      BitmapDescriptor icon;
      try {
        // Intentar cargar un ícono que represente la ubicación actual del usuario
        icon = await gmaps.BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(80, 80)),
          _taxiImage, // Usar el mismo ícono por ahora, podrías cambiarlo por otro
        );
      } catch (e) {
        print('TaxiInfo: Error cargando imagen para ubicación actual, usando default: $e');
        icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      }

      final marker = Marker(
        markerId: markerId,
        position: location,
        icon: icon,
        flat: true,
        rotation: bearing,
        anchor: const Offset(0.5, 0.5),
        consumeTapEvents: true,
        infoWindow: InfoWindow(title: 'Tu ubicación actual'),
      );

      updatedMarkers.add(marker);
      markers.value = updatedMarkers;

      print('TaxiInfo: Marcador de ubicación actual actualizado en: ${location.latitude}, ${location.longitude}');
    } catch (e) {
      print('TaxiInfo: Error actualizando marcador de ubicación actual: $e');
    }
  }

  void _handleDriverLocationUpdate(Map<String, dynamic> locationData) async {
    try {
      // Verificar si seguimos en estado 3
      if (idStatus.value != 3) {
        print('TaxiInfo: No en estado 3, ignorando actualización de ubicación');
        return;
      }
      
      _updatesReceived++;
      _lastUpdateTime = DateTime.now();
      print('TaxiInfo: Procesando actualización #$_updatesReceived: $locationData');
      
      double latitude, longitude;
      
      // Intentar parsear los datos de diferentes formas
      if (locationData.containsKey('latitude') && locationData.containsKey('longitude')) {
        latitude = double.parse(locationData['latitude'].toString());
        longitude = double.parse(locationData['longitude'].toString());
      } else if (locationData.containsKey('location')) {
        var location = locationData['location'];
        if (location is Map) {
          latitude = double.parse(location['latitude'].toString());
          longitude = double.parse(location['longitude'].toString());
        } else {
          print('TaxiInfo: Formato de location desconocido: $location');
          return;
        }
      } else {
        print('TaxiInfo: Datos de ubicación en formato desconocido: $locationData');
        return;
      }
      
      final newDriverLocation = LatLng(latitude, longitude);
      
      print('TaxiInfo: Nueva ubicación del conductor: ${newDriverLocation.latitude}, ${newDriverLocation.longitude}');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastDriverLat', newDriverLocation.latitude.toString());
      await prefs.setString('lastDriverLng', newDriverLocation.longitude.toString());
      await prefs.setString('lastUpdateTime', DateTime.now().toIso8601String());
      
      driverLocation.value = newDriverLocation;

      // Actualizar marcador y ETA siempre
      _updateDriverMarker(newDriverLocation);
      _updateEstimatedArrivalTime(newDriverLocation);
      
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
      print('TaxiInfo: Error al procesar la ubicación del conductor: $e');
    }
  }

  void _updateDriverMarker(LatLng location) async {
    // En estado 4, utilizamos otro método para actualizar el marcador
    if (idStatus.value == 4) {
      _updateUserLocationMarker(location);
      return;
    }
    
    try {
      final markerId = MarkerId('driver');
      final updatedMarkers = Set<Marker>.from(markers);
      updatedMarkers.removeWhere((m) => m.markerId == markerId);

      double bearing = 0.0;
      if (_previousLocation != null) {
        bearing = _calculateBearing(_previousLocation!, location);
      } else if (idStatus.value == 3 && startLocation.value != null) {
        bearing = _calculateBearing(location, startLocation.value!);
      }
      
      _previousLocation = location;

      // Crear BitmapDescriptor una sola vez y reusar
      BitmapDescriptor icon;
      try {
        icon = await gmaps.BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(80, 80)),
          _taxiImage,
        );
      } catch (e) {
        print('TaxiInfo: Error cargando imagen de taxi, usando default: $e');
        icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      }

      final marker = Marker(
        markerId: markerId,
        position: location,
        icon: icon,
        flat: true,
        rotation: bearing,
        anchor: const Offset(0.5, 0.5),
        consumeTapEvents: true,
        infoWindow: InfoWindow(title: 'Conductor'),
      );

      updatedMarkers.add(marker);
      markers.value = updatedMarkers;

      print('TaxiInfo: Marcador del conductor actualizado en: ${location.latitude}, ${location.longitude} con rotación: $bearing');
    } catch (e) {
      print('TaxiInfo: Error actualizando marcador: $e');
    }
  }

  void _updateEstimatedArrivalTime(LatLng driverLocation) {
    if (startLocation.value != null) {
      final distance = _calculateDistance(
          driverLocation.latitude,
          driverLocation.longitude,
          startLocation.value!.latitude,
          startLocation.value!.longitude);

      final averageSpeed = 30.0 * 1000 / 3600; // 30 km/h en m/s
      final estimatedSeconds = distance / averageSpeed;
      final minutes = (estimatedSeconds / 60).round();

      if (minutes < 1) {
        estimatedArrivalTime.value = "menos de un minuto";
      } else {
        estimatedArrivalTime.value = "$minutes minutos";
      }
    }
  }

  void _updateEstimatedTimeToDestination(LatLng userLocation) {
    if (endLocation.value != null) {
      final distance = _calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          endLocation.value!.latitude,
          endLocation.value!.longitude);

      final averageSpeed = 30.0 * 1000 / 3600; // 30 km/h en m/s
      final estimatedSeconds = distance / averageSpeed;
      final minutes = (estimatedSeconds / 60).round();

      if (minutes < 1) {
        estimatedArrivalTime.value = "menos de un minuto al destino";
      } else {
        estimatedArrivalTime.value = "$minutes minutos al destino";
      }
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }

  @override
  void onClose() {
    // Cancelar observer de ciclo de vida
    WidgetsBinding.instance.removeObserver(this);
    
    // Limpiar recursos
    _locationSubscription?.cancel();
    positionStreamSubscription?.cancel();
    _reconnectTimer?.cancel();
    
    // Desconectar socket
    _disconnectSocket();
    
    super.onClose();
  }

  void updateFromNotification(TravelAlertModel updatedTravel) {
    try {
      int oldStatus = idStatus.value;
      
      // Actualizar estados
      isIdStatusSix.value = updatedTravel.id_status == 6;
      waitingFor.value = updatedTravel.waiting_for ?? 0;
      idStatus.value = updatedTravel.id_status;
      
      print('TaxiInfo: Estado cambió de $oldStatus a ${updatedTravel.id_status}');

      if (updatedTravel.id_status == 3) {
        // Si es estado 3, activar socket
        isTrackingDriver.value = true;
        
        // Limpiar recursos anteriores
        _locationSubscription?.cancel();
        positionStreamSubscription?.cancel();
        
        // Solo mostrar el punto de inicio en estado 3
        markers.clear();
        if (startLocation.value != null) {
          _addMarker(startLocation.value!, true);
        }
        
        // Reconectar socket
        _reconnectSocketIfNeeded();
      } else {
        // Para cualquier otro estado, desconectar socket
        isTrackingDriver.value = updatedTravel.id_status == 4;
        _disconnectSocket();
        
        if (updatedTravel.id_status == 4) {
          // En estado 4, usar localización en tiempo real
          // Mostrar ambos marcadores
          markers.clear();
          if (startLocation.value != null) {
            _addMarker(startLocation.value!, true);
          }
          if (endLocation.value != null) {
            _addMarker(endLocation.value!, false);
          }
          
          _startRealtimeLocation();
        } else {
          // Para otros estados, limpiar recursos
          positionStreamSubscription?.cancel();
        }
      }
    } catch (e) {
      print('TaxiInfo: Error en updateFromNotification: $e');
    }
  }

  Future<void> _initializeMap() async {
    if (travelList.isNotEmpty) {
      var travelAlert = travelList[0];
      isIdStatusSix.value = travelAlert.id_status == 6;
      isIdStatusOne.value = travelAlert.id_status == 1;
      waitingFor.value = travelAlert.waiting_for ?? 0;
      idStatus.value = travelAlert.id_status;

      print('TaxiInfo: Inicializando mapa para viaje ${travelAlert.id} en estado ${travelAlert.id_status}');

      double? startLatitude = double.tryParse(travelAlert.start_latitude);
      double? startLongitude = double.tryParse(travelAlert.start_longitude);
      double? endLatitude = double.tryParse(travelAlert.end_latitude);
      double? endLongitude = double.tryParse(travelAlert.end_longitude);

      if (startLatitude != null && startLongitude != null && 
          endLatitude != null && endLongitude != null) {
        startLocation.value = LatLng(startLatitude, startLongitude);
        endLocation.value = LatLng(endLatitude, endLongitude);

        // Solo añadir marcadores según el estado
        if (travelAlert.id_status != 3) {
          _addMarker(startLocation.value!, true);
          _addMarker(endLocation.value!, false);
        } else {
          _addMarker(startLocation.value!, true);
        }
      } else {
        Get.snackbar('Error', 'Error al convertir coordenadas a números');
      }
      
      // Inicializar socket después de configurar datos
      // Solo para estado 3
      Future.delayed(Duration(milliseconds: 500), () {
        if (travelAlert.id_status == 3) {
          _initializeSocket();
        }
      });
    }
    isLoading.value = false;
  }


void _addMarker(LatLng latLng, bool isStartPlace) async {
  final markerId = isStartPlace ? MarkerId('start') : MarkerId('destination');
  final String title = isStartPlace ? 'Punto de recogida' : 'Destino';

  markers.removeWhere((m) => m.markerId == markerId);
  
  BitmapDescriptor icon;
  try {
    // Determinar la ruta de la imagen según la plataforma
    String imagePath;
    if (isStartPlace) {
      imagePath = Platform.isAndroid 
        ? 'assets/images/mapa/origen-android.png' 
        : 'assets/images/mapa/origen-ios.png';
    } else {
      imagePath = Platform.isAndroid 
        ? 'assets/images/mapa/destino-android.png' 
        : 'assets/images/mapa/destino-ios.png';
    }
    
    icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(10, 10)),
      imagePath,
    );
  } catch (e) {
    print('TaxiInfo: Error cargando icono, usando default: $e');
    icon = isStartPlace ? 
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen) :
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }
  
  markers.add(
    Marker(
      markerId: markerId,
      position: latLng,
      icon: icon,
      onTap: () {
        travelLocalDataSource.showLocationPreview(latLng, title);
      }
    ),
  );
  
  print('TaxiInfo: Marcador ${isStartPlace ? "de origen" : "de destino"} añadido en: ${latLng.latitude}, ${latLng.longitude}');
}

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (startLocation.value != null) {
      mapController?.moveCamera(
        CameraUpdate.newLatLngZoom(startLocation.value!, 14.0),
      );
    }
    
    print('TaxiInfo: Mapa creado');
    
    // Verificar si necesitamos iniciar socket después de que el mapa esté listo
    if (idStatus.value == 3 && !_isSocketConnected.value) {
      Future.delayed(Duration(milliseconds: 500), () {
        _reconnectSocketIfNeeded();
      });
    }
  }

  void updateWaitingFor(int newStatus) {
    waitingFor.value = newStatus;
  }

  void updateIdStatus(int newStatus) {
    int oldStatus = idStatus.value;
    idStatus.value = newStatus;
    
    // Gestionar socket si cambia el estado
    if (oldStatus != newStatus) {
      print('TaxiInfo: Estado cambió de $oldStatus a $newStatus');
      
      if (newStatus == 3) {
        // Activar socket solo en estado 3
        _reconnectSocketIfNeeded();
      } else {
        // Desconectar en cualquier otro estado
        _disconnectSocket();
        
        if (newStatus == 4) {
          // En estado 4, usar localización en tiempo real
          _startRealtimeLocation();
        }
      }
    }
  }
}