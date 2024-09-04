import 'package:rayo_taxi/features/Clients/data/datasources/client_local_data_source.dart';
import 'package:rayo_taxi/features/Clients/data/repositories/client__repository_impl.dart';
import 'package:rayo_taxi/features/Clients/domain/usecases/create_client_usecase.dart';
import 'package:rayo_taxi/features/Clients/domain/usecases/login_client_usecase.dart';

import 'features/Clients/domain/usecases/tokenclient_usecase.dart';

class UsecaseConfig {
  ClientLocalDataSourceImp? clientLocalDataSourceImp;
  ClientRepositoryImpl? clientRepositoryImpl;

  CreateClientUsecase? createClientUsecase;
  LoginClientUsecase? loginClientUsecase;
  TokenclientUsecase? tokenclientUsecase;

  UsecaseConfig() {
    clientLocalDataSourceImp = ClientLocalDataSourceImp();
    clientRepositoryImpl =
        ClientRepositoryImpl(clientLocalDataSource: clientLocalDataSourceImp!);

    createClientUsecase = CreateClientUsecase(clientRepositoryImpl!);
    loginClientUsecase = LoginClientUsecase(clientRepositoryImpl!);
    tokenclientUsecase = TokenclientUsecase(clientRepositoryImpl!);
  }
}
