import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/client/domain/entities/client.dart';
import 'package:rayo_taxi/features/client/domain/usecases/create_client_usecase.dart';
import 'package:rayo_taxi/features/client/domain/usecases/update_client_usecase.dart';
import 'package:flutter/material.dart';
import 'package:rayo_taxi/features/client/presentation/getxs/get/get_client_getx.dart';
part 'Update_event.dart';
part 'Update_state.dart';

class UpdateGetx extends GetxController {
  final UpdateClientUsecase updateClientUsecase;
  var state = Rx<UpdateState>(UpdateInitial());
  final GetClientGetx getClientGetx = Get.find<GetClientGetx>();

  final nameController = TextEditingController();
  final birthdateController = TextEditingController();
  final newPasswordController = TextEditingController();
  final oldPasswordController = TextEditingController();

  var isOldPasswordVisible = false.obs;
  var isNewPasswordVisible = false.obs;
  var showPasswordFields = false.obs;
  var imagePath = RxnString();

  UpdateGetx({required this.updateClientUsecase});

  @override
  void onInit() {
    super.onInit();
  }

  void initializeControllers(Client client) {
    nameController.text = client.name ?? '';
    birthdateController.text = client.birthdate ?? '';
  }

  void toggleOldPasswordVisibility() {
    isOldPasswordVisible.value = !isOldPasswordVisible.value;
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void togglePasswordFields() {
    showPasswordFields.value = !showPasswordFields.value;
  }

  void setImagePath(String path) {
    imagePath.value = path;
  }

  Future<void> updateClient() async {
    state.value = UpdateLoading();
    try {
      final client = Client(
        photo_profile: imagePath.value,
        name: nameController.text,
        new_password: newPasswordController.text,
        current_password: oldPasswordController.text,
        birthdate: birthdateController.text,
      );

      await updateClientUsecase.execute(client);
      state.value = UpdateCreatedSuccessfully();
      await getClientGetx.fetchCoDetails(FetchgetDetailsEvent());

      newPasswordController.clear();
      oldPasswordController.clear();
    } catch (e) {
      state.value = UpdateCreationFailure(e.toString());
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    birthdateController.dispose();
    newPasswordController.dispose();
    oldPasswordController.dispose();
    super.onClose();
  }
}
