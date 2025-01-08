import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart'; // Importa QuickAlert
import 'package:rayo_taxi/features/client/domain/entities/recoveryPassword/recovery_password_entitie.dart';
import 'package:rayo_taxi/features/client/domain/usecases/check_recovery_code_usecase.dart';
import 'package:rayo_taxi/features/client/domain/usecases/create_recovery_code_usecase.dart';
import 'package:rayo_taxi/features/client/domain/usecases/update_password_usecase.dart';
import 'package:rayo_taxi/features/client/presentation/pages/home_page/home_page.dart';

enum RecoveryStep { Email, Code, UpdatePassword }

class CreateRecoveryCodeController extends GetxController {
  // Controladores para los campos de texto
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Variables observables para determinar el paso actual
  var currentStep = RecoveryStep.Email.obs;

  // Variables observables para manejar el estado de carga
  var isLoading = false.obs;

  // Variables observables para manejar la visibilidad de las contraseñas
  var isNewPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;

  // Casos de uso
  final CreateRecoveryCodeUsecase createRecoveryCodeUsecase;
  final CheckRecoveryCodeUsecase checkRecoveryCodeUsecase;
  final UpdatePasswordUsecase updatePasswordUsecase;
  var remainingSeconds = 180.obs; // 3 minutos en segundos
  Timer? timer; // Temporizador

  // Constructor con inyección de dependencias
  CreateRecoveryCodeController({
    required this.createRecoveryCodeUsecase,
    required this.checkRecoveryCodeUsecase,
    required this.updatePasswordUsecase,
  });

  // Métodos para alternar la visibilidad de las contraseñas
  void toggleNewPasswordVisibility() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }
void startTimer() {
    remainingSeconds.value = 180; // Reinicia el tiempo
    timer?.cancel(); // Cancela cualquier temporizador previo
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        timer.cancel();
        // Tiempo agotado, regresa al paso de email
        currentStep.value = RecoveryStep.Email;
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.info,
          title: 'Tiempo agotado',
          text: 'El código ha expirado. Por favor solicita un nuevo código.',
          confirmBtnText: 'OK',
        );
      }
    });
  }
    void cancelTimer() {
    timer?.cancel();
  }
  
  // Método para enviar el código de recuperación
   Future<void> sendRecoveryCode() async {
    final email = emailController.text.trim();
    if (_validateEmail(email)) {
      isLoading.value = true;
      try {
        final recoveryPasswordEntitie = RecoveryPasswordEntitie(email: email);
        await createRecoveryCodeUsecase.execute(recoveryPasswordEntitie);
        currentStep.value = RecoveryStep.Code;
        startTimer(); // Inicia el temporizador aquí
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.success,
          title: 'Éxito',
          text: 'Código de recuperación enviado a $email',
          confirmBtnText: 'OK',
        );
      } catch (e) {
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'No se pudo enviar el código de recuperación. Inténtalo de nuevo.',
          confirmBtnText: 'OK',
        );
      } finally {
        isLoading.value = false;
      }
    } else {
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Por favor ingresa un correo electrónico válido',
        confirmBtnText: 'OK',
      );
    }
  }


  // Método para validar el código de recuperación
  Future<void> validateRecoveryCode() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();
    if (_validateCode(code)) {
      isLoading.value = true;
      try {
        final recoveryPasswordEntitie = RecoveryPasswordEntitie(email: email, recovery_code: code);
        await checkRecoveryCodeUsecase.execute(recoveryPasswordEntitie);
        currentStep.value = RecoveryStep.UpdatePassword;
        cancelTimer(); // Cancela el temporizador aquí
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.success,
          title: 'Éxito',
          text: 'Código de recuperación validado correctamente',
          confirmBtnText: 'OK',
        );
      } catch (e) {
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'Código de recuperación inválido. Inténtalo de nuevo.',
          confirmBtnText: 'OK',
        );
      } finally {
        isLoading.value = false;
      }
    } else {
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Por favor ingresa un código de recuperación válido de 6 dígitos',
        confirmBtnText: 'OK',
      );
    }
  }
  // Método para actualizar la contraseña
  Future<void> updatePassword() async {
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (_validatePasswords(newPassword, confirmPassword)) {
      isLoading.value = true;
      try {
        final recoveryPasswordEntitie = RecoveryPasswordEntitie(
          new_password: newPassword,
        );
        await updatePasswordUsecase.execute(recoveryPasswordEntitie);

        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.success,
          title: 'Éxito',
          text: 'Contraseña actualizada correctamente',
          confirmBtnText: 'OK',
          onConfirmBtnTap: () {
            Get.offAll(() => HomePage(selectedIndex: 1));
          },
        );
      } catch (e) {
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'No se pudo actualizar la contraseña. Inténtalo de nuevo.',
          confirmBtnText: 'OK',
        );
      } finally {
        isLoading.value = false;
      }
    } else {
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Las contraseñas no coinciden o no cumplen con los requisitos',
        confirmBtnText: 'OK',
      );
    }
  }

  // Método de validación del correo electrónico
  bool _validateEmail(String email) {
    if (email.isEmpty) return false;
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return regex.hasMatch(email);
  }

  // Método de validación del código
  bool _validateCode(String code) {
    final regex = RegExp(r'^\d{6}$');
    return regex.hasMatch(code);
  }

  // Método de validación de las contraseñas
  bool _validatePasswords(String password, String confirmPassword) {
    if (password.isEmpty || confirmPassword.isEmpty) return false;
  //  if (password.length < 6) return false; // Por ejemplo, mínimo 6 caracteres
    return password == confirmPassword;
  }

  @override
  void onClose() {
    emailController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    cancelTimer(); // Asegúrate de cancelar el temporizador al cerrar
    super.onClose();
  }
}
