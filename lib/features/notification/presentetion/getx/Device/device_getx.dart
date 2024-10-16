import 'package:meta/meta.dart';
import 'package:get/get.dart';
import '../../../domain/usecases/id_device_usecase.dart';

part 'device_event.dart';
part 'device_state.dart';

class DeviceGetx extends GetxController {
  final IdDeviceUsecase idDeviceUsecase;

  var deviceState = Rx<DeviceState>(DeviceInitial());

  DeviceGetx({required this.idDeviceUsecase});

  Future<void> getDeviceId() async {
    deviceState.value = DeviceLoading();
    try {
      await idDeviceUsecase.execute();
      deviceState.value = DeviceSuccessfully();
    } catch (e) {
      deviceState.value = DeviceError(e.toString());
    }
  }
}
