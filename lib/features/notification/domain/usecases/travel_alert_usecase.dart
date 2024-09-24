

import 'package:rayo_taxi/features/notification/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/notification/domain/repositories/notification_repository.dart';

class TravelAlertUsecase {
  final NotificationRepository notificationRepository;
  TravelAlertUsecase({required this.notificationRepository});
  Future<List<TravelAlertModel>> execute(bool connection) async {
    return await notificationRepository.getNotificationtravel(connection);
  }
}