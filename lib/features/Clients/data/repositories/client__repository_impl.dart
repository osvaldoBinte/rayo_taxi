import 'package:rayo_taxi/features/Clients/data/datasources/client_local_data_source.dart';
import 'package:rayo_taxi/features/Clients/domain/entities/client.dart';
import 'package:rayo_taxi/features/Clients/domain/repositories/client_repository.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ClientLocalDataSource clientLocalDataSource;
  ClientRepositoryImpl({required this.clientLocalDataSource});

  @override
  Future<void> createClient(Client client) async {
    return await clientLocalDataSource.createClient(client);
  }
}
