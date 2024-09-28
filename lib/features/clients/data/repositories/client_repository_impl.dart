import 'package:rayo_taxi/features/clients/data/datasources/client_local_data_source.dart';
import 'package:rayo_taxi/features/clients/data/models/client_model.dart';
import 'package:rayo_taxi/features/clients/domain/entities/client.dart';
import 'package:rayo_taxi/features/clients/domain/repositories/client_repository.dart';

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
}
