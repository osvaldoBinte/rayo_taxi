import 'package:rayo_taxi/features/client/domain/entities/recoveryPassword/recovery_password_entitie.dart';
import 'package:rayo_taxi/features/client/domain/repositories/client_repository.dart';

class UpdatePasswordUsecase {
    final ClientRepository clientRepository;
  UpdatePasswordUsecase({required this.clientRepository});
  Future<void>execute(RecoveryPasswordEntitie recoveryPasswordEntitie) async{
    return await clientRepository.updatePassword(recoveryPasswordEntitie);
  
  }
}