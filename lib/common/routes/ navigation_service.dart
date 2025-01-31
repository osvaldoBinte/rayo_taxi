import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/notification/notificationcontroller.dart';

class NavigationService extends GetxService {
  static NavigationService get to => Get.find();
  
  Future<void> navigateToHome({int selectedIndex = 1}) async {
    // Add a small delay to ensure we're not in build phase
    await Future.delayed(Duration.zero);
    
    await Get.offAllNamed(
      RoutesNames.homePage,
      arguments: {'selectedIndex': selectedIndex}
    );
  }
   Future<void> navigateToHome2({int selectedIndex = 1, bool showNotification = false}) async {
    final completer = Completer<void>();
    
    try {
      // Primero navegamos
      await Get.offAllNamed(
        RoutesNames.homePage,
        arguments: {'selectedIndex': selectedIndex}
      );
      
      if (showNotification) {
        // Esperamos un poco para asegurar que la navegación se completó
        await Future.delayed(const Duration(milliseconds: 300));
        
        final NotificationController notificationController = Get.find<NotificationController>();
        final message = notificationController.lastNotification.value;
        
        if (message != null && 
            message.notification?.title != null &&
            message.notification?.body != null) {
          final title = message.notification!.title!;
          final body = message.notification!.body!;
          
          if (title == 'Tu viaje fue aceptado' ||
              title == "Contraoferta aceptada por el conductor") {
            // Usamos Get.context en lugar de Get.overlayContext
            if (Get.context != null) {
              // Aseguramos que se ejecute en el siguiente frame
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showacept(Get.context!, title, body);
              });
            }
          }
        }
      }
      
      completer.complete();
    } catch (e) {
      print('Error en navigateToHome: $e');
      completer.completeError(e);
    }
    
    return completer.future;
  }


  void showacept(BuildContext context, String title, String body) {

    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: title,
      text: body,
      confirmBtnText: 'OK',
      onConfirmBtnTap: () {
        Navigator.of(context).pop();
      },
    );
  }
}