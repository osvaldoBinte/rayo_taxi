import 'package:rayo_taxi/features/driver/data/datasources/driver_local_data_source.dart';
import 'package:rayo_taxi/features/driver/data/repositories/driver_repository_imp.dart';
import 'package:rayo_taxi/features/driver/domain/usecases/get_driver_usecase.dart';
import 'package:rayo_taxi/features/driver/domain/usecases/login_driver_usecase.dart';
import 'package:rayo_taxi/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:rayo_taxi/features/notification/data/repositories/notification_repository_imp.dart';
import 'package:rayo_taxi/features/notification/domain/usecases/id_device_usecase.dart';
import 'package:rayo_taxi/features/notification/domain/usecases/travel_alert_usecase.dart';
import 'package:rayo_taxi/features/notification/domain/usecases/travels_alert_usecase.dart';

class UsecaseConfig {
  DriverLocalDataSourceImp? driverLocalDataSourceImp;
  DriverRepositoryImp?driverRepositoryImp;
  NotificationLocalDataSourceImp? notificationLocalDataSourceImp;
  NotificationRepositoryImp? notificationRepositoryImp;

  LoginDriverUsecase? loginDriverUsecase;
  GetDriverUsecase? getDriverUsecase;
  IdDeviceUsecase? idDeviceUsecase;

  TravelsAlertUsecase? travelsAlertUsecase;
  TravelAlertUsecase? travelAlertUsecase;  
  UsecaseConfig() {
    driverLocalDataSourceImp = DriverLocalDataSourceImp();
    notificationLocalDataSourceImp = NotificationLocalDataSourceImp();
    driverRepositoryImp = DriverRepositoryImp(driverLocalDataSource: driverLocalDataSourceImp!);
    notificationRepositoryImp = NotificationRepositoryImp(notificationLocalDataSource: notificationLocalDataSourceImp!);
    loginDriverUsecase = LoginDriverUsecase(driverRepository: driverRepositoryImp!);
    getDriverUsecase = GetDriverUsecase(driverRepository: driverRepositoryImp!);
    idDeviceUsecase = IdDeviceUsecase(notificationRepository: notificationRepositoryImp!);
    travelAlertUsecase = TravelAlertUsecase(notificationRepository: notificationRepositoryImp!);
    travelsAlertUsecase = TravelsAlertUsecase(notificationRepository: notificationRepositoryImp!);
  }
}
