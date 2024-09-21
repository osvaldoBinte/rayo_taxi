import '../../data/models/travel_alert_model.dart';
import '../repositories/notification_repository.dart';

class TravelsAlertUsecase {
  final NotificationRepository notificationRepository;
  TravelsAlertUsecase({required this.notificationRepository});
  Future<List<TravelAlertModel>> execute(bool connection) async {
    return await notificationRepository.getNotification(connection);
  }
}
