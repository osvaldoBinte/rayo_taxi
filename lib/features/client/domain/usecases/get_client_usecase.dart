import 'package:rayo_taxi/features/client/data/models/client_model.dart';
import 'package:rayo_taxi/features/client/domain/repositories/client_repository.dart';

class GetClientUsecase {
  final ClientRepository clientRepository;
  GetClientUsecase({required this.clientRepository});
  Future<List<ClientModel>> execute(bool conection) async {
    return await clientRepository.getClient(conection);
  }
}
