import 'package:rayo_taxi/features/driver/data/datasources/driver_local_data_source.dart';
import 'package:rayo_taxi/features/driver/data/repositories/driver_repository_imp.dart';
import 'package:rayo_taxi/features/driver/domain/usecases/login_driver_usecase.dart';
import 'features/driver/domain/usecases/tokendriver_usecase.dart';

class UsecaseConfig {
  DriverLocalDataSourceImp? driverLocalDataSourceImp;
  DriverRepositoryImp?driverRepositoryImp;
  LoginDriverUsecase? loginDriverUsecase;
  TokendriverUsecase?tokendriverUsecase;


  UsecaseConfig() {
    driverLocalDataSourceImp = DriverLocalDataSourceImp();
    driverRepositoryImp = DriverRepositoryImp(driverLocalDataSource: driverLocalDataSourceImp!);
    loginDriverUsecase = LoginDriverUsecase(driverRepository: driverRepositoryImp!);
    tokendriverUsecase = TokendriverUsecase(driverRepository: driverRepositoryImp!);
  }
}
