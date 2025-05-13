import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/client/domain/entities/client.dart';
import 'package:rayo_taxi/features/client/domain/usecases/create_client_usecase.dart';
import 'package:flutter/material.dart';
import 'package:rayo_taxi/features/client/presentation/pages/login/login_clients_page.dart';

part 'client_event.dart';
part 'client_state.dart';

class ClientGetx extends GetxController {
  final CreateClientUsecase createClientUsecase;
  var state = Rx<ClientState>(ClientInitial());

  // Controladores de texto
  final nameController = TextEditingController();
  final birthdateController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var isPasswordVisible = false.obs;
  var selectedGenderId = Rx<int?>(null); // Género seleccionado

  ClientGetx({required this.createClientUsecase});

  Future<void> registerClient() async {
    if (nameController.text.isEmpty ||
        birthdateController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        selectedGenderId.value == null) {

print('nameController ${nameController.text}');
print('passwordController ${passwordController.text}');
print('emailController ${emailController.text}');
print('birthdateController ${birthdateController.text}');
print('selectedGenderId ${selectedGenderId.value}');
      Get.snackbar(
        'Error',
        'Por favor, complete todos los campos',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    state.value = ClientLoading();
    try {
      final client = Client(
        name: nameController.text,
        password: passwordController.text,
        email: emailController.text,
        birthdate: birthdateController.text,
        id_gender: selectedGenderId.value,
      );
print('nameController ${nameController.text}');
print('passwordController ${passwordController.text}');
print('emailController ${emailController.text}');
print('birthdateController ${birthdateController.text}');
print('selectedGenderId ${selectedGenderId.value}');

      await createClientUsecase.execute(client);
      state.value = ClientCreatedSuccessfully();

      // Limpiar los controladores después del registro exitoso
      nameController.clear();
      birthdateController.clear();
      emailController.clear();
      passwordController.clear();
      selectedGenderId.value = null;

      // Navegar a la página de inicio de sesión
    } catch (e) {
      state.value = ClientCreationFailure(e.toString());
    }
  }
   void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
}
