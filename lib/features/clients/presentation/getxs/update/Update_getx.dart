import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/clients/domain/entities/client.dart';
import 'package:rayo_taxi/features/clients/domain/usecases/create_client_usecase.dart';
import 'package:rayo_taxi/features/clients/domain/usecases/update_client_usecase.dart';

part 'Update_event.dart';
part 'Update_state.dart';
class UpdateGetx extends GetxController {
  final UpdateClientUsecase updateClientUsecase;
  var state = Rx<UpdateState>(UpdateInitial());
  UpdateGetx({required this.updateClientUsecase});
  updateGetx(CreateUpdateEvent event) async {
    state.value = UpdateLoading();
    try {
      await updateClientUsecase.execute(event.client);
      state.value = UpdateCreatedSuccessfully();
    } catch (e) {
      state.value = UpdateCreationFailure(e.toString());
    }
  }
}