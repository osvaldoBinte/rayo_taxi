import 'package:rayo_taxi/features/client/domain/repositories/client_repository.dart';

class CalculateAgeUsecase {
  final ClientRepository clientRepository;
  CalculateAgeUsecase({required this.clientRepository});
  int execute(String birthdate)  {
    return clientRepository.calcularEdad(birthdate);
  }
}
