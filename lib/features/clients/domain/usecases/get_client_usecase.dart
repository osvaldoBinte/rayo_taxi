import 'package:rayo_taxi/features/clients/data/models/client_model.dart';
import 'package:rayo_taxi/features/clients/domain/repositories/client_repository.dart';

class GetClientUsecase {
  final ClientRepository clientRepository;
  GetClientUsecase({required this.clientRepository});
  Future<List<ClientModel>> execute(bool conection) async {
    return await clientRepository.getClient(conection);
  }
}
