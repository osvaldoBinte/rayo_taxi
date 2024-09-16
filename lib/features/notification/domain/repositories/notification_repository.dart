import 'package:rayo_taxi/features/notification/domain/entities/device.dart';

abstract class NotificationRepository{
  Future<void> updateIdDevice();

}