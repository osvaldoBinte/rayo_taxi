import 'package:rayo_taxi/features/notification/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/notification/domain/entities/device.dart';

abstract class NotificationRepository {
  Future<void> updateIdDevice();
  Future<List<TravelAlertModel>> getNotification(bool connection);
  Future<List<TravelAlertModel>> getNotificationtravel(bool connection);
}
