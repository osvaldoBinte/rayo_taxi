import 'package:rayo_taxi/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:rayo_taxi/features/notification/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/notification/domain/entities/device.dart';
import 'package:rayo_taxi/features/notification/domain/repositories/notification_repository.dart';

class NotificationRepositoryImp implements NotificationRepository {
  final NotificationLocalDataSource notificationLocalDataSource;
  NotificationRepositoryImp({required this.notificationLocalDataSource});

  @override
  Future<void> updateIdDevice() async {
    return await notificationLocalDataSource.updateIdDevice();
  }

  @override
  Future<List<TravelAlertModel>> getNotification(bool connection) async {
    return await notificationLocalDataSource.getNotification(connection);
  }

  @override
  Future<List<TravelAlertModel>> getNotificationtravel(bool connection) async {
    return await notificationLocalDataSource.getNotificationtravel(connection);
  }
  
  @override
  Future<String?> fetchDeviceId() async {
     return await notificationLocalDataSource.fetchDeviceId();
  }
}
