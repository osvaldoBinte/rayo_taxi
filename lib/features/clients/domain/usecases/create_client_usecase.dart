import 'package:rayo_taxi/features/clients/domain/entities/client.dart';
import 'package:rayo_taxi/features/clients/domain/repositories/client_repository.dart';

class CreateClientUsecase {
  final ClientRepository clientRepository;
  CreateClientUsecase(this.clientRepository);
  Future<void>execute(Client client) async{
    return await clientRepository.createClient(client);
  
  }
}