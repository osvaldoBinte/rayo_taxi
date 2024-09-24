import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/login/logindriver_getx.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/firebase_options.dart';
import 'package:rayo_taxi/usecase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';
import 'features/driver/presentation/getxs/get/get_driver_getx.dart';
import 'features/driver/presentation/pages/Homeprueba.dart';
import 'features/driver/presentation/pages/home_page.dart';
import 'features/driver/presentation/pages/login_driver_page.dart';
import 'features/notification/presentetion/getx/Device/device_getx.dart';

final connectivityService = ConnectivityService();
UsecaseConfig usecaseConfig = UsecaseConfig();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(LogindriverGetx(loginDriverUsecase: usecaseConfig.loginDriverUsecase!));
  Get.put(GetDriverGetx(getDriverUsecase: usecaseConfig.getDriverUsecase!,connectivityService: connectivityService));
  Get.put(DeviceGetx(idDeviceUsecase: usecaseConfig.idDeviceUsecase!));

  Get.put(TravelsAlertGetx(travelsAlertUsecase: usecaseConfig.travelsAlertUsecase!, connectivityService: connectivityService));
  Get.put(TravelAlertGetx(travelAlertUsecase: usecaseConfig.travelAlertUsecase!, connectivityService: connectivityService));
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
    return GetMaterialApp(
      home:
          token != null && token!.isNotEmpty ? HomePage() : LoginDriverPage(),
    );
  }
}
