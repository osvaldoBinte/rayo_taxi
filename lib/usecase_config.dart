import 'package:rayo_taxi/features/clients/data/datasources/client_local_data_source.dart';
import 'package:rayo_taxi/features/clients/data/repositories/client_repository_impl.dart';
import 'package:rayo_taxi/features/clients/domain/usecases/create_client_usecase.dart';
import 'package:rayo_taxi/features/clients/domain/usecases/device_cient_usecase.dart';
import 'package:rayo_taxi/features/clients/domain/usecases/get_client_usecase.dart';
import 'package:rayo_taxi/features/clients/domain/usecases/login_client_usecase.dart';
import 'package:rayo_taxi/features/clients/domain/usecases/update_client_usecase.dart';
import 'package:rayo_taxi/features/travel/data/repositories/travel_repository_Imp.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/posh_travel_usecase.dart';
import 'features/clients/domain/usecases/tokenclient_usecase.dart';

class UsecaseConfig {
  ClientLocalDataSourceImp? clientLocalDataSourceImp;
  ClientRepositoryImpl? clientRepositoryImpl;
  TravelRepositoryImp? travelRepositoryImp;

  CreateClientUsecase? createClientUsecase;
  LoginClientUsecase? loginClientUsecase;
  TokenclientUsecase? tokenclientUsecase;
  DeviceCientUsecase?deviceCientUsecase;
  GetClientUsecase? getClientUsecase;
  UpdateClientUsecase? updateClientUsecase;

  PoshTravelUsecase? poshTravelUsecase;
  UsecaseConfig() {
    clientLocalDataSourceImp = ClientLocalDataSourceImp();
    clientRepositoryImpl =ClientRepositoryImpl(clientLocalDataSource: clientLocalDataSourceImp!);
    createClientUsecase = CreateClientUsecase(clientRepositoryImpl!);
    loginClientUsecase = LoginClientUsecase(clientRepositoryImpl!);
    tokenclientUsecase = TokenclientUsecase(clientRepositoryImpl!);
    deviceCientUsecase = DeviceCientUsecase(clientRepository: clientRepositoryImpl!);
    getClientUsecase = GetClientUsecase(clientRepository: clientRepositoryImpl!);
    updateClientUsecase = UpdateClientUsecase(clientRepository: clientRepositoryImpl!);
    poshTravelUsecase = PoshTravelUsecase(travelRepository: travelRepositoryImp!);
  }
}
