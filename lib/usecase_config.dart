import 'package:rayo_taxi/features/driver/data/datasources/driver_local_data_source.dart';
import 'package:rayo_taxi/features/driver/data/repositories/driver_repository_imp.dart';
import 'package:rayo_taxi/features/driver/domain/usecases/get_driver_usecase.dart';
import 'package:rayo_taxi/features/driver/domain/usecases/login_driver_usecase.dart';
import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';
import 'package:rayo_taxi/features/travel/data/repositories/travel_repository_imp.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/id_device_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel_alert_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel_by_id_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travels_alert_usecase.dart';

class UsecaseConfig {
  DriverLocalDataSourceImp? driverLocalDataSourceImp;
  DriverRepositoryImp?driverRepositoryImp;
  TravelLocalDataSourceImp? travelLocalDataSourceImp;
  TravelRepositoryImp? travelRepositoryImp;

  LoginDriverUsecase? loginDriverUsecase;
  GetDriverUsecase? getDriverUsecase;
  IdDeviceUsecase? idDeviceUsecase;

  TravelsAlertUsecase? travelsAlertUsecase;
  TravelAlertUsecase? travelAlertUsecase;  
  TravelByIdUsecase? travelByIdUsecase;
  UsecaseConfig() {
    driverLocalDataSourceImp = DriverLocalDataSourceImp();
    travelLocalDataSourceImp = TravelLocalDataSourceImp();
    driverRepositoryImp = DriverRepositoryImp(driverLocalDataSource: driverLocalDataSourceImp!);
    travelRepositoryImp = TravelRepositoryImp(travelLocalDataSource: travelLocalDataSourceImp!);
    loginDriverUsecase = LoginDriverUsecase(driverRepository: driverRepositoryImp!);
    getDriverUsecase = GetDriverUsecase(driverRepository: driverRepositoryImp!);
    idDeviceUsecase = IdDeviceUsecase(notificationRepository: travelRepositoryImp!);
    travelAlertUsecase = TravelAlertUsecase(travelRepository: travelRepositoryImp!);
    travelsAlertUsecase = TravelsAlertUsecase(travelRepository: travelRepositoryImp!);
    travelByIdUsecase = TravelByIdUsecase(travelRepository:travelRepositoryImp!);
  }
}
