
import 'package:rayo_taxi/features/driver/data/datasources/driver_local_data_source.dart';
import 'package:rayo_taxi/features/driver/domain/entities/driver.dart';
import 'package:rayo_taxi/features/driver/domain/repositories/driver_repository.dart';

class DriverRepositoryImp implements DriverRepository{
  final DriverLocalDataSource driverLocalDataSource;
  DriverRepositoryImp({required this.driverLocalDataSource});

  @override
  Future<void> loginDriver(Driver driver) async {
   return await driverLocalDataSource.loginDriver(driver);
  }

  @override
  Future<bool> verifyToken() async {
    return await driverLocalDataSource.verifyToken();
  }

}