import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/routes/%20navigation_service.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/client/presentation/getxs/get/get_client_getx.dart';
import 'package:rayo_taxi/common/widge/custom_alert_dialog.dart';
import 'package:rayo_taxi/features/travel/presentation/page/ratetrip/rate_trip.dart';
import 'package:rayo_taxi/features/client/presentation/pages/home_page/home_page.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/confirmar_tariff_entitie.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/notification/notificationcontroller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/acceptTravel/accept_travel_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/travelwithtariff_entitie.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelAlert/current_travel.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/rejectTravelOffer/rejectTravelOffer_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelWithTariff/travelWithTariff_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/offerNegotiation/offerNegotiation_getx.dart';
import 'package:rayo_taxi/common/FloatingNotificationButton.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/customSnacknar.dart';

import 'package:rayo_taxi/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final GlobalKey<FloatingNotificationButtonState>
      floatingNotificationKey = GlobalKey<FloatingNotificationButtonState>();
  final currentTravelGetx = Get.find<CurrentTravelGetx>();
  final travelAlertGetx = Get.find<TravelsAlertGetx>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  AndroidNotificationChannel? channel;
  final GlobalKey<NavigatorState> navigatorKey;

  bool _isPriceDialogOpen = false;
  RemoteMessage? initialMessage;

  NotificationService(this.navigatorKey);

  Future<void> initialize() async {
    
    FirebaseMessaging.onBackgroundMessage(
        NotificationController.firebaseMessagingBackgroundHandler);

    channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones Importantes',
      description: 'Este canal se usa para notificaciones importantes.',
      importance: Importance.high,
    );

    await _configureIOSPermissions();
    await _initializeLocalNotifications();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel!);

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _setupMessageListeners();
    
    await _registerFCMToken();
    
    _setupTravelStateObservers();
  }

  Future<void> _configureIOSPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true, 
      announcement: false, 
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true, 
    );
    
    print('User granted permission: ${settings.authorizationStatus}');
    
    await FirebaseMessaging.instance.getAPNSToken();
  }

  Future<void> _initializeLocalNotifications() async {
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_launcher_background');
    
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      // Importante: Configurar como manejar las notificaciones cuando la app está abierta
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      // Configurar categorías para acciones en notificaciones de iOS
      notificationCategories: [
        DarwinNotificationCategory(
          'travelCategory',
          actions: [
            DarwinNotificationAction.plain(
              'VIEW',
              'Ver',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );
    
    // Combinar configuraciones
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    // Inicializar el plugin con manejadores de eventos
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // Importante: Manejar cuando el usuario toca la notificación
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }

  // Manejador para notificaciones locales en iOS (versiones anteriores)
  void _onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {
    print('Recibida notificación local iOS: $title');
    if (payload != null) {
      _handleNotificationPayload(payload);
    }
  }

  // Manejador para cuando el usuario toca una notificación
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    print('Usuario tocó notificación con payload: ${response.payload}');
    if (response.payload != null) {
      _handleNotificationPayload(response.payload!);
    }
  }
  
  void _handleNotificationPayload(String payload) {
    try {
      final data = json.decode(payload);
      _handleNotificationClick(data);
    } catch (e) {
      print('Error al procesar payload: $e');
    }
  }

  Future<void> _registerFCMToken() async {
    try {
      // Obtener token FCM
      String? fcmToken = await _messaging.getToken();
      print('Token FCM: $fcmToken');
      
      // En iOS, obtener token APNs específico
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      print('Token APNs (iOS): $apnsToken');
      
      // Aquí podrías guardar el token en tu backend
    } catch (e) {
      print('Error al obtener el token FCM/APNs: $e');
    }
  }

  void _setupMessageListeners() {
    // Cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen(_onMessageHandler);
    
    // Cuando la app está en segundo plano y se abre por tocar la notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedAppHandler);
    
    // Verificar si la app se abrió desde una notificación mientras estaba cerrada
    _checkInitialMessage();
  }
  
  void _setupTravelStateObservers() {
    ever(currentTravelGetx.state, (state) {
      if (state is TravelAlertLoaded) {
        final travel = state.travel.firstOrNull;
        if (travel != null) {
          _handleTravelStateChange(travel);
        }
      }
    });
    
    ever(travelAlertGetx.state, (state) {
      if (state is TravelsAlertLoaded) {
        final travel = state.travels.firstOrNull;
        if (travel != null) {
          _RateTrip(travel);
        }
      }
    });
  }

  Future<void> _checkInitialMessage() async {
    // Importante para iOS: verificar si la app se abrió por una notificación
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    
    if (initialMessage != null) {
      print('App opened from terminated state by notification: ${initialMessage.data}');
      _handleNotificationClick(initialMessage.data);
    }
  }

  Future<void> _handleTravelStateChange(TravelAlertModel travel) async {
    if (travel.waiting_for == 1 && travel.id_status == 6) {
     if (!_isPriceDialogOpen && Get.context != null) {
        showNewPriceDialog(Get.context!);
      }
    }
  }

  Future _RateTrip(TravelAlertModel travel) async {
    final state = travelAlertGetx.state.value;

    if (state is! TravelsAlertLoaded) {
      print("Error: No travel data available.");
      return;
    }

    final travel = state.travels.first;
    showRateTripAlert(Get.context!, travel);
  }

  Future<void> _onMessageHandler(RemoteMessage message) async {
    print('Mensaje recibido en primer plano: ${message.messageId}');

    final context = Get.key.currentContext;

    if (context != null) {
      final notification = message.notification;
      if (notification != null) {
        Get.find<NotificationController>().updateNotification(message);

        final title = notification.title ?? 'Notificación';
        final body = notification.body ?? 'Tienes una nueva notificación';

        
      }
    }

    _showLocalNotification(message);
  }

  Future<void> _waitForOperationsToComplete(
      {required CurrentTravelGetx currentTravelGetx,
      required TravelsAlertGetx travelAlertGetx}) async {
    final currentTravelCompleter = Completer();
    final travelsAlertCompleter = Completer();
    ever(currentTravelGetx.state, (state) {
      if (state is TravelAlertLoaded || state is TravelAlertFailure) {
        if (!currentTravelCompleter.isCompleted) {
          currentTravelCompleter.complete();
        }
      }
    });
    ever(travelAlertGetx.state, (state) {
      if (state is TravelsAlertLoaded || state is TravelsAlertFailure) {
        if (!travelsAlertCompleter.isCompleted) {
          travelsAlertCompleter.complete();
        }
      }
    });

    travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());
    currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());

    await Future.wait(
        [currentTravelCompleter.future, travelsAlertCompleter.future]);
  }

  void _onMessageOpenedAppHandler(RemoteMessage message) {
    print(
        'El usuario hizo clic en una notificación mientras la app estaba en segundo plano');
    _handleNotificationClick(message.data);
    initialMessage = message;
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
  

    print('DEBUG: Mensaje recibido en segundo plano');
    print('DEBUG: Título del mensaje: ${message.notification?.title}');

    final prefs = await SharedPreferences.getInstance();
    final messageJson = message.toMap();
    await prefs.setString('lastNotification', jsonEncode(messageJson));
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    int? travelId = int.tryParse(data['travel'] ?? '');
    print('Datos del mensaje: $data');
    print('El id desde _handleNotificationClick: $travelId');

    if (travelId != null) {
      navigateToHome();
    } else {
      print('Error: El travelId no es un entero válido');
    }
  }

 void showNewPriceDialog(BuildContext context) async {
      if (Get.isDialogOpen == true) {
      Get.back();
    }
    
    _isPriceDialogOpen = true;
  final state = currentTravelGetx.state.value;
  
   if (state is! TravelAlertLoaded) {
    print("Error: No travel data available.");
    _isPriceDialogOpen = false; // Resetear en caso de error
    return;
  }
  
  final travel = state.travel.first;
  final travelId = travel.id;
  final driverId = int.parse(travel.id_travel_driver);
  print('-------- $driverId travel $travelId tarifa ');
  
  Future.delayed(Duration(milliseconds: 500), () {
    final TextEditingController priceController = TextEditingController();
    final RxString inputAmount = "".obs;
    final RxString buttonText = "Confirmar".obs;
    
    showCustomAlert(
      context: context,
      type: CustomAlertType.warning,
      title: 'Nueva oferta',
      message: '',
      confirmText: '',
      cancelText: null,
      showBarrier:false,
      customWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RichText(
            text: TextSpan(
              text: 'El Chofer envió una oferta de ',
              style: TextStyle(color: Colors.black, fontSize: 16),
              children: [
                TextSpan(
                  text: '\$${travel.tarifa} MXN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextSpan(
                  text: ' para tu viaje.',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ],
            ),
          ),
          Obx(() {
            if (inputAmount.value.isNotEmpty) {
              String displayAmount = inputAmount.value.length > 6
                  ? '${inputAmount.value.substring(0, 6)}...'
                  : inputAmount.value;
              return Text(
                'Monto ofertado: \$${displayAmount}',
                style: TextStyle(fontSize: 16),
              );
            } else {
              return SizedBox();
            }
          }),
          
          SizedBox(height: 10),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              inputAmount.value = value;
              final truncatedValue =
                  value.length > 5 ? '${value.substring(0, 5)}...' : value;
              buttonText.value = value.isNotEmpty
                  ? "Ofertar \$${truncatedValue}"
                  : "Confirmar";
            },
            decoration: InputDecoration(
              labelText: 'Importe \$ MXN',
              hintText: '',
              labelStyle: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.buttonColormap,
                  width: 2.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              prefixIcon: Icon(
                Icons.attach_money,
                color: Colors.green,
              ),
            ),
          ),
          SizedBox(height: 20),
          // Usar Wrap para manejar automáticamente el desbordamiento
          Wrap(
            spacing: 10, // Espacio horizontal entre los botones
            runSpacing: 10, // Espacio vertical cuando los botones cambian de línea
            alignment: WrapAlignment.spaceBetween, // Distribuye los botones en el espacio disponible
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () async {
                  try {
                    final travelObj = TravelwithtariffEntitie(
                      driverId: driverId,
                      travelId: travelId,
                    );
                    final event = RejectTravelofferEventEvent(travel: travelObj);
                    await Get.find<RejecttravelofferGetx>()
                        .rejecttravelofferGetx(event);
                    
                    navigateToHome();
                    CustomSnackBar.showSuccess(
                      'Éxito',
                      'El rechazo de la oferta de viaje se realizó correctamente',
                    );
                    currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());
                  } catch (error) {
                    Get.back();
                    CustomSnackBar.showError(
                      'Error',
                      'Hubo un problema al rechazar la oferta de viaje',
                    );
                  }
                },
                child: Text("Rechazar"),
              ),
              Obx(() => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary2,
                ),
                onPressed: () async {
                  if (buttonText.value == "Confirmar") {
                    try {
                      final travelObj = ConfirmarTariffEntitie(
                        driverId: driverId,
                        travelId: travelId,
                      );
                      await Get.find<TravelwithtariffGetx>()
                          .travelwithtariffGetx(
                              TravelWithtariffEvent(travel: travelObj));
                      
                      navigateToHome();
                      
                      CustomSnackBar.showSuccess(
                        'Éxito',
                        'La confirmación del viaje se realizó correctamente',
                      );
                    } catch (error) {
                      Get.back();
                      CustomSnackBar.showError(
                        'Error',
                        'Hubo un problema al confirmar el viaje',
                      );
                    }
                  } else {
                      final newPrice = double.tryParse(priceController.text.replaceAll(',', '.'));

                    
                    // Verificación de precio con null-check similar al código de trabajo
                    if (newPrice == null || 
                        newPrice <= 0 || 
                        newPrice < (travel?.cost as double)) {
                      QuickAlert.show(
                        context: Get.context!,
                        type: QuickAlertType.error,
                        title: 'Importe inválido',
                        text: 'El Importe debe ser mayor a \$${travel.cost} MXN',
                        confirmBtnText: 'Entendido',
                        confirmBtnColor: Theme.of(Get.context!).colorScheme.error,
                        borderRadius: 8,
                        titleColor: Theme.of(Get.context!).colorScheme.error,
                      );
                      return;
                    }
                    
                    try {
                      final travelObj = TravelwithtariffEntitie(
                        driverId: driverId,
                        travelId: travelId,
                        tarifa: newPrice,
                      );
                      await Get.find<OffernegotiationGetx>()
                          .offernegotiation(
                              OfferNegotiationevent(travel: travelObj));
                      navigateToHome();
                      
                      CustomSnackBar.showSuccess(
                        'Éxito',
                        'La oferta se realizó correctamente.',
                      );
                      currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());
                    } catch (error) {
                      Get.back();
                      
                      CustomSnackBar.showError(
                        'Error',
                        'Hubo un problema al realizar la oferta: $error',
                      );
                    }
                  }
                },
                child: Text(buttonText.value),
              )),
            ],
          ),
        ],
      ),
    ).then((_) {
        _isPriceDialogOpen = false;
      });
    });
}

  void showacept(BuildContext context, String title, String body) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: title,
      text: body,
      confirmBtnText: 'OK',
      onConfirmBtnTap: () async {
        await Get.find<NavigationService>().navigateToHome(selectedIndex: 1);
      },
    );
  }

  void showQuickAlert(BuildContext context, String title, String body) {
    Future.microtask(() {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.info,
        title: title,
        text: body,
        confirmBtnText: 'OK',
        onConfirmBtnTap: () {
          if (title == 'Viaje terminado') {
            Get.find<NotificationController>().tripAccepted.value = false;
            Get.find<ModalController>().imageUrl.value = 'assets/images/viajes/add_travel.gif';
            Get.find<ModalController>().modalText.value = 'Buscando chofer...';
          }

          currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());
          Navigator.of(context).pop();
        },
      );
    });
  }

  void navigateToHome() {
    Get.offAllNamed(
      RoutesNames.homePage,
      arguments: {'selectedIndex': 1},
    );
  }
  
  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      // Actualizar la UI según el tipo de notificación
      if (notification.title == 'Tu viaje fue aceptado') {
        Get.find<NotificationController>().tripAccepted.value = true;
        var modalController = Get.find<ModalController>();
        modalController.isLottieError.value = false;
        modalController.lottieUrl.value = 'https://lottie.host/4b6efc1d-1021-48a4-a3dd-df0eecbd8949/1CzFNvYv69.json';
        modalController.imageUrl.value = 'assets/images/viajes/viaje-aceptado.gif';
        modalController.modalText.value = 'Viaje aceptado, espera al conductor en el punto de encuentro';
      }
      
      if (notification.title == 'Nuevo precio para tu viaje') {
        Get.find<NotificationController>().tripAccepted.value = true;
        var modalController = Get.find<ModalController>();
        modalController.isLottieError.value = false;
        modalController.lottieUrl.value = 'https://lottie.host/4b6efc1d-1021-48a4-a3dd-df0eecbd8949/1CzFNvYv69.json';
        modalController.imageUrl.value = 'assets/images/viajes/viaje-aceptado.gif';
        modalController.modalText.value = 'Viaje aceptado, espera al conductor en el punto de encuentro';
      }
      
      if (notification.title == 'Tu viaje ha comenzado') {
        Get.find<NotificationController>().tripAccepted.value = true;
        var modalController = Get.find<ModalController>();
        modalController.isLottieError.value = false;
        modalController.lottieUrl.value = 'https://lottie.host/4a367cbb-4834-44ba-997a-9a8a62408a99/keSVai2cNe.json';
        modalController.imageUrl.value = 'assets/images/viajes/viaje-ha-comenzado.gif';
        modalController.modalText.value = 'Tu viaje ha comenzado';
      }

      if (notification.title == 'El taxi llego') {
        Get.find<NotificationController>().tripAccepted.value = true;
        var modalController = Get.find<ModalController>();
        modalController.isLottieError.value = false;
        modalController.lottieUrl.value = 'https://lottie.host/bcf4608b-5b35-4c48-b2c9-c0126124a159/CFerLgDKdO.json';
        modalController.imageUrl.value = 'assets/images/viajes/taxi-llego.gif';
        modalController.modalText.value = 'El taxi ha llegado al punto de encuentro';
      }

      if (notification.title == 'Viaje terminado') {
  Get.find<NotificationController>().tripAccepted.value = true;
  var modalController = Get.find<ModalController>();
  modalController.isLottieError.value = false;
  modalController.lottieUrl.value = 'https://lottie.host/4b6efc1d-1021-48a4-a3dd-df0eecbd8949/1CzFNvYv69.json';
  modalController.imageUrl.value = 'assets/images/viajes/viaje-finalizado.gif';
  modalController.modalText.value = 'Tu viaje a terminado';
}
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel!.id,
          channel!.name,
          channelDescription: channel!.description,
          icon: '@drawable/rayo_taxi',
          color: Color(0xFFEFC300),
        ),
            iOS: DarwinNotificationDetails(), // Añade detalles iOS

      ),
      payload: jsonEncode(message.data),
    );
  }
}
}
