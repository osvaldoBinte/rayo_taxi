// home_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class HomeController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  DateTime? lastBackPressTime;

  void setIndex(int index) {
    selectedIndex.value = index;
  }

  Future<bool> handleBackButton(int initialIndex) async {
    if (selectedIndex.value != initialIndex) {
      selectedIndex.value = initialIndex;
      return false;
    }
    
    if (lastBackPressTime == null || 
        DateTime.now().difference(lastBackPressTime!) > Duration(seconds: 2)) {
      lastBackPressTime = DateTime.now();
      Get.showSnackbar(
        GetSnackBar(
          message: 'Presiona nuevamente para salir',
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    
    await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    return false;
  }
  
  Future<void> requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> requestPhonePermission() async {
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      await Permission.phone.request();
    }
  }

  Future<void> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }
  }
}