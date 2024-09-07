import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/login/logindriver_getx.dart';
import 'package:rayo_taxi/usecase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/driver/presentation/getxs/token/tokendriver_getx.dart';
import 'features/driver/presentation/pages/Homeprueba.dart';
import 'features/driver/presentation/pages/login_driver_page.dart';

UsecaseConfig usecaseConfig = UsecaseConfig();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    Get.put(
        LogindriverGetx(loginDriverUsecase: usecaseConfig.loginDriverUsecase!));
  Get.put(
      TokendriverGetx(tokendriverUsecase: usecaseConfig.tokendriverUsecase!));
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
          : LoginDriverPage(),
    );
  }
}