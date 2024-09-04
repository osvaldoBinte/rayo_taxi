import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/usecase_config.dart';

import 'features/Clients/presentation/getxs/client/client_getx.dart';
import 'features/Clients/presentation/pages/login_clients_page.dart';
UsecaseConfig usecaseConfig = UsecaseConfig();

void main() {
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
 MyApp() {
    
    Get.put(ClientGetx(createClientUsecase: usecaseConfig.createClientUsecase!));
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      home:  LoginClientsPage(),
    );
  }
}
