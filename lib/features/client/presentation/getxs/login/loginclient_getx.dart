import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/features/client/domain/entities/client.dart';
import 'package:rayo_taxi/features/client/domain/usecases/login_client_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rayo_taxi/features/client/presentation/pages/home_page/home_page.dart';

part 'loginclient_event.dart';
part 'loginclient_state.dart';

class LoginclientGetx extends GetxController {
  final LoginClientUsecase loginClientUsecase;
  
  var state = Rx<LoginclientState>(LoginclientInitial());
  
  var isLoading = false.obs;

  LoginclientGetx({required this.loginClientUsecase});

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    state.value = LoginclientLoading();
    try {
      final client = Client(email: email, password: password);
      await loginClientUsecase.execute(client);
      state.value = LoginclientSuccessfully();

               Get.offAll(() => HomePage(selectedIndex: 1));

    } catch (e) {
      state.value = LoginclientFailure(e.toString());

      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'ACCESO INCORRECTO',
        text: 'No se pudo iniciar sesión. Inténtalo de nuevo.',
        confirmBtnText: 'OK',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    state.value = LoginclientInitial();  
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('auth_token');
    });
  }
}
