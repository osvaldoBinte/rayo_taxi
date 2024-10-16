
import 'package:rayo_taxi/features/travel/domain/entities/device.dart';
import 'package:rayo_taxi/features/travel/domain/repositories/travel_repository.dart';

class IdDeviceUsecase{
  final TravelRepository notificationRepository;
  IdDeviceUsecase({required this.notificationRepository});
    Future<void>execute() async{
      return await notificationRepository.updateIdDevice();
    }

}