import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/update/Update_getx.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/prueba.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/travel/travel_getx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/login_clients_page.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/client/client_getx.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/login/loginclient_getx.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/Device/device_getx.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/get/get_client_getx.dart';
import 'package:rayo_taxi/usecase_config.dart';

import 'connectivity_service.dart';

UsecaseConfig usecaseConfig = UsecaseConfig();
final connectivityService = ConnectivityService();

void main()   async {
  WidgetsFlutterBinding.ensureInitialized();

  Get.put(ClientGetx(createClientUsecase: usecaseConfig.createClientUsecase!));
  Get.put(LoginclientGetx(loginClientUsecase: usecaseConfig.loginClientUsecase!));
  Get.put(DeviceGetx(deviceCientUsecase: usecaseConfig.deviceCientUsecase!));
  Get.put(GetClientGetx(getClientUsecase: usecaseConfig.getClientUsecase!,connectivityService: connectivityService,));
  Get.put(UpdateGetx(updateClientUsecase: usecaseConfig.updateClientUsecase!));
  Get.put(TravelGetx(poshTravelUsecase: usecaseConfig.poshTravelUsecase!));

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');

  print('Token al iniciar la aplicación: $token');
  runApp(MyApp(token: token));
}

class MyApp extends StatelessWidget {
  final String? token;

  MyApp({this.token});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: token != null && token!.isNotEmpty
          ? MyHomePage()
          : LoginClientsPage(),
    );
  }
}
