
import 'package:rayo_taxi/features/notification/domain/entities/device.dart';
import 'package:rayo_taxi/features/notification/domain/repositories/notification_repository.dart';

class IdDeviceUsecase{
  final NotificationRepository notificationRepository;
  IdDeviceUsecase({required this.notificationRepository});
    Future<void>execute() async{
      return await notificationRepository.updateIdDevice();
    }

}