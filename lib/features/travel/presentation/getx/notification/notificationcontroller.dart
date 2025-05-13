import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rayo_taxi/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class NotificationController extends GetxController with WidgetsBindingObserver {
  RxBool tripAccepted = false.obs;
  var lastNotification = Rxn<RemoteMessage>();
  var lastNotificationTitle = ''.obs;
  var lastNotificationBody = ''.obs;
  var lastNotificationType = ''.obs;
  var lastTravelId = ''.obs;
  
  var hasPendingNotification = false.obs;
  var isProcessingNotification = false.obs;

  static const String _lastNotificationKey = 'lastNotification';
  static const String _lastTravelIdKey = 'lastTravelId';
  static const String _timestampKey = 'notification_timestamp';
  
  bool _isProcessing = false;
  int _lastProcessedTimestamp = 0;

  @override
  void onInit() async {
    super.onInit();
    
    WidgetsBinding.instance.addObserver(this);
    
    await _checkStoredData();
    
    await loadLastNotification();

    _setupNotificationListeners();
  }
  
  Future<void> _checkStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      print('DEBUG: Claves en SharedPreferences al inicio: $keys');
      
      if (prefs.containsKey(_lastNotificationKey)) {
        final notifData = prefs.getString(_lastNotificationKey);
        print('DEBUG: Hay notificación almacenada (longitud: ${notifData?.length})');
      }
      
      if (prefs.containsKey(_lastTravelIdKey)) {
        final travelId = prefs.getString(_lastTravelIdKey);
        print('DEBUG: Travel ID almacenado: $travelId');
      }
      
      if (prefs.containsKey(_timestampKey)) {
        final timestamp = prefs.getInt(_timestampKey);
        final now = DateTime.now().millisecondsSinceEpoch;
        final secondsAgo = (now - (timestamp ?? 0)) / 1000;
        print('DEBUG: Notificación recibida hace $secondsAgo segundos');
      }
    } catch (e) {
      print('ERROR en _checkStoredData: $e');
    }
  }
  
  void _setupNotificationListeners() {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('DEBUG: Recibida notificación inicial (cold start)');
        updateNotification(message);
      }
    });

    FirebaseMessaging.onMessage.listen((message) {
      print('DEBUG: Recibida notificación en primer plano');
      updateNotification(message);
    });

    // Para notificaciones cuando se hace clic mientras la app está en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('DEBUG: App abierta desde notificación');
      updateNotification(message);
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      print('DEBUG: App resumed en NotificationController');
      
      // Verificar al volver a primer plano si hay notificaciones
      await _checkStoredData();
      await loadLastNotification();
    }
  }

  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      // Guardar la notificación en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Guardar la notificación completa
      final messageJson = message.toMap();
      await prefs.setString(_lastNotificationKey, jsonEncode(messageJson));
      
      // 2. Guardar el ID del viaje por separado para mayor seguridad
      if (message.data.containsKey('travel')) {
        await prefs.setString(_lastTravelIdKey, message.data['travel']);
      } else if (message.data.containsKey('travel_id')) {
        await prefs.setString(_lastTravelIdKey, message.data['travel_id']);
      }
      
      // 3. Guardar timestamp para saber cuándo se recibió
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);

      print('DEBUG: Notificación background guardada: ${message.notification?.title}');
      
      // Verificar que se guardó correctamente
      final storedNotif = prefs.getString(_lastNotificationKey);
      if (storedNotif != null) {
        print('DEBUG: Verificado: notificación guardada (${storedNotif.length} bytes)');
      } else {
        print('ERROR: No se pudo verificar la notificación guardada');
      }
    } catch (e) {
      print('ERROR en background handler: $e');
    }
  }
  
  Future<void> updateNotification(RemoteMessage message) async {
    // Prevenir procesamiento simultáneo
    if (_isProcessing) {
      print('DEBUG: Ya procesando notificación, esperando...');
      await Future.delayed(Duration(milliseconds: 200));
      if (_isProcessing) return; // Si todavía está procesando, salir
    }
    
    _isProcessing = true;
    isProcessingNotification.value = true;
    
    try {
      final notification = message.notification;
      if (notification != null) {
        print('DEBUG: Procesando notificación: ${notification.title}');
        
        // Actualizar valores reactivos
        lastNotificationTitle.value = notification.title ?? 'Notificación';
        lastNotificationBody.value = notification.body ?? 'Tienes una nueva notificación';
        lastNotification.value = message;
        
        // Extraer y guardar el ID del viaje
        if (message.data.containsKey('travel')) {
          lastTravelId.value = message.data['travel'];
          print('DEBUG: ID de viaje extraído (travel): ${lastTravelId.value}');
        } else if (message.data.containsKey('travel_id')) {
          lastTravelId.value = message.data['travel_id'];
          print('DEBUG: ID de viaje extraído (travel_id): ${lastTravelId.value}');
        } else {
          print('DEBUG: No se encontró ID de viaje. Claves: ${message.data.keys.join(", ")}');
        }
        
        // Determinar tipo de notificación
        if (notification.title == 'Tu viaje fue aceptado' || 
            notification.title == 'Contraoferta aceptada por el conductor') {
          lastNotificationType.value = 'trip_accepted';
          tripAccepted.value = true;
        } else if (notification.title == 'Nuevo precio para tu viaje') {
          lastNotificationType.value = 'new_price';
        } else if (notification.title == 'Tu viaje ha comenzado') {
          lastNotificationType.value = 'trip_started';
          tripAccepted.value = true;
        } else if (notification.title == 'El taxi llego') {
          lastNotificationType.value = 'taxi_arrived';
          tripAccepted.value = true;
        } else if (notification.title == 'Viaje terminado') {
          lastNotificationType.value = 'trip_ended';
          tripAccepted.value = true;
        } else {
          lastNotificationType.value = 'general';
        }
        
        hasPendingNotification.value = true;
        
        await _saveLastNotification(message);
        
        _lastProcessedTimestamp = DateTime.now().millisecondsSinceEpoch;
        
        print('DEBUG: Notificación procesada y guardada correctamente');
      }
    } catch (e) {
      print('ERROR en updateNotification: $e');
    } finally {
      _isProcessing = false;
      isProcessingNotification.value = false;
    }
  }

  Future<void> clearNotification() async {
    try {
      print('DEBUG: Limpiando datos de notificación');
      
      // Limpiar valores reactivos
      lastNotificationTitle.value = '';
      lastNotificationBody.value = '';
      lastNotificationType.value = '';
      lastNotification.value = null;
      lastTravelId.value = '';
      hasPendingNotification.value = false;
      
      // Nota: No limpiamos tripAccepted aquí para mantener el estado de la UI,
      // eso debería hacerse explícitamente cuando sea apropiado
      
      // Limpiar de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastNotificationKey);
      await prefs.remove(_lastTravelIdKey);
      await prefs.remove(_timestampKey);
      
      print('DEBUG: Notificación limpiada completamente');
    } catch (e) {
      print('ERROR en clearNotification: $e');
    }
  }

  Future<void> _saveLastNotification(RemoteMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Guardar mensaje completo
      final messageJson = message.toMap();
      await prefs.setString(_lastNotificationKey, jsonEncode(messageJson));
      
      // 2. Guardar ID del viaje por separado
      if (message.data.containsKey('travel')) {
        await prefs.setString(_lastTravelIdKey, message.data['travel']);
      } else if (message.data.containsKey('travel_id')) {
        await prefs.setString(_lastTravelIdKey, message.data['travel_id']);
      }
      
      // 3. Guardar timestamp
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
      
      print('DEBUG: Notificación guardada en SharedPreferences');
      
      // Verificar que se guardó correctamente
      final storedNotif = prefs.getString(_lastNotificationKey);
      if (storedNotif != null) {
        print('DEBUG: Verificado: notificación guardada (${storedNotif.length} bytes)');
      }
    } catch (e) {
      print('ERROR en _saveLastNotification: $e');
    }
  }

  Future<void> loadLastNotification() async {
    if (_isProcessing) {
      print('DEBUG: Ya procesando, saltando carga');
      return;
    }
    
    _isProcessing = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      
      final storedMessage = prefs.getString(_lastNotificationKey);
      if (storedMessage != null && storedMessage.isNotEmpty) {
        try {
          print('DEBUG: Cargando notificación guardada...');
          
          final Map<String, dynamic> messageMap = jsonDecode(storedMessage);
          final message = RemoteMessage.fromMap(messageMap);
          
          lastNotification.value = message;
          
          final notification = message.notification;
          if (notification != null) {
            lastNotificationTitle.value = notification.title ?? 'Notificación';
            lastNotificationBody.value = notification.body ?? 'Tienes una nueva notificación';
            
            if (notification.title == 'Tu viaje fue aceptado' || 
                notification.title == 'Contraoferta aceptada por el conductor') {
              lastNotificationType.value = 'trip_accepted';
              tripAccepted.value = true;
            } else if (notification.title == 'Nuevo precio para tu viaje') {
              lastNotificationType.value = 'new_price';
            } else if (notification.title == 'Tu viaje ha comenzado') {
              lastNotificationType.value = 'trip_started';
              tripAccepted.value = true;
            } else if (notification.title == 'El taxi llego') {
              lastNotificationType.value = 'taxi_arrived';
              tripAccepted.value = true;
            } else if (notification.title == 'Viaje terminado') {
              lastNotificationType.value = 'trip_ended';
              tripAccepted.value = true;
            } else {
              lastNotificationType.value = 'general';
            }
          }
          
          // Extraer ID del viaje
          if (message.data.containsKey('travel')) {
            lastTravelId.value = message.data['travel'];
            print('DEBUG: ID de viaje cargado (travel): ${lastTravelId.value}');
          } else if (message.data.containsKey('travel_id')) {
            lastTravelId.value = message.data['travel_id'];
            print('DEBUG: ID de viaje cargado (travel_id): ${lastTravelId.value}');
          } else {
            // Si no está en el mensaje, intentar cargar del valor separado
            final separateTravelId = prefs.getString(_lastTravelIdKey);
            if (separateTravelId != null && separateTravelId.isNotEmpty) {
              lastTravelId.value = separateTravelId;
              print('DEBUG: ID de viaje cargado (valor separado): ${lastTravelId.value}');
            }
          }
          
          // Verificar timestamp
          final timestamp = prefs.getInt(_timestampKey) ?? 0;
          final now = DateTime.now().millisecondsSinceEpoch;
          final secondsAgo = (now - timestamp) / 1000;
          
          print('DEBUG: Notificación cargada (recibida hace $secondsAgo seg)');
          hasPendingNotification.value = true;
        } catch (e) {
          print('ERROR al parsear notificación guardada: $e');
        }
      } else {
        // Si no hay notificación completa, verificar si hay ID de viaje separado
        final travelId = prefs.getString(_lastTravelIdKey);
        if (travelId != null && travelId.isNotEmpty) {
          lastTravelId.value = travelId;
          hasPendingNotification.value = true;
          print('DEBUG: Solo se encontró ID de viaje: $travelId');
        } else {
          print('DEBUG: No se encontró notificación guardada');
          hasPendingNotification.value = false;
        }
      }
    } catch (e) {
      print('ERROR en loadLastNotification: $e');
    } finally {
      _isProcessing = false;
    }
  }
  
  Future<void> forceStoreTestNotification() async {
    try {
      final testData = {
        'notification': {
          'title': 'Notificación de prueba',
          'body': 'Este es un mensaje de prueba'
        },
        'data': {
          'travel': '12345'
        }
      };
      
      final testMessage = RemoteMessage.fromMap(testData);
      await updateNotification(testMessage);
      
      print('DEBUG: Notificación de prueba guardada');
    } catch (e) {
      print('ERROR en forceStoreTestNotification: $e');
    }
  }
}
class ModalController extends GetxController {
  var lottieUrl = 'https://lottie.host/0430a89e-3317-4d46-8dc8-a8a090712c51/HnCUuYzAkG.lottie'.obs;
  var imageUrl = 'assets/images/viajes/add_travel.gif'.obs;
  var modalText = 'Buscando chofer...'.obs;
  var isLottieError = false.obs;
}