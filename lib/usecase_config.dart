import 'package:rayo_taxi/features/Clients/data/datasources/client_local_data_source.dart';
import 'package:rayo_taxi/features/Clients/data/repositories/client__repository_impl.dart';
import 'package:rayo_taxi/features/Clients/domain/usecases/create_client_usecase.dart';

class UsecaseConfig{
  ClientLocalDataSourceImp? clientLocalDataSourceImp;
  ClientRepositoryImpl? clientRepositoryImpl;

  CreateClientUsecase?createClientUsecase;

  UsecaseConfig(){
    clientLocalDataSourceImp=ClientLocalDataSourceImp();
    clientRepositoryImpl=ClientRepositoryImpl(clientLocalDataSource: clientLocalDataSourceImp!);

   createClientUsecase=CreateClientUsecase(clientRepositoryImpl!);
  }
}