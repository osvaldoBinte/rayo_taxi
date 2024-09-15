import 'package:rayo_taxi/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:rayo_taxi/features/notification/domain/entities/device.dart';
import 'package:rayo_taxi/features/notification/domain/repositories/notification_repository.dart';

class NotificationRepositoryImp implements NotificationRepository{
  final NotificationLocalDataSource notificationLocalDataSource;
  NotificationRepositoryImp({required this.notificationLocalDataSource});

  @override
  Future<void> updateIdDevice() async {
    return await notificationLocalDataSource.updateIdDevice();
  }

}