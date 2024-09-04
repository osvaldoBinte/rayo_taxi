import '../entities/client.dart';
import '../repositories/client_repository.dart';

class TokenclientUsecase {
  final ClientRepository clientRepository;
  TokenclientUsecase(this.clientRepository);
  Future<bool> execute() async {
    return await clientRepository.verifyToken();
  }
}
