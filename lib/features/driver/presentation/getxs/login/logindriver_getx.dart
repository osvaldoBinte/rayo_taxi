import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/driver/domain/entities/driver.dart';
import 'package:rayo_taxi/features/driver/domain/usecases/login_driver_usecase.dart';

part 'logindriver_event.dart';
part 'logindriver_state.dart';

class LogindriverGetx extends GetxController {
  final LoginDriverUsecase loginDriverUsecase;
  var state = Rx<LogindriverState>(LogindriverInitial());
  LogindriverGetx({required this.loginDriverUsecase});
  createClient(LoginDriverEvent event) async {
    state.value = LogindriverLoading();
    try {
      await loginDriverUsecase.execute(event.driver);
      state.value = LogindriverSuccessfully();
    } catch (e) {
      state.value = LogindriverFailure(e.toString());
    }
  }
}
