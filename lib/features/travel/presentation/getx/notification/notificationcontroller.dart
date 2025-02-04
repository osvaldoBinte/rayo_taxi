// notificationcontroller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

class NotificationController extends GetxController
    with WidgetsBindingObserver {
  RxBool tripAccepted = false.obs;
  var lastNotification = Rxn<RemoteMessage>();
  var lastNotificationTitle = ''.obs;
  var lastNotificationBody = ''.obs;
  var lastNotificationType = ''.obs;
  final ModalController modalController = Get.find<ModalController>();
  // final currentTravelGetx = Get.find<CurrentTravelGetx>();
  //final travelAlertGetx = Get.find<TravelsAlertGetx>();

  static const String _lastNotificationKey = 'lastNotification';
  Timer? _clearNotificationTimer;
  @override
  void onInit() async {
    super.onInit();

    if (!Get.isRegistered<ModalController>()) {
      Get.put(ModalController());
    }

    await _initializeNotifications();
    WidgetsBinding.instance.addObserver(this);

    await loadLastNotification();
  }

  Future<void> _initializeNotifications() async {
    await loadLastNotification();

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        updateNotification(message);
      }
    });

    FirebaseMessaging.onMessage.listen((message) {
      updateNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      updateNotification(message);
    });
  }

  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);

      // Guardamos la notificación en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final messageJson = message.toMap();
      await prefs.setString('lastNotification', jsonEncode(messageJson));

      print('DEBUG: Mensaje recibido en segundo plano');
      print('DEBUG: Título del mensaje: ${message.notification?.title}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        print("Procesando notificación en segundo plano");

        // Aseguramos que los controladores estén registrados
        if (!Get.isRegistered<ModalController>()) {
          Get.put(ModalController());
        }
        if (!Get.isRegistered<NotificationController>()) {
          Get.put(NotificationController());
        }

        // Obtenemos las instancias existentes
        final notificationController = Get.find<NotificationController>();
        final modalController = Get.find<ModalController>();

        // Procesamos la notificación
        switch (notification.title) {
          case 'Tu viaje fue aceptado':
            print('DEBUG: Procesando - Tu viaje fue aceptado');
            await _handleTripAccepted(notificationController, modalController);
            break;
          case 'Nuevo precio para tu viaje':
            print('DEBUG: Procesando - negosiando');
            await _handleNegotiatingrate(
                notificationController, modalController);
            break;
          case 'Tu viaje ha comenzado':
            print('DEBUG: Procesando - Tu viaje ha comenzado');
            await _handleTripStarted(notificationController, modalController);
            break;
          case 'El taxi llego':
            print('DEBUG: Procesando - El taxi llegó');
            await _handleTaxiArrived(notificationController, modalController);
            break;
          case 'Viaje terminado':
            print('DEBUG: Procesando - Viaje terminado');
            await _handleTripEnded(notificationController, modalController);
            break;
        }

        // Forzamos una actualización de la UI
        Get.forceAppUpdate();
      }
    } catch (e) {
      print('ERROR en background handler: $e');
    }
  }

static Future<void> _handleTripAccepted(
    NotificationController notificationController,
    ModalController modalController) async {
  notificationController.tripAccepted.value = true;
  modalController.imageUrl.value = 'assets/images/viajes/viaje-aceptado.gif';
  modalController.modalText.value = 'Viaje aceptado, espera al conductor en el punto de encuentro';
}

static Future<void> _handleNegotiatingrate(
    NotificationController notificationController,
    ModalController modalController) async {
  notificationController.tripAccepted.value = true;
  modalController.imageUrl.value = 'assets/images/viajes/viaje-desconocido.gif';
  modalController.modalText.value = 'El conductor ha recibido tu solicitud. Por favor, espera mientras se negocia la tarifa del viaje.';
}

static Future<void> _handleTripStarted(
    NotificationController notificationController,
    ModalController modalController) async {
  notificationController.tripAccepted.value = true;
  modalController.imageUrl.value = 'assets/images/viajes/viaje-ha-comenzado.gif';
  modalController.modalText.value = 'Tu viaje ha comenzado';
}

static Future<void> _handleTaxiArrived(
    NotificationController notificationController,
    ModalController modalController) async {
  notificationController.tripAccepted.value = true;
  modalController.imageUrl.value = 'assets/images/viajes/taxi-llego.gif';
  modalController.modalText.value = 'El taxi ha llegado al punto de encuentro';
}

static Future<void> _handleTripEnded(
    NotificationController notificationController,
    ModalController modalController) async {
  notificationController.tripAccepted.value = true;
  modalController.imageUrl.value = 'assets/images/viajes/viaje-finalizado.gif';
  modalController.modalText.value = 'Tu viaje a terminado';
}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      print('DEBUG: App resumed - Reloading state');

      // Forzar recarga de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      // Cargar última notificación y actualizar estados
      await loadLastNotification();

      // Forzar actualización de GetX
      // currentTravelGetx.update();
      // travelAlertGetx.update();

      // Forzar actualización de UI
      Get.forceAppUpdate();
    }
  }

  Future<void> updateNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      lastNotificationTitle.value = notification.title ?? 'Notificación';
      lastNotificationBody.value =
          notification.body ?? 'Tienes una nueva notificación';
      lastNotification.value = message;

      // Update states based on notification title
      switch (notification.title) {
        case 'Tu viaje fue aceptado':
          await _handleTripAccepted(this, modalController);
          break;
        case 'Nuevo precio para tu viaje':
          await _handleNegotiatingrate(this, modalController);
          break;
        case 'Tu viaje ha comenzado':
          await _handleTripStarted(this, modalController);
          break;
        case 'El taxi llego':
          await _handleTaxiArrived(this, modalController);
          break;
        case 'Viaje terminado':
          await _handleTripEnded(this, modalController);
          break;
      }

      if (notification.title == 'Nuevo precio para tu viaje') {
        lastNotificationType.value = 'new_price';
      } else if (notification.title == 'Tu viaje fue aceptado' ||
          notification.title == "Contraoferta aceptada por el conductor") {
        lastNotificationType.value = 'trip_accepted';
      } else {
        lastNotificationType.value = 'general';
      }

      await _saveLastNotification(message);
      print(
          'DEBUG: Updated notification - Title: ${notification.title}, Body: ${notification.body}');
      print(
          'DEBUG: Updated states - tripAccepted: ${tripAccepted.value}, modalText: ${modalController.modalText.value}');
    }
  }

  Future<void> loadLastNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final storedMessage = prefs.getString(_lastNotificationKey);

      if (storedMessage != null) {
        final Map<String, dynamic> messageMap = jsonDecode(storedMessage);
        final message = RemoteMessage.fromMap(messageMap);
        lastNotification.value = message;

        final notification = message.notification;
        if (notification != null) {
          lastNotificationTitle.value = notification.title ?? 'Notificación';
          lastNotificationBody.value =
              notification.body ?? 'Tienes una nueva notificación';

          // Update states based on notification title
          switch (notification.title) {
            case 'Tu viaje fue aceptado':
              await _handleTripAccepted(this, modalController);
              break;
            case 'Tu viaje ha comenzado':
              await _handleTripStarted(this, modalController);
              break;
            case 'El taxi llego':
              await _handleTaxiArrived(this, modalController);
              break;
            case 'Viaje terminado':
              await _handleTripEnded(this, modalController);
              break;
          }

          // Forzamos actualización de la UI
          Get.forceAppUpdate();
        }
        print(
            'DEBUG: Loaded last notification - Title: ${notification?.title}, Body: ${notification?.body}');
        print(
            'DEBUG: Updated states - tripAccepted: ${tripAccepted.value}, modalText: ${modalController.modalText.value}');
      } else {
        print('DEBUG: No stored notification found in SharedPreferences.');
      }
    } catch (e) {
      print('ERROR in loadLastNotification: $e');
    }
  }

  Future<void> clearNotification() async {
    lastNotificationTitle.value = '';
    lastNotificationBody.value = '';
    lastNotificationType.value = '';
    lastNotification.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastNotificationKey);
  }

  Future<void> _saveLastNotification(RemoteMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final messageJson = message.toMap();
    await prefs.setString(_lastNotificationKey, jsonEncode(messageJson));
  }

  @override
  void onClose() {
    _clearNotificationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
class ModalController extends GetxController {
  var imageUrl = 'assets/images/viajes/add_travel.gif'.obs;
  var modalText = 'Buscando chofer...'.obs;
}