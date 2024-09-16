import 'package:rayo_taxi/features/driver/domain/entities/driver.dart';

import '../../data/models/driver_model.dart';

abstract class DriverRepository {
  Future<void> loginDriver(Driver driver);
  Future<List<DriverModel>> getDriver(bool conection);
}
