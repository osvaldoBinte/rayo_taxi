import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/login/logindriver_getx.dart';
import 'package:rayo_taxi/usecase_config.dart';
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
  final tokendriverGetx = Get.find<TokendriverGetx>();
  await tokendriverGetx.verifyToken();
  final isValidToken = tokendriverGetx.state.value is TokendriverVerified;
  runApp(MyApp(isValidToken: isValidToken));
}

class MyApp extends StatelessWidget {
  final bool isValidToken;

  MyApp({required this.isValidToken}) ;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: isValidToken ? Homeprueba() : LoginDriverPage(),
    );
  }
}
