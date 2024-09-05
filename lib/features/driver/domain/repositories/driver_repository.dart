import 'package:rayo_taxi/features/driver/domain/entities/driver.dart';

abstract class DriverRepository {
  Future<void> loginDriver(Driver driver);
  Future<bool> verifyToken();
}
