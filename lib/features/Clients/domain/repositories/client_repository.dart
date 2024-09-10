import 'package:rayo_taxi/features/Clients/data/models/client_model.dart';
import 'package:rayo_taxi/features/Clients/domain/entities/client.dart';

abstract class ClientRepository {
    Future<List<ClientModel>> getClient();

  Future<void> createClient(Client client);
  Future<void> loginClient(Client client);
  Future<bool> verifyToken();
  Future<String?> getDeviceId();
}
