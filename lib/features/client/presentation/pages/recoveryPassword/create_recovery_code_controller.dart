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
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var currentStep = RecoveryStep.Email.obs;

  var isLoading = false.obs;

  var isNewPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;

  final CreateRecoveryCodeUsecase createRecoveryCodeUsecase;
  final CheckRecoveryCodeUsecase checkRecoveryCodeUsecase;
  final UpdatePasswordUsecase updatePasswordUsecase;
  var remainingSeconds = 60.obs; 
  Timer? timer; 

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
    remainingSeconds.value = 60;
    timer?.cancel(); 
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        timer.cancel();
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
  
   Future<void> sendRecoveryCode() async {
    final email = emailController.text.trim();
    if (_validateEmail(email)) {
      isLoading.value = true;
      try {
        final recoveryPasswordEntitie = RecoveryPasswordEntitie(email: email);
        await createRecoveryCodeUsecase.execute(recoveryPasswordEntitie);
        currentStep.value = RecoveryStep.Code;
        startTimer(); 
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


  Future<void> validateRecoveryCode() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();
    if (_validateCode(code)) {
      isLoading.value = true;
      try {
        final recoveryPasswordEntitie = RecoveryPasswordEntitie(email: email, recovery_code: code);
        await checkRecoveryCodeUsecase.execute(recoveryPasswordEntitie);
        currentStep.value = RecoveryStep.UpdatePassword;
        cancelTimer();
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

  bool _validateEmail(String email) {
    if (email.isEmpty) return false;
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return regex.hasMatch(email);
  }

  bool _validateCode(String code) {
    final regex = RegExp(r'^\d{6}$');
    return regex.hasMatch(code);
  }

  bool _validatePasswords(String password, String confirmPassword) {
    if (password.isEmpty || confirmPassword.isEmpty) return false;
    return password == confirmPassword;
  }

  @override
  void onClose() {
    emailController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    cancelTimer(); 
    super.onClose();
  }
}
