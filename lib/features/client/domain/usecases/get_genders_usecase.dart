import 'package:rayo_taxi/features/client/data/models/genders/genders_model.dart';
import 'package:rayo_taxi/features/client/domain/repositories/client_repository.dart';

class GetGendersUsecase {
  final ClientRepository clientRepository;
  GetGendersUsecase({required this.clientRepository});
  Future<List<GendersModel>> execute() async {
    return await clientRepository.getgenders();
  }
}
