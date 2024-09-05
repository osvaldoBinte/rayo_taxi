import 'package:rayo_taxi/features/driver/domain/repositories/driver_repository.dart';

class TokendriverUsecase {
  final DriverRepository driverRepository;
  TokendriverUsecase({required this.driverRepository});
  Future<bool> execute() async {
    return await driverRepository.verifyToken();
  }
}
