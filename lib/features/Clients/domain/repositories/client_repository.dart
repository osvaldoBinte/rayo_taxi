
import 'package:rayo_taxi/features/Clients/domain/entities/client.dart';

abstract class ClientRepository{
  Future<void>createClient(Client client);
  
}