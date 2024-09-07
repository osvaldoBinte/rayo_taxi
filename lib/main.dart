import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rayo_taxi/features/Clients/presentation/getxs/Device/device_getx.dart';
import 'package:rayo_taxi/usecase_config.dart';

import 'features/Clients/presentation/getxs/client/client_getx.dart';
import 'features/Clients/presentation/getxs/login/loginclient_getx.dart';
import 'features/Clients/presentation/getxs/token/tokenclient_getx.dart';
import 'features/Clients/presentation/pages/Homeprueba.dart';
import 'features/Clients/presentation/pages/login_clients_page.dart';

UsecaseConfig usecaseConfig = UsecaseConfig();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(ClientGetx(createClientUsecase: usecaseConfig.createClientUsecase!));
  Get.put(LoginclientGetx(loginClientUsecase: usecaseConfig.loginClientUsecase!));
  Get.put(DeviceGetx(deviceCientUsecase: usecaseConfig.deviceCientUsecase!));

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
      home: token != null && token!.isNotEmpty
          ? Homeprueba() 
          : LoginClientsPage(),
    );
  }
}
