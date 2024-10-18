import 'package:rayo_taxi/features/notification/domain/entities/device.dart';
import 'package:rayo_taxi/features/notification/domain/entities/travel_alert.dart';

import '../../data/models/travel_alert_model.dart';

abstract class NotificationRepository {
  Future<void> updateIdDevice();
  Future<List<TravelAlertModel>> getNotification(bool connection);
  Future<List<TravelAlertModel>> getNotificationtravel(bool connection);
  Future<String?> fetchDeviceId();
  Future<List<TravelAlertModel>> getbyIdtravelid(int? idTravel, bool connection);
}
