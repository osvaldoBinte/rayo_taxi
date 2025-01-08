import 'package:rayo_taxi/features/client/data/repositories/client_repository_impl.dart';
import 'package:rayo_taxi/features/client/domain/entities/client.dart';
import 'package:rayo_taxi/features/client/domain/repositories/client_repository.dart';

class LoginGoogleUsecase {
  final ClientRepository clientRepository;
  LoginGoogleUsecase({required this.clientRepository});
  Future<void> execute(Client client) async{
    return await clientRepository.loginGoogle(client);
  }
}
