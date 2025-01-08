import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/get_device_usecase.dart';

class GetDeviceGetx extends GetxController {
  final GetDeviceUsecase getDeviceUsecase;

  GetDeviceGetx({required this.getDeviceUsecase});

  Future<String?> execute() async {
    try {
      final idDevice = await getDeviceUsecase.execute();
      return idDevice;
    } catch (e) {
      print("Error obteniendo el id_device: $e");
      return null;
    }
  }
}