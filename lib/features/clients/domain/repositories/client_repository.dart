import 'package:rayo_taxi/features/clients/data/models/client_model.dart';
import 'package:rayo_taxi/features/clients/domain/entities/client.dart';

abstract class ClientRepository {
  Future<List<ClientModel>> getClient(bool conection);
  Future<void> createClient(Client client);
  Future<void> updateClient(Client client);
  Future<void> loginClient(Client client);
  Future<bool> verifyToken();
  Future<String?> getDeviceId();
  int calcularEdad(String birthdate);
}
