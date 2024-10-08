import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/calculateAge/calculateAge_getx.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/update/Update_getx.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/home_page.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/Device/device_getx.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/notification/presentetion/page/notification_page.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/delete/delete_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/travel/travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/page/TravelListScreen.dart';
import 'package:rayo_taxi/features/travel/presentation/page/mapa.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/login_clients_page.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/client/client_getx.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/login/loginclient_getx.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/get/get_client_getx.dart';
import 'package:rayo_taxi/usecase_config.dart';
import 'connectivity_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rayo_taxi/firebase_options.dart';

UsecaseConfig usecaseConfig = UsecaseConfig();
final connectivityService = ConnectivityService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? authToken = prefs.getString('auth_token');

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
  runApp(MyApp(authToken: authToken));
}

class MyApp extends StatelessWidget {
  final String? authToken;

  MyApp({this.authToken});

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
            bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
            bodyMedium: TextStyle(fontSize: 12, color: Colors.grey[600]),
            bodySmall: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            )),
      ),
      home: authToken != null ? HomePage() : LoginClientsPage(),
    );
  }
}

extension CustomColorScheme on ColorScheme {
  Color get buttonColor => Color(0xFFEFC300);
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
  Color get backgroundColorLogin => Color(0xFFEFC300);
  Color get CurvedNavigationIcono => Color.fromARGB(255, 5, 5, 5);
  Color get CurvedNavigationIcono2 => Colors.white;
  Color get CurvedIconback => Color(0xFFEFC300);

  Color get error => Colors.red;
  Color get Success => Colors.green;
  Color get TextAler => Colors.white;
  Color get button => Color.fromARGB(255, 10, 10, 10);
  Color get buttontext => Colors.white;

}
