
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class RemoveDataAccountUsecase {
   final NotificationRepository notificationRepository;
  RemoveDataAccountUsecase({required this.notificationRepository});
  Future<void> execute() async{
    return await notificationRepository.removedataaccount();
  }
}