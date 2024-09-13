import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/clients/domain/entities/client.dart';
import 'package:rayo_taxi/features/clients/domain/usecases/create_client_usecase.dart';

part 'client_event.dart';
part 'client_state.dart';
class ClientGetx extends GetxController {
  final CreateClientUsecase createClientUsecase;
  var state = Rx<ClientState>(ClientInitial());
  ClientGetx({required this.createClientUsecase});
  createClient(CreateClientEvent event) async {
    state.value = ClientLoading();
    try {
      await createClientUsecase.execute(event.client);
      state.value = ClientCreatedSuccessfully();
    } catch (e) {
      state.value = ClientCreationFailure(e.toString());
    }
  }
}