import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/notification/notificationcontroller.dart';

class CustomLottieWidget extends StatelessWidget {
  final ModalController controller;
  final VoidCallback onError;

  const CustomLottieWidget({
    Key? key,
    required this.controller,
    required this.onError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => controller.isLottieError.value
        ? Image.asset(controller.imageUrl.value)
        : Lottie.network(
            controller.lottieUrl.value,
            errorBuilder: (context, error, stackTrace) {
              onError();
              return Image.asset(controller.imageUrl.value);
            },
          ));
  }
}