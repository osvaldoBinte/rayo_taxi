import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/client/presentation/getxs/get/get_client_getx.dart';
import 'package:rayo_taxi/features/client/presentation/pages/home_page/home_page.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/confirmar_tariff_entitie.dart';
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

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  AndroidNotificationChannel? channel;
  final GlobalKey<NavigatorState> navigatorKey;

  RemoteMessage? initialMessage;

  NotificationService(this.navigatorKey);

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones Importantes',
      description: 'Este canal se usa para notificaciones importantes.',
      importance: Importance.high,
    );
   await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        final String? payload = notificationResponse.payload;
        if (payload != null && payload.isNotEmpty) {
          _handleNotificationClick(json.decode(payload));
        }
      },
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(AndroidNotificationChannel(
            'default_channel',
            'Default Channel',
            importance: Importance.high,
        ),);

    FirebaseMessaging.onMessage.listen(_onMessageHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedAppHandler);

    initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('La aplicación se inició desde una notificación');
      _handleNotificationClick(initialMessage!.data);
    }

    String? fcmToken = await _messaging.getToken();
    print('Token FCM: $fcmToken');
  }

  Future<void> _onMessageHandler(RemoteMessage message) async {
    print('Mensaje recibido en primer plano: ${message.messageId}');
    final context = navigatorKey.currentState?.overlay?.context;

    if (context != null) {
      final notification = message.notification;
      if (notification != null) {
        Get.find<NotificationController>().updateNotification(message);

        final title = notification.title ?? 'Notificación';
        final body = notification.body ?? 'Tienes una nueva notificación';
print('====Future $title');
        if (title == 'Nuevo precio para tu viaje') {
          currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());
print('====currentTravelGetx $title');
await _waitForOperationsToComplete(
      currentTravelGetx: Get.find<CurrentTravelGetx>(),
     
    );

    if (context.mounted) { 
      showNewPriceDialog(context);
    }
        } else if (title == 'Tu viaje fue aceptado' ||
            title == "Contraoferta aceptada por el conductor") {
          showacept(context, title, body);
        } else {
          showQuickAlert(context, title, body);
        }
      }
    }

    _showLocalNotification(message);
  }

Future<void> _waitForOperationsToComplete({
  required CurrentTravelGetx currentTravelGetx,
}) async {
  final currentTravelCompleter = Completer();

  ever(currentTravelGetx.state, (state) {
    if (state is TravelAlertLoaded || state is TravelAlertFailure) {
      if (!currentTravelCompleter.isCompleted) {
        currentTravelCompleter.complete();
      }
    }
  });

 

  currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());

  await Future.wait([
    currentTravelCompleter.future,
  ]);
}
  void _onMessageOpenedAppHandler(RemoteMessage message) {
    print(
        'El usuario hizo clic en una notificación mientras la app estaba en segundo plano');
    _handleNotificationClick(message.data);
    initialMessage = message;
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
         WidgetsBinding.instance.addPostFrameCallback((_) async {
     
    final currentTravelGetx = Get.find<CurrentTravelGetx>();

          currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());
    });
    
    final prefs = await SharedPreferences.getInstance();
    final messageJson = message.toMap();
    await prefs.setString('lastNotification', jsonEncode(messageJson));

    print('DEBUG: Message saved to SharedPreferences');

    final storedMessage = prefs.getString('lastNotification');

    print(
        'DEBUG: Raw stored message in _firebaseMessagingBackgroundHandler: $storedMessage');
    print("Background message received: ${message.notification?.title}");

    if (Get.isRegistered<NotificationController>()) {
      final notificationController = Get.find<NotificationController>();
      await notificationController.loadLastNotification();
    }
    if (!Get.isRegistered<ModalController>()) {
      Get.put(ModalController());
    }
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    print("Mensaje recibido en segundo plano");

    print(
        'DEBUG: Background message received - Title: ${message.notification?.title}');

    if (notification != null) {
      Get.find<NotificationController>().updateNotification(message);
    }
    if (notification != null && android != null) {
      print("Procesando notificación en segundo plano");

      if (notification.title == 'Tu viaje fue aceptado') {
        Get.find<NotificationController>().tripAccepted.value = true;
        Get.find<ModalController>().lottieUrl.value =
            'https://lottie.host/4b6efc1d-1021-48a4-a3dd-df0eecbd8949/1CzFNvYv69.json';
        Get.find<ModalController>().modalText.value =
            'Viaje aceptado, espera al conductor en el punto de encuentro';
        print("Tu viaje fue aceptado");
      }
      if (notification.title == 'Tu viaje ha comenzado') {
        print("Tu viaje ha comenzado");

        Get.find<NotificationController>().tripAccepted.value = true;
        Get.find<ModalController>().lottieUrl.value =
            'https://lottie.host/4a367cbb-4834-44ba-997a-9a8a62408a99/keSVai2cNe.json';
        Get.find<ModalController>().modalText.value = 'Tu viaje ha comenzado';
      }

      if (notification.title == 'El taxi llego') {
        print("El taxi llegó");

        Get.find<NotificationController>().tripAccepted.value = true;
        Get.find<ModalController>().lottieUrl.value =
            "https://lottie.host/bcf4608b-5b35-4c48-b2c9-c0126124a159/CFerLgDKdO.json";
        Get.find<ModalController>().modalText.value =
            'El taxi ha llegado al punto de encuentro';
      }
      if (notification.title == 'Viaje terminado') {
        Get.find<NotificationController>().tripAccepted.value = false;
        Get.find<ModalController>().lottieUrl.value =
            'https://lottie.host/e44ab786-30a1-48ee-96eb-bb2e002f3ae8/NtzqQeAN8j.json';
        Get.find<ModalController>().modalText.value = 'Buscando chofer...';
      }
    }
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
  final state = currentTravelGetx.state.value;

  if (state is! TravelAlertLoaded) {
    print("Error: No travel data available.");
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

    QuickAlert.show(
      context: context,
      type: QuickAlertType.custom,
      title: 'Nueva oferta ',
      showCancelBtn: false,
      showConfirmBtn: false,
      widget: Column(
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
          Obx(() => Text(
                inputAmount.value.isNotEmpty
                    ? 'Monto ofertado: \$${inputAmount.value}'
                    : '',
                style: TextStyle(fontSize: 16),
              )),
          SizedBox(height: 10),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              inputAmount.value = value;
              buttonText.value = value.isNotEmpty ? "Ofertar \$${value}" : "Confirmar";
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () async {
                  try {
                    final travel = TravelwithtariffEntitie(
                      driverId: driverId,
                      travelId: travelId,
                    );
                    final event = RejectTravelofferEventEvent(travel: travel);
                    await Get.find<RejecttravelofferGetx>().rejecttravelofferGetx(event);
                    
                   // Get.back();
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
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () async {
                      if (buttonText.value == "Confirmar") {
                        try {
                          final travel = ConfirmarTariffEntitie(
                            driverId: driverId,
                            travelId: travelId,
                          );
                          await Get.find<TravelwithtariffGetx>()
                              .travelwithtariffGetx(TravelWithtariffEvent(travel: travel));
                          
                          //Get.back();
                                              navigateToHome();

                          CustomSnackBar.showSuccess(
                            'Éxito',
                            'La confirmación del viaje se realizó correctamente',
                          );
                         // currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());
                        } catch (error) {
                          Get.back(); 
                          CustomSnackBar.showError(
                            'Error',
                            'Hubo un problema al confirmar el viaje',
                          );
                        }
                      } else {
                        final newPrice = int.tryParse(priceController.text);
                        if (newPrice == null || newPrice <= 0) {
                          CustomSnackBar.showError(
                            'Error',
                            'Por favor, introduce un precio válido.',
                          );
                          return;
                        }
                        
                        try {
                          final travel = TravelwithtariffEntitie(
                            driverId: driverId,
                            travelId: travelId,
                            tarifa: newPrice,
                          );
                          await Get.find<OffernegotiationGetx>()
                              .offernegotiation(OfferNegotiationevent(travel: travel));
                                            navigateToHome();

                          CustomSnackBar.showSuccess(
                            'Éxito',
                            'La oferta se realizó correctamente.',
                          );
                          currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());
                        } catch (error) {
                          Get.back(); // Cerrar el QuickAlert incluso si hay error
                          
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
    );
  });
}

  void showacept(BuildContext context, String title, String body) {
              currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());

    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: title,
      text: body,
            confirmBtnText: 'OK',

       onConfirmBtnTap: () {
       
        navigateToHome();
      },
    );
  }

  void showQuickAlert(BuildContext context, String title, String body) {
  // Wrap modal operations in microtask to avoid build phase conflicts
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
          Get.find<ModalController>().lottieUrl.value =
              'https://lottie.host/e44ab786-30a1-48ee-96eb-bb2e002f3ae8/NtzqQeAN8j.json';
          Get.find<ModalController>().modalText.value = 'Buscando chofer...';
        }
        
        // Use Navigator directly instead of delayed call
        Navigator.pushNamed(
          context,
          RoutesNames.homePage,
          arguments: {'selectedIndex': 1}
        );
      },
    );
  });
}
void navigateToHome() {
  if (navigatorKey.currentContext != null) {
    Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
      RoutesNames.homePage,
      (route) => false,
      arguments: {'selectedIndex': 1},
    );
  }
}
  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      if (notification.title == 'Tu viaje fue aceptado') {
        Get.find<NotificationController>().tripAccepted.value = true;
        Get.find<ModalController>().lottieUrl.value =
            'https://lottie.host/4b6efc1d-1021-48a4-a3dd-df0eecbd8949/1CzFNvYv69.json';
        Get.find<ModalController>().modalText.value =
            'Viaje aceptado, espera al conductor en el punto de encuentro';
      }
      if (notification.title == 'Tu viaje ha comenzado') {
        Get.find<NotificationController>().tripAccepted.value = true;
        Get.find<ModalController>().lottieUrl.value =
            'https://lottie.host/4a367cbb-4834-44ba-997a-9a8a62408a99/keSVai2cNe.json';
        Get.find<ModalController>().modalText.value = 'Tu viaje ha comenzado';
      }

      if (notification.title == 'El taxi llego') {
        Get.find<NotificationController>().tripAccepted.value = true;
        Get.find<ModalController>().lottieUrl.value =
            "https://lottie.host/bcf4608b-5b35-4c48-b2c9-c0126124a159/CFerLgDKdO.json";
        Get.find<ModalController>().modalText.value =
            'El taxi ha llegado al punto de encuentro';
      }
      if (notification.title == 'Viaje terminado') {
        Get.find<NotificationController>().tripAccepted.value = false;
        Get.find<ModalController>().lottieUrl.value =
            'https://lottie.host/e44ab786-30a1-48ee-96eb-bb2e002f3ae8/NtzqQeAN8j.json';
        Get.find<ModalController>().modalText.value = 'Buscando chofer...';
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
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }
}
