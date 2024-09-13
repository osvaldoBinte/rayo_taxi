import 'package:rayo_taxi/features/clients/domain/repositories/client_repository.dart';

class DeviceCientUsecase{
  final ClientRepository clientRepository;
  DeviceCientUsecase({required this.clientRepository});
    Future<String?> execute() async{
      return await clientRepository.getDeviceId();
    }

}