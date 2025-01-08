import 'package:rayo_taxi/features/client/domain/entities/client.dart';
import 'package:rayo_taxi/features/client/domain/repositories/client_repository.dart';

class UpdateClientUsecase{
  final ClientRepository clientRepository;
  UpdateClientUsecase({required this.clientRepository});
  Future<void> execute(Client client)async{
    return await clientRepository.updateClient(client);
  }
}