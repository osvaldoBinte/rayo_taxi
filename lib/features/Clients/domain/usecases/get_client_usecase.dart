import 'package:rayo_taxi/features/Clients/data/models/client_model.dart';
import 'package:rayo_taxi/features/Clients/domain/repositories/client_repository.dart';

class GetClientUsecase{
  final ClientRepository clientRepository;
  GetClientUsecase({required this.clientRepository});
  Future<List<ClientModel>> execute()async{
    return await clientRepository.getClient();
  }
}