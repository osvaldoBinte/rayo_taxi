import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/Clients/domain/usecases/device_cient_usecase.dart';

part 'device_event.dart';
part 'device_state.dart';

class DeviceGetx extends GetxController {
  final DeviceCientUsecase deviceCientUsecase;

  var deviceState = Rx<DeviceState>(DeviceInitial());

  DeviceGetx({required this.deviceCientUsecase});

  Future<void> getDeviceId() async {
    deviceState.value = DeviceLoading();
    try {
      await deviceCientUsecase.execute();
      deviceState.value = DeviceSuccessfully();
    } catch (e) {
      deviceState.value = DeviceError(e.toString());
    }
  }
}
