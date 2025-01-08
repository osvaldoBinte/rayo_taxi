import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/client/presentation/pages/home_page/home_page.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/Device/id_device_get.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/Device/renew_token.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:rayo_taxi/features/client/presentation/pages/login_clients_page.dart';
import 'package:rayo_taxi/common/FloatingNotificationButton.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? idDevice;
  bool? token;

  @override
  void initState() {
    super.initState();

    _initializeApp();
  }

  void _initializeApp() async {
    //token = prefs.getString('auth_token');
    token = await Get.find<RenewTokenGetx>().execute();
    idDevice = await Get.find<GetDeviceGetx>().execute();

      if (idDevice == null || idDevice!.isEmpty) {
      //await prefs.remove('auth_token');
      Get.offAll(() => LoginClientsPage());
    } else if (token == true ) {
      Get.offAll(() => HomePage(
            selectedIndex: 1,
          ));
    } else {
      Get.offAll(() => LoginClientsPage());
    }
    if (token == true ) {
      Get.offAll(() => HomePage(
            selectedIndex: 1,
          ));
    } else {
      Get.offAll(() => LoginClientsPage());
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        Center(
          child: CircularProgressIndicator(),
        ),
      ],
    ),
  );
}
}