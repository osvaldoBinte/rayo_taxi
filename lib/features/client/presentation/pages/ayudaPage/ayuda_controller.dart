import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:rayo_taxi/features/client/domain/entities/client.dart';

class AyudaController extends GetxController with GetSingleTickerProviderStateMixin {
  static const platform = MethodChannel('com.tuapp/whatsapp');
  static const platformPhone = MethodChannel('com.tuapp/phone');
  
  final Client client;
  late AnimationController animationController;
  final isPressed = false.obs;
  final holdDuration = 1;

  AyudaController({required this.client});

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: holdDuration),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        makeEmergencyCall();
      }
    });
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }

  void onEmergencyTapDown() {
    isPressed.value = true;
    animationController.forward();
  }

  void onEmergencyTapUp() {
    isPressed.value = false;
    animationController.reset();
  }

  void onEmergencyTapCancel() {
    isPressed.value = false;
    animationController.reset();
  }
 Future<void> makeEmergencyCall() async {
  final phoneUrl = 'tel:911'; 
    
    try {
      Uri uri = Uri.parse(phoneUrl);
      if (Platform.isAndroid || Platform.isIOS) {
        const platform = MethodChannel('com.tuapp/phone');
        await platform.invokeMethod('makeEmergencyCall', {'url': uri.toString()});
      }
    } on PlatformException catch (e) {
      String errorMessage = 'No se pudo realizar la llamada de emergencia.';
      if (e.code == 'PERMISSION_DENIED') {
        errorMessage = 'Se requiere permiso para realizar llamadas de emergencia.';
      }
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo realizar la llamada de emergencia.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
}


  Future<void> abrirWhatsApp() async {
    final phoneSupport = client.phone_support?.replaceAll(RegExp(r'[^\d]'), '');
    final whatsappUrl = 'https://wa.me/+52$phoneSupport?text=${'Hola!! necesito ayuda'}';
    
    try {
      Uri uri = Uri.parse(whatsappUrl);
      await launchUrlNative(uri);
    } catch (e) {
      print('Error WhatsApp: $e');    
      Get.snackbar(
        'Error',
        'No se pudo abrir WhatsApp. Asegúrate de tenerlo instalado.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> hacerLlamada() async {
    final telefono = client.phone_support?.replaceAll(RegExp(r'[^\d]'), '');
    final phoneUrl = 'tel:+52$telefono';
    
    try {
      Uri uri = Uri.parse(phoneUrl);
      await launchPhoneCall(uri);
    } catch (e) {
      print('Error llamada: $e');    
      Get.snackbar(
        'Error',
        'No se pudo realizar la llamada.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> launchUrlNative(Uri uri) async {
    final String uriString = uri.toString();
    
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await platform.invokeMethod('openWhatsApp', {'url': uriString});
      } else {
        throw UnsupportedError('Plataforma no soportada');
      }
    } on PlatformException catch (e) {
      throw Exception('Error al abrir WhatsApp: ${e.message}');
    }
  }

  Future<void> launchPhoneCall(Uri uri) async {
    final String uriString = uri.toString();
    
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await platformPhone.invokeMethod('makePhoneCall', {'url': uriString});
      } else {
        throw UnsupportedError('Plataforma no soportada');
      }
    } on PlatformException catch (e) {
      throw Exception('Error al hacer la llamada: ${e.message}');
    }
  }
}