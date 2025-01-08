
import '../entities/client.dart';
import '../repositories/client_repository.dart';

class LoginClientUsecase{
  final ClientRepository clientRepository;
  LoginClientUsecase(this.clientRepository);
  Future<void>execute(Client client) async{
    return await clientRepository.loginClient(client);
  }
}