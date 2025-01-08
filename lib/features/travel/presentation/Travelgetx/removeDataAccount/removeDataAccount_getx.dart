import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rayo_taxi/features/client/presentation/getxs/login/loginclient_getx.dart';

import 'package:rayo_taxi/features/client/presentation/pages/login_clients_page.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/confirm_travel_with_tariff_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/remove_data_account_usecase.dart';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'removeDataAccount_event.dart';
part 'removeDataAccount_state.dart';

class RemovedataaccountGetx extends GetxController {
  final RemoveDataAccountUsecase removeDataAccountUsecase;
  var state = Rx<RemovedataaccountState>(RemovedataaccountInitial());
  final LoginclientGetx _loginGetx = Get.find<LoginclientGetx>();

  RemovedataaccountGetx({required this.removeDataAccountUsecase});

  Future<void> removedataaccountGetx(RemoveDataaccountEvent event) async {
    print("removedataaccountGetx.Travelwithtariff: Start");
    state.value = RemovedataaccountLoading();

    // Muestra el SpinKitFadingCube mientras se procesa la eliminación
    Get.dialog(
      Center(
        child: SpinKitFadingCube(
          color: Colors.blue,
          size: 50.0,
        ),
      ),
      barrierDismissible: false,
    );

    try {
      await removeDataAccountUsecase.execute();
      print("removedataaccountGetx.Removedataaccount: After execute");

      // Update state before navigation
      state.value = RemovedataaccountSuccessfully();

      // Cierra el diálogo del SpinKit
      if (Get.isDialogOpen ?? false) Get.back();

      // Navega a LoginClientsPage de forma segura
      await _logout();
      print("despues de microtask");
    } catch (e) {
      print("removedataaccountGetx.Removedataaccount: Exception - $e");

      // Cierra el diálogo del SpinKit si hubo error
      if (Get.isDialogOpen ?? false) Get.back();

      // Muestra un mensaje de error
      Get.snackbar(
        'Error',
        'No se pudo eliminar la cuenta: $e',
        snackPosition: SnackPosition.BOTTOM,
      );

      state.value = RemovedataaccountFailure(e.toString());
    }
    print("removedataaccountGetx.Removedataaccount: End");
  }

  Future<void> _logout() async {
    // Obtener instancia de GoogleSignIn
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      // Cerrar sesión de Google
      await googleSignIn.signOut();
      print("se cerro la sesion");
    } catch (e) {
      print("Error al cerrar sesión de Google: $e");
    }

    // Intentar desconectar, pero manejar la excepción si falla
    try {
      await googleSignIn.disconnect();
    } catch (e) {
      print("No se pudo revocar el acceso de Google: $e");
    }

    // Limpiar el token de autenticación
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _loginGetx.logout();
    await prefs.remove('auth_token');

    // Navegar a la página de inicio de sesión
    await Get.offAll(() => LoginClientsPage());
  }

  void confirmDeleteAccount() {
    // Muestra alerta de confirmación
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: 'Eliminar Cuenta',
      text: '¿Estás seguro de que deseas eliminar tu cuenta?',
      confirmBtnText: 'Sí, eliminar',
      cancelBtnText: 'Cancelar',
      onConfirmBtnTap: () async {
        Get.back(); // Cierra la alerta
        await Future.delayed(Duration(milliseconds: 300)); // Espera breve
        await removedataaccountGetx(RemoveDataaccountEvent());
      },
      onCancelBtnTap: () {
        Get.back(); // Cierra la alerta
      },
    );
  }
}
