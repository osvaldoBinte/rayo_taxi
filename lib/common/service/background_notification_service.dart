import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Canal para comunicación entre isolate de background y UI
const String backgroundIsolateName = 'backgroundNotificationIsolate';
const String _lastNotificationKey = 'lastNotification';

// Esta función se ejecutará en segundo plano cuando llega una notificación
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  // Guarda los datos de la notificación para procesarlos cuando la app se reactive
  final prefs = await SharedPreferences.getInstance();
  final notificationData = json.encode({
    'notification': {
      'title': message.notification?.title,
      'body': message.notification?.body,
    },
    'data': message.data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
  
  await prefs.setString(_lastNotificationKey, notificationData);
  
  // Envía un mensaje al isolate principal si está activo
  final SendPort? sendPort = IsolateNameServer.lookupPortByName(backgroundIsolateName);
  if (sendPort != null) {
    sendPort.send('notification_received');
  }
  
  // Crear una notificación local para asegurar que el usuario la vea
  await _showLocalNotification(message);
  
  print('Notificación recibida en segundo plano: ${message.notification?.title}');
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.max,
    priority: Priority.high,
  );
  
  const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
  
  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title ?? 'Nueva notificación',
    message.notification?.body ?? '',
    platformDetails,
  );
}

// Inicializa el servicio de notificaciones
Future<void> setupBackgroundNotifications() async {
  // Puerto para comunicación entre isolates
  final ReceivePort receivePort = ReceivePort();
  bool isRegistered = IsolateNameServer.registerPortWithName(
    receivePort.sendPort,
    backgroundIsolateName,
  );
  
  if (!isRegistered) {
    IsolateNameServer.removePortNameMapping(backgroundIsolateName);
    IsolateNameServer.registerPortWithName(
      receivePort.sendPort,
      backgroundIsolateName,
    );
  }
  
  // Configurar para recibir mensajes del background isolate
  receivePort.listen((dynamic message) {
    if (message == 'notification_received') {
      // Gatillar actualización de datos cuando llegue notificación
      _triggerDataUpdate();
    }
  });
  
  // Configurar notificaciones locales
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  
  await FlutterLocalNotificationsPlugin().initialize(initializationSettings);
  
  // Registrar handler para mensajes en background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

void _triggerDataUpdate() async {
  // Este método será llamado cuando llegue una notificación en segundo plano
  
  // Intentamos actualizar datos a través de SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('force_update_on_resume', true);
  await prefs.setInt('last_notification_timestamp', 
      DateTime.now().millisecondsSinceEpoch);
}