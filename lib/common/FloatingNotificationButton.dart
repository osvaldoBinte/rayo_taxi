import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/notification_service.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/notification/notificationcontroller.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';

class FloatingNotificationButtonController extends GetxController {
  Rx<Offset> position = Offset(0, 0).obs;

  void updatePosition(Offset newPosition) {
    position.value = newPosition;
  }
}

class FloatingNotificationButton extends StatefulWidget {
  FloatingNotificationButton({Key? key}) : super(key: key);

  @override
  FloatingNotificationButtonState createState() => FloatingNotificationButtonState();
}

class FloatingNotificationButtonState extends State<FloatingNotificationButton> {
  final notificationService = Get.find<NotificationService>();
  final NotificationController notificationController = Get.find<NotificationController>();
final FloatingNotificationButtonController buttonController = 
    Get.put(FloatingNotificationButtonController(), permanent: true);

 @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final size = WidgetsBinding.instance.window.physicalSize /
        WidgetsBinding.instance.window.devicePixelRatio;
    if (buttonController.position.value == Offset(0, 0)) {
      buttonController.updatePosition(
        Offset(
          size.width - 60 - 20, 
          size.height * 0.6,   
        ),
      );
    }
  });
}

  void _showLastNotification() {
    if (!mounted) return;

    final message = notificationController.lastNotification.value;
    if (message != null && message.notification?.title != null) {
      final title = message.notification!.title!;
      final body = message.notification!.body!;

       // Muestra el diálogo correspondiente
    if (title == 'Nuevo precio para tu viaje') {
      notificationService.showNewPriceDialog(context);
    } else if (title == 'Tu viaje fue aceptado' || title == "Contraoferta aceptada por el conductor") {
     // notificationService.showacept(context, title, body);
    } else {
      notificationService.showQuickAlert(context, title, body);
    } } else {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.info,
        text: 'No hay notificaciones disponibles.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final position = buttonController.position.value;
      final notification = notificationController.lastNotification.value;
      return Positioned(
        left: position.dx,
        top: position.dy,
        child: GestureDetector(
          onTap: () async {
            await notificationController.loadLastNotification();
            _showLastNotification();
          },
          child: _buildButton(notification),
        ),
      );
    });
  }

  Widget _buildButton(RemoteMessage? notification) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.buttonColormap,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.buttonColormap,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.notifications,
            color: Theme.of(context).colorScheme.iconwhite,
            size: 35,
          ),
          if (notification != null)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '1',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.TextAler,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
