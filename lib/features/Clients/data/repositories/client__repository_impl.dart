import 'package:rayo_taxi/features/Clients/data/datasources/client_local_data_source.dart';
import 'package:rayo_taxi/features/Clients/data/models/client_model.dart';
import 'package:rayo_taxi/features/Clients/domain/entities/client.dart';
import 'package:rayo_taxi/features/Clients/domain/repositories/client_repository.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ClientLocalDataSource clientLocalDataSource;
  ClientRepositoryImpl({required this.clientLocalDataSource});

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
  Future<String?> getDeviceId() async {
    return await clientLocalDataSource.getDeviceId();
  }

  @override
  Future<List<ClientModel>> getClient() async {
    return await clientLocalDataSource.getClient();
  }
}
