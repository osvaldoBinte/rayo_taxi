import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/update/Update_getx.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/home_page.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/Device/device_getx.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/notification/presentetion/page/notification_page.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/travel/travel_getx.dart';
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
  Get.put(LoginclientGetx(loginClientUsecase: usecaseConfig.loginClientUsecase!));
  Get.put(GetClientGetx(getClientUsecase: usecaseConfig.getClientUsecase!,connectivityService: connectivityService));
  Get.put(UpdateGetx(updateClientUsecase: usecaseConfig.updateClientUsecase!));
  Get.put(TravelGetx(poshTravelUsecase: usecaseConfig.poshTravelUsecase!));
  Get.put(TravelsAlertGetx(travelsAlertUsecase: usecaseConfig.travelsAlertUsecase!, connectivityService: connectivityService));
  Get.put(TravelAlertGetx(travelAlertUsecase: usecaseConfig.travelAlertUsecase!, connectivityService: connectivityService));
  runApp(MyApp(authToken: authToken));
}

class MyApp extends StatelessWidget {
  final String? authToken;

  MyApp({this.authToken});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: authToken != null ? HomePage() : LoginClientsPage(),
    );
  }
}
