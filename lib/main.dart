import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/login/logindriver_getx.dart';
import 'package:rayo_taxi/features/travel/presentetion/getx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentetion/getx/TravelById/travel_by_id_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentetion/getx/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/firebase_options.dart';
import 'package:rayo_taxi/usecase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';
import 'features/driver/presentation/getxs/get/get_driver_getx.dart';
import 'features/driver/presentation/pages/home_page.dart';
import 'features/driver/presentation/pages/login_driver_page.dart';
import 'features/travel/presentetion/getx/Device/device_getx.dart';

final connectivityService = ConnectivityService();
UsecaseConfig usecaseConfig = UsecaseConfig();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(LogindriverGetx(loginDriverUsecase: usecaseConfig.loginDriverUsecase!));
  Get.put(GetDriverGetx(getDriverUsecase: usecaseConfig.getDriverUsecase!,connectivityService: connectivityService));
  Get.put(DeviceGetx(idDeviceUsecase: usecaseConfig.idDeviceUsecase!));

  Get.put(TravelsAlertGetx(travelsAlertUsecase: usecaseConfig.travelsAlertUsecase!, connectivityService: connectivityService));
  Get.put(TravelAlertGetx(travelAlertUsecase: usecaseConfig.travelAlertUsecase!, connectivityService: connectivityService));
    Get.put(TravelByIdAlertGetx(travelByIdUsecase: usecaseConfig.travelByIdUsecase!, connectivityService: connectivityService));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  runApp(MyApp(token: token));
}

class MyApp extends StatelessWidget {
  final String? token;

  MyApp({this.token});

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
      home:
          token != null && token!.isNotEmpty ? HomePage() : LoginDriverPage(),
    );
  }
}

extension CustomColorScheme on ColorScheme {
  Color get buttonColor => Color(0xFFEFC300);
  Color get Statuscancelled => Colors.red;
  Color get Statusaccepted => Colors.green;
  Color get StatusLookingfor => Colors.orange;
  Color get StatusCompletado=> Colors.blue;
  Color get Statusrecognized=> Colors.grey;
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