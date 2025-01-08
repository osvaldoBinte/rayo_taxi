import 'package:rayo_taxi/features/client/data/models/client_model.dart';
import 'package:rayo_taxi/features/client/data/models/genders/genders_model.dart';
import 'package:rayo_taxi/features/client/domain/entities/client.dart';
import 'package:rayo_taxi/features/client/domain/entities/recoveryPassword/recovery_password_entitie.dart';

abstract class ClientRepository {
  Future<List<ClientModel>> getClient(bool conection);
  Future<void> createClient(Client client);
  Future<void> updateClient(Client client);
  Future<void> loginClient(Client client);
  Future<bool> verifyToken();
  int calcularEdad(String birthdate);
    Future <void> loginGoogle(Client client);
Future<List<GendersModel>> getgenders() ;

  Future<void> CreaterecoveryCode(
      RecoveryPasswordEntitie recoveryPasswordEntitie);
  Future<void> checkRecoveryCode(
      RecoveryPasswordEntitie recoveryPasswordEntitie);
  Future<void> updatePassword(
      RecoveryPasswordEntitie recoveryPasswordEntitie);
}
