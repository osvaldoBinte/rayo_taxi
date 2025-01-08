import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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
    return true;
  }
Future<void> requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      var result = await Permission.notification.request();
      if (result.isPermanentlyDenied) {
        await openAppSettings();
      }
    }
  }
  Future<void> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Get.dialog(
        AlertDialog(
          title: Text('Servicios de Ubicación Desactivados'),
          content: Text('Activa los servicios de ubicación para continuar.'),
          actions: [
            TextButton(
              child: Text('Activar'),
              onPressed: () async {
                await Geolocator.openLocationSettings();
                Get.back();
              },
            ),
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Get.back(),
            ),
          ],
        ),
        barrierDismissible: false,
      );
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      await openAppSettings();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      print('Ubicación actual: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error al obtener la ubicación: $e');
    }
  }
}