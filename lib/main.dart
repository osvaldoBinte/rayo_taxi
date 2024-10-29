import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/calculateAge/calculateAge_getx.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/update/Update_getx.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/home_page.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/Device/device_getx.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/Device/id_device_get.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelById/travel_by_id_alert_getx.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/delete/delete_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/mapa/destino_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/travel/travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/page/mapa.dart';
import 'package:rayo_taxi/features/travel/presentation/page/mapa/destino_page.dart';
import 'package:rayo_taxi/features/travel/presentation/page/travel/accept_travel_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rayo_taxi/firebase_options.dart';
import 'connectivity_service.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/login_clients_page.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/client/client_getx.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/login/loginclient_getx.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/get/get_client_getx.dart';
import 'package:rayo_taxi/usecase_config.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

UsecaseConfig usecaseConfig = UsecaseConfig();
final connectivityService = ConnectivityService();
RemoteMessage? initialMessage;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
AndroidNotificationChannel? channel;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  channel = const AndroidNotificationChannel(
    'high_importance_channel', 
    'Notificaciones Importantes', 
    description:
        'Este canal se usa para notificaciones importantes.',
    importance: Importance.high,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
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
      ?.createNotificationChannel(channel!);

  // Inicializa controladores GetX
  Get.put(DeviceGetx(idDeviceUsecase: usecaseConfig.idDeviceUsecase!));
  Get.put(ClientGetx(createClientUsecase: usecaseConfig.createClientUsecase!));
  Get.put(
      LoginclientGetx(loginClientUsecase: usecaseConfig.loginClientUsecase!));
  Get.put(GetClientGetx(
      getClientUsecase: usecaseConfig.getClientUsecase!,
      connectivityService: connectivityService));
  Get.put(UpdateGetx(updateClientUsecase: usecaseConfig.updateClientUsecase!));
  Get.put(TravelGetx(poshTravelUsecase: usecaseConfig.poshTravelUsecase!));
  Get.put(TravelsAlertGetx(
      travelsAlertUsecase: usecaseConfig.travelsAlertUsecase!,
      connectivityService: connectivityService));
  Get.put(TravelAlertGetx(
      travelAlertUsecase: usecaseConfig.travelAlertUsecase!,
      connectivityService: connectivityService));
  Get.put(CalculateAgeGetx(
      calculateAgeUsecase: usecaseConfig.calculateAgeUsecase!));
  Get.put(DeleteTravelGetx(
      deleteTravelUsecase: usecaseConfig.deleteTravelUsecase!,
      connectivityService: connectivityService));
  Get.put(GetDeviceGetx(getDeviceUsecase: usecaseConfig.getDeviceUsecase!));

  Get.put(TravelByIdAlertGetx(
      travelByIdUsecase: usecaseConfig.travelByIdUsecase!,
      connectivityService: connectivityService));
  
  Get.put(DestinoController(getSearchHistoryUsecase: usecaseConfig.getSearchHistoryUsecase!,saveSearchHistoryUsecase: usecaseConfig.saveSearchHistoryUsecase!,getPlaceDetailsAndMoveUsecase: usecaseConfig.getPlaceDetailsAndMoveUsecase!, getPlacePredictionsUsecase: usecaseConfig.getPlacePredictionsUsecase!, ));
 //Get.put( MapController(getSearchHistoryUsecase: usecaseConfig.getSearchHistoryUsecase!,saveSearchHistoryUsecase: usecaseConfig.saveSearchHistoryUsecase!,getPlaceDetailsAndMoveUsecase: usecaseConfig.getPlaceDetailsAndMoveUsecase!, getPlacePredictionsUsecase: usecaseConfig.getPlacePredictionsUsecase!, ),);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Mensaje recibido en primer plano: ${message.messageId}');

    final context = navigatorKey.currentState?.overlay?.context;

    if (context != null) {
      final title = message.notification?.title ?? 'Notificación';
      final body =
          message.notification?.body ?? 'Tienes una nueva notificación';

      QuickAlert.show(
        context: context,
        type: QuickAlertType.info,
        title: title,
        text: body,
        confirmBtnText: 'OK',
        onConfirmBtnTap: () {
          if (title == 'Viaje terminado') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => HomePage(
                        selectedIndex: 0,
                      )),
              (Route<dynamic> route) => false,
            );
          } else {
            Navigator.of(context).pop();
          }
        },
      );
    } else {
      print('El contexto es nulo');
    }
  });

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Mensaje recibido en primer plano: ${message.messageId}');
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
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
  });

  String? fcmToken = await messaging.getToken();
  print('Token FCM: $fcmToken');
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print(
        'El usuario hizo clic en una notificación mientras la app estaba en segundo plano');
    _handleNotificationClick(message.data);
    initialMessage = message;
  });

  initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    print('La aplicación se inició desde una notificación');
  }

  runApp(MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void _handleNotificationClick(Map<String, dynamic> data) {
  int? travelId = int.tryParse(data['travel'] ?? '');
  print('Datos del mensaje: $data');
  print('el id desde _handleLoadedState ${travelId}');

  if (travelId != null) {   
    Get.to(() => AcceptTravelPage(idTravel: travelId));
  } else {
    print('Error: El travelId no es un entero válido');
  }
}

class MyApp extends StatelessWidget {
  MyApp();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSwatch().copyWith(
      primary: Color.fromARGB(255, 254, 255, 255),
      secondary: Color(0xFF007BFF),
    );

    return GetMaterialApp(
      navigatorKey: navigatorKey, 
      debugShowCheckedModeBanner: false,

      locale: const Locale('es', 'ES'),
      supportedLocales: [
        const Locale('es', 'ES'),
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        primaryColor: Color(0xFF3F3F3F),
        colorScheme: colorScheme,
        scaffoldBackgroundColor: Color.fromARGB(255, 255, 255, 255),
        textTheme: TextTheme(
          displayLarge: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          titleMedium: TextStyle(fontSize: 18, color: Color(0xFF333333)),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 12, color: Colors.grey[600]),
          bodySmall: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: SplashScreen(),
    );
  }
}


class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? idDevice;
  String? token;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
    idDevice = await Get.find<GetDeviceGetx>().fetchDeviceId();

    if (idDevice == null || idDevice!.isEmpty) {
      await prefs.remove('auth_token');
      Get.offAll(() => LoginClientsPage());
    } else if (token != null && token!.isNotEmpty) {
      Get.offAll(() => HomePage(
            selectedIndex: 1,
          ));
    } else {
      Get.offAll(() => LoginClientsPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

extension CustomColorScheme on ColorScheme {
  Color get buttonColor => Color.fromARGB(255, 0, 0, 0);
  Color get textButton => Color(0xFFEFC300);

  Color get Statuscancelled => Colors.red;
  Color get Statusaccepted => Colors.green;
  Color get StatusLookingfor => Colors.orange;
  Color get StatusCompletado => Colors.blue;
  Color get Statusrecognized => Colors.grey;
  Color get getStatusIcon => Colors.white;

  Color get iconred => Colors.red;
  Color get icongreen => Colors.green;
  Color get iconorange => Colors.orange;
  Color get iconblue => Colors.blue;
  Color get icongrey => Colors.grey;
  Color get iconwhite => Colors.white;
  Color get buttonColormap => Color.fromARGB(255, 10, 10, 10);
  Color get buttonColormap2 => Color(0xFF1e88e5);
  Color get blueAccent => const Color.fromARGB(255, 0, 0, 0);
  Color get backgroundColor => Color.fromARGB(255, 0, 0, 0);
  Color get backgroundColorLogin => Color.fromARGB(255, 5, 5, 5);
  Color get CurvedNavigationIcono => Color.fromARGB(255, 5, 5, 5);
  Color get CurvedNavigationIcono2 => Colors.white;
  Color get CurvedIconback => Color(0xFFEFC300);

  Color get error => Colors.red;
  Color get Success => Colors.green;
  Color get TextAler => Colors.white;
  Color get button => Color.fromARGB(255, 10, 10, 10);
  Color get buttontext => Colors.white;

    Color get iconhistory => Color(0xFFEFC300);
  Color get iconlocation_on => Colors.red;
}
