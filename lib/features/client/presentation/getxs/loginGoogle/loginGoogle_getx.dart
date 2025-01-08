import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/client/domain/entities/client.dart';
import 'package:rayo_taxi/features/client/domain/usecases/login_client_usecase.dart';
import 'package:rayo_taxi/features/client/domain/usecases/login_google_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'loginGoogle_event.dart';
part 'loginGoogle_state.dart';

class LogingoogleGetx extends GetxController {
  final LoginGoogleUsecase loginGoogleUsecase;
  var state = Rx<LogingoogleState>(LogingoogleInitial());
  String? message; // Add this variable

  LogingoogleGetx({required this.loginGoogleUsecase});

  Future<void> logingoogle(LoginGoogleEvent event) async {
    state.value = LogingoogleLoading();
    print('${DateTime.now()}: LogingoogleGetx - LogingoogleLoading');
    try {
      await loginGoogleUsecase.execute(event.client);
      // Retrieve the message from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      message = prefs.getString('login_message');
      state.value = LogingoogleSuccessfully();
      print('${DateTime.now()}: LogingoogleGetx - LogingoogleSuccessfully');
    } catch (e) {
      state.value = LogingoogleFailure(e.toString());
      print('${DateTime.now()}: LogingoogleGetx - LogingoogleFailure: ${e.toString()}');
    }
  }

  void logout() {
    state.value = LogingoogleInitial();
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('auth_token');
    });
  }
}
