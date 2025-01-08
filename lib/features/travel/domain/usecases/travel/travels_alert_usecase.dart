import '../../../data/models/travel/travel_alert_model.dart';
import '../../repository/travel_repository.dart';

class TravelsAlertUsecase {
  final NotificationRepository notificationRepository;
  TravelsAlertUsecase({required this.notificationRepository});
  Future<List<TravelAlertModel>> execute(bool connection) async {
    return await notificationRepository.getNotification(connection);
  }
}
