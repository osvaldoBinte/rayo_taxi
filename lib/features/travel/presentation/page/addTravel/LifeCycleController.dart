import 'package:get/get.dart';
import 'package:flutter/material.dart';

class LifeCycleController extends GetxController with WidgetsBindingObserver {
  final appLifeCycleState = Rx<AppLifecycleState>(AppLifecycleState.resumed);

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appLifeCycleState.value = state;
  }
}