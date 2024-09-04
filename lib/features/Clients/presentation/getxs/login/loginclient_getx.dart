import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/Clients/domain/entities/client.dart';
import 'package:rayo_taxi/features/Clients/domain/usecases/login_client_usecase.dart';

part 'loginclient_event.dart';
part 'loginclient_state.dart';

class LoginclientGetx extends GetxController {
  final LoginClientUsecase loginClientUsecase;
  var state = Rx<LoginclientState>(LoginclientInitial());
  LoginclientGetx({required this.loginClientUsecase});
  createClient(LoginClientEvent event) async {
    state.value = LoginclientLoading();
    try {
      await loginClientUsecase.execute(event.client);
      state.value = LoginclientSuccessfully();
    } catch (e) {
      state.value = LoginclientFailure(e.toString());
    }
  }
}
