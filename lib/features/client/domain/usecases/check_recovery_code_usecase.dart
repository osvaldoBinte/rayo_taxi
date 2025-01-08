import 'package:rayo_taxi/features/client/domain/entities/recoveryPassword/recovery_password_entitie.dart';
import 'package:rayo_taxi/features/client/domain/repositories/client_repository.dart';

class CheckRecoveryCodeUsecase {
  final ClientRepository clientRepository;
  CheckRecoveryCodeUsecase({required this.clientRepository});
  Future<void>execute(RecoveryPasswordEntitie recoveryPasswordEntitie) async{
    return await clientRepository.checkRecoveryCode(recoveryPasswordEntitie);
  
  }
}