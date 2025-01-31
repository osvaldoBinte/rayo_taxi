import 'package:rayo_taxi/features/client/data/datasources/client_local_data_source.dart';
import 'package:rayo_taxi/features/client/data/models/client_model.dart';
import 'package:rayo_taxi/features/client/data/models/genders/genders_model.dart';
import 'package:rayo_taxi/features/client/data/models/google/google_mensaje_model.dart';
import 'package:rayo_taxi/features/client/domain/entities/client.dart';
import 'package:rayo_taxi/features/client/domain/entities/recoveryPassword/recovery_password_entitie.dart';
import 'package:rayo_taxi/features/client/domain/repositories/client_repository.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ClientLocalDataSource clientLocalDataSource;
  ClientRepositoryImpl({required this.clientLocalDataSource});
  
  @override
  Future<List<ClientModel>> getClient(bool conection) async {
    return await clientLocalDataSource.getClient(conection);
  }

  @override
  Future<void> createClient(Client client) async {
    return await clientLocalDataSource.createClient(client);
  }

  @override
  Future<void> loginClient(Client client) async {
    return await clientLocalDataSource.loginClient(client);
  }

  @override
  Future<bool> verifyToken() async {
    return await clientLocalDataSource.verifyToken();
  }


  @override
  Future<void> updateClient(Client client) async {
    return await clientLocalDataSource.updateClient(client);
  }
  
  @override
  int calcularEdad(String birthdate)  {
   return clientLocalDataSource.calcularEdad(birthdate);
  }
  
  @override
  Future<GoogleMensajeModel> loginGoogle(Client client) async {
    return await clientLocalDataSource.loginGoogle(client);
  }

  @override
  Future<List<GendersModel>> getgenders() async {
    return await clientLocalDataSource.getgenders();
  }

  @override
  Future<void> CreaterecoveryCode(RecoveryPasswordEntitie recoveryPasswordEntitie) async {
    return await clientLocalDataSource.CreaterecoveryCode(recoveryPasswordEntitie);
  }

  @override
  Future<void> checkRecoveryCode(RecoveryPasswordEntitie recoveryPasswordEntitie) async {
    return await clientLocalDataSource.checkRecoveryCode(recoveryPasswordEntitie);
  }

  @override
  Future<void> updatePassword(RecoveryPasswordEntitie recoveryPasswordEntitie) async {
   return await clientLocalDataSource.updatePassword(recoveryPasswordEntitie);
  }
  
 
  
}
