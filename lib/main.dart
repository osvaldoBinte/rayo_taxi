import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/usecase_config.dart';

import 'features/Clients/data/datasources/client_local_data_source.dart';
import 'features/Clients/presentation/getxs/client/client_getx.dart';
import 'features/Clients/presentation/getxs/login/loginclient_getx.dart';
import 'features/Clients/presentation/getxs/token/tokenclient_getx.dart';
import 'features/Clients/presentation/pages/Homeprueba.dart';
import 'features/Clients/presentation/pages/login_clients_page.dart';

UsecaseConfig usecaseConfig = UsecaseConfig();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 Get.put(
        TokenclientGetx(tokenclientUsecase: usecaseConfig.tokenclientUsecase!));
  final tokenclientGetx = Get.find<TokenclientGetx>();
  await tokenclientGetx.verifyToken();
  final isValidToken = tokenclientGetx.state.value is TokenclientVerified;

  runApp(MyApp(isValidToken: isValidToken));
}

class MyApp extends StatelessWidget {
  final bool isValidToken;

  MyApp({required this.isValidToken}) {
    Get.put(
        ClientGetx(createClientUsecase: usecaseConfig.createClientUsecase!));
    Get.put(
        LoginclientGetx(loginClientUsecase: usecaseConfig.loginClientUsecase!));
   
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: isValidToken ? Homeprueba() : LoginClientsPage(),
    );
  }
}
