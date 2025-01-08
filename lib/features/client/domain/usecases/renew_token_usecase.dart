import 'package:rayo_taxi/features/client/domain/entities/recoveryPassword/recovery_password_entitie.dart';
import 'package:rayo_taxi/features/client/domain/repositories/client_repository.dart';

class RenewTokenUsecase {
   final ClientRepository clientRepository;
  RenewTokenUsecase({required this.clientRepository});
 Future<bool> execute() async{
    return await clientRepository.verifyToken();
  }
}