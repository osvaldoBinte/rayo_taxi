import 'package:flutter/material.dart';
import 'package:rayo_taxi/features/clients/data/datasources/client_local_data_source.dart';
import 'package:rayo_taxi/features/clients/data/repositories/client_repository_impl.dart';
import 'package:rayo_taxi/features/clients/domain/usecases/create_client_usecase.dart';
import 'package:rayo_taxi/features/clients/domain/usecases/device_cient_usecase.dart';
import 'package:rayo_taxi/features/clients/domain/usecases/get_client_usecase.dart';
import 'package:rayo_taxi/features/clients/domain/usecases/login_client_usecase.dart';
import 'package:rayo_taxi/features/clients/domain/usecases/update_client_usecase.dart';
import 'package:rayo_taxi/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:rayo_taxi/features/notification/data/repositories/notification_repository_imp.dart';
import 'package:rayo_taxi/features/notification/domain/usecases/id_device_usecase.dart';
import 'package:rayo_taxi/features/notification/domain/usecases/travel_alert_usecase.dart';
import 'package:rayo_taxi/features/notification/domain/usecases/travels_alert_usecase.dart';
import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';
import 'package:rayo_taxi/features/travel/data/repositories/travel_repository_Imp.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/posh_travel_usecase.dart';
import 'features/clients/domain/usecases/tokenclient_usecase.dart';

class UsecaseConfig {
  ClientLocalDataSourceImp? clientLocalDataSourceImp;
  ClientRepositoryImpl? clientRepositoryImpl;
  TravelLocalDataSourceImp? travelLocalDataSourceImp;
  TravelRepositoryImp? travelRepositoryImp;
  NotificationLocalDataSourceImp? notificationLocalDataSourceImp;
  NotificationRepositoryImp? notificationRepositoryImp;

  CreateClientUsecase? createClientUsecase;
  LoginClientUsecase? loginClientUsecase;
  TokenclientUsecase? tokenclientUsecase;
  DeviceCientUsecase? deviceCientUsecase;
  GetClientUsecase? getClientUsecase;
  UpdateClientUsecase? updateClientUsecase;

  PoshTravelUsecase? poshTravelUsecase;
  
  IdDeviceUsecase? idDeviceUsecase;
  TravelsAlertUsecase? travelsAlertUsecase;
  TravelAlertUsecase? travelAlertUsecase;
  UsecaseConfig() {
    clientLocalDataSourceImp = ClientLocalDataSourceImp();
    travelLocalDataSourceImp = TravelLocalDataSourceImp();
    notificationLocalDataSourceImp = NotificationLocalDataSourceImp();

    clientRepositoryImpl = ClientRepositoryImpl(clientLocalDataSource: clientLocalDataSourceImp!);
    travelRepositoryImp =TravelRepositoryImp(travelLocalDataSource: travelLocalDataSourceImp!);
    notificationRepositoryImp = NotificationRepositoryImp(notificationLocalDataSource: notificationLocalDataSourceImp!);

    createClientUsecase = CreateClientUsecase(clientRepositoryImpl!);
    loginClientUsecase = LoginClientUsecase(clientRepositoryImpl!);
    tokenclientUsecase = TokenclientUsecase(clientRepositoryImpl!);
    deviceCientUsecase =DeviceCientUsecase(clientRepository: clientRepositoryImpl!);
    getClientUsecase = GetClientUsecase(clientRepository: clientRepositoryImpl!);
    updateClientUsecase = UpdateClientUsecase(clientRepository: clientRepositoryImpl!);
   
    poshTravelUsecase = PoshTravelUsecase(travelRepository: travelRepositoryImp!);

    idDeviceUsecase = IdDeviceUsecase(notificationRepository: notificationRepositoryImp!);
    travelsAlertUsecase = TravelsAlertUsecase(notificationRepository: notificationRepositoryImp!);
travelAlertUsecase = TravelAlertUsecase(notificationRepository: notificationRepositoryImp!);
  }
}
