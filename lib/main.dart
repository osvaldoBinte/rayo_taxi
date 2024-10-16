import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/get/id_device_get.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/login/logindriver_getx.dart';
import 'package:rayo_taxi/features/travel/presentetion/getx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentetion/getx/TravelById/travel_by_id_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentetion/getx/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentetion/page/accept_travel_page.dart';
import 'package:rayo_taxi/firebase_options.dart';
import 'package:rayo_taxi/usecase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';
import 'features/driver/presentation/getxs/get/get_driver_getx.dart';
import 'features/driver/presentation/pages/home_page.dart';
import 'features/driver/presentation/pages/login_driver_page.dart';
import 'features/travel/presentetion/getx/Device/device_getx.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final connectivityService = ConnectivityService();
UsecaseConfig usecaseConfig = UsecaseConfig();
RemoteMessage? initialMessage;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa los controladores Getx
  Get.put(LogindriverGetx(
      loginDriverUsecase: usecaseConfig.loginDriverUsecase!));
  Get.put(GetDriverGetx(
      getDriverUsecase: usecaseConfig.getDriverUsecase!,
      connectivityService: connectivityService));
  Get.put(DeviceGetx(idDeviceUsecase: usecaseConfig.idDeviceUsecase!));
  Get.put(TravelsAlertGetx(
      travelsAlertUsecase: usecaseConfig.travelsAlertUsecase!,
      connectivityService: connectivityService));
  Get.put(TravelAlertGetx(
      travelAlertUsecase: usecaseConfig.travelAlertUsecase!,
      connectivityService: connectivityService));
  Get.put(TravelByIdAlertGetx(
      travelByIdUsecase: usecaseConfig.travelByIdUsecase!,
      connectivityService: connectivityService));
  Get.put(GetDeviceGetx(
      getDeviceUsecase: usecaseConfig.getDeviceUsecase!));

  // Configura Firebase Messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;
 
 FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Mensaje recibido en primer plano');
    print('Datos del mensaje: ${message.data}');
    if (message.notification != null) {
      print('El mensaje también contiene una notificación: ${message.notification}');
    }
  });


  // Maneja cuando la aplicación está en segundo plano y el usuario hace clic en la notificación
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('El usuario hizo clic en una notificación mientras la app estaba en segundo plano');
    _handleNotificationClick(message);
        initialMessage = message;

  });

   initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    print('La aplicación se inició desde una notificación');
    // Almacena el mensaje para manejarlo después
  }

  runApp(MyApp());
}
void _handleNotificationClick(RemoteMessage message) {
  // Aquí puedes obtener datos de la notificación y navegar a la página deseada
  // Por ejemplo, si tienes datos en message.data
int? travelId = int.tryParse(message.data['travel'] ?? '');
    print('Datos del mensaje: ${message.data}');

  // Asegúrate de usar Get.to o Get.offAll según tus necesidades
  Get.to(() => AcceptTravelPage(idTravel: travelId,));
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF3F3F3F),
        colorScheme: colorScheme,
        scaffoldBackgroundColor: Color.fromARGB(255, 255, 255, 255),
        textTheme: TextTheme(
            displayLarge: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            titleMedium: TextStyle(fontSize: 18, color: Color(0xFF333333)),
            bodyLarge: TextStyle(fontSize: 16, color: Colors.green),
            bodyMedium: TextStyle(fontSize: 12, color: Colors.grey[600]),
            bodySmall: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            )),
      ),
      home: SplashScreen(initialMessage: initialMessage), // Pasa initialMessage
    );
  }
}

class SplashScreen extends StatefulWidget {
  final RemoteMessage? initialMessage;

  SplashScreen({this.initialMessage});

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
      Get.offAll(() => LoginDriverPage());
    } else if (token != null && token!.isNotEmpty) {
      Get.offAll(() => HomePage());
    } else {
      Get.offAll(() => LoginDriverPage());
    }

    // Después de la navegación, maneja el mensaje inicial
    if (widget.initialMessage != null) {
      print('Manejando initialMessage en SplashScreen');
      _handleNotificationClick(widget.initialMessage!);
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    print('Datos del mensaje: ${message.data}');

    int? travelId = int.tryParse(message.data['travel'] ?? '');

    if (travelId != null) {
      Get.to(() => AcceptTravelPage(idTravel: travelId));
    } else {
      print('Error: El travelId no es un entero válido');
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
  Color get buttonColor => Color(0xFFEFC300);
  Color get Statuscancelled => Colors.red;
  Color get Statusaccepted => Colors.green;
  Color get StatusLookingfor => Colors.orange;
  Color get StatusCompletado => Colors.blue;
  Color get Statusrecognized => Colors.grey;
  Color get getStatusIcon => Colors.white;

  Color get buttonColormap => Color.fromARGB(255, 10, 10, 10);
  Color get buttonColormap2 => Color(0xFF1e88e5);
  Color get blueAccent => const Color.fromARGB(255, 0, 0, 0);
  Color get backgroundColor => Color.fromARGB(255, 0, 0, 0);
  Color get backgroundColorLogin => Color(0xFFEFC300);
  Color get CurvedNavigationIcono => Color.fromARGB(255, 5, 5, 5);
  Color get CurvedNavigationIcono2 => Colors.white;
  Color get CurvedIconback => Color(0xFFEFC300);

  Color get error => Colors.red;
  Color get success => Colors.green;
  Color get TextAler => Colors.white;
  Color get button => Color.fromARGB(255, 10, 10, 10);
  Color get buttontext => Colors.white;
}
