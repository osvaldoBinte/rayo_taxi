import 'package:flutter/material.dart';
import 'package:rayo_taxi/features/client/data/datasources/client_local_data_source.dart';
import 'package:rayo_taxi/features/client/data/repositories/client_repository_impl.dart';
import 'package:rayo_taxi/features/client/domain/usecases/calculate_age_usecase.dart';
import 'package:rayo_taxi/features/client/domain/usecases/check_recovery_code_usecase.dart';
import 'package:rayo_taxi/features/client/domain/usecases/create_client_usecase.dart';
import 'package:rayo_taxi/features/client/domain/usecases/create_recovery_code_usecase.dart';
import 'package:rayo_taxi/features/client/domain/usecases/get_client_usecase.dart';
import 'package:rayo_taxi/features/client/domain/usecases/get_genders_usecase.dart';
import 'package:rayo_taxi/features/client/domain/usecases/login_client_usecase.dart';
import 'package:rayo_taxi/features/client/domain/usecases/login_google_usecase.dart';
import 'package:rayo_taxi/features/client/domain/usecases/renew_token_usecase.dart';
import 'package:rayo_taxi/features/client/domain/usecases/update_client_usecase.dart';
import 'package:rayo_taxi/features/client/domain/usecases/update_password_usecase.dart';
import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';
import 'package:rayo_taxi/features/travel/data/repositories/notification_repository_imp.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/calculate_distance_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/decode_polyline_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_duration_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_encoded_points_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_route_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/confirm_travel_with_tariff_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/get_cost_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/get_device_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/id_device_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/offer_negotiation_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/reject_travel_offer_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/remove_data_account_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/current_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/travel_by_id_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/travels_alert_usecase.dart';
import 'package:rayo_taxi/features/travel/data/datasources/mapa_local_data_source.dart';
import 'package:rayo_taxi/features/travel/data/repositories/travel_repository_Imp.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/delete_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_place_details_and_move_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_place_predictions_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_search_history_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/posh_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/save_search_history_usecase.dart';
import 'features/client/domain/usecases/tokenclient_usecase.dart';

class UsecaseConfig {
  ClientLocalDataSourceImp? clientLocalDataSourceImp;
  ClientRepositoryImpl? clientRepositoryImpl;
  TravelLocalDataSourceImp? travelLocalDataSourceImp;
  TravelRepositoryImp? travelRepositoryImp;
  NotificationLocalDataSourceImp? notificationLocalDataSourceImp;
  NotificationRepositoryImp? notificationRepositoryImp;
  RenewTokenUsecase?renewTokenUsecase;
  CreateClientUsecase? createClientUsecase;
  LoginClientUsecase? loginClientUsecase;
  TokenclientUsecase? tokenclientUsecase;
  GetClientUsecase? getClientUsecase;
  UpdateClientUsecase? updateClientUsecase;
  CalculateAgeUsecase? calculateAgeUsecase;
  LoginGoogleUsecase? loginGoogleUsecase;

  PoshTravelUsecase? poshTravelUsecase;
  OfferNegotiationUsecase? offerNegotiationUsecase;
  GetCostTravelUsecase? getCostTravelUsecase;
  
  IdDeviceUsecase? idDeviceUsecase;
  GetDeviceUsecase? getDeviceUsecase;

  TravelsAlertUsecase? travelsAlertUsecase;
  CurrentTravelUsecase? currentTravelUsecase;
  DeleteTravelUsecase? deleteTravelUsecase;
  TravelByIdUsecase? travelByIdUsecase;

  GetSearchHistoryUsecase? getSearchHistoryUsecase;
  SaveSearchHistoryUsecase? saveSearchHistoryUsecase;
  GetPlaceDetailsAndMoveUsecase? getPlaceDetailsAndMoveUsecase;
  GetPlacePredictionsUsecase ? getPlacePredictionsUsecase;
  CalculateDistanceUsecase ? calculateDistanceUsecase;
  GetRouteUsecase ? getRouteUsecase;
GetEncodedPointsUsecase ? getEncodedPointsUsecase;
DecodePolylineUsecase ? decodePolylineUsecase;
GetDurationUsecase? getDurationUsecase;


  ConfirmTravelWithTariffUsecase?confirmTravelWithTariffUsecase;
  RejectTravelOfferUsecase?rejectTravelOfferUsecase;

  RemoveDataAccountUsecase? removeDataAccountUsecase;
  GetGendersUsecase? getGendersUsecase;

  CreateRecoveryCodeUsecase? createRecoveryCodeUsecase;
  UpdatePasswordUsecase? updatePasswordUsecase;
  CheckRecoveryCodeUsecase? checkRecoveryCodeUsecase;

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
    getClientUsecase = GetClientUsecase(clientRepository: clientRepositoryImpl!);
    updateClientUsecase = UpdateClientUsecase(clientRepository: clientRepositoryImpl!);
    calculateAgeUsecase = CalculateAgeUsecase(clientRepository: clientRepositoryImpl!);
    loginGoogleUsecase = LoginGoogleUsecase(clientRepository: clientRepositoryImpl!);
   renewTokenUsecase = RenewTokenUsecase(clientRepository: clientRepositoryImpl!);

    poshTravelUsecase = PoshTravelUsecase(travelRepository: travelRepositoryImp!);
    deleteTravelUsecase = DeleteTravelUsecase(travelRepository: travelRepositoryImp!);
    offerNegotiationUsecase = OfferNegotiationUsecase(notificationRepository: notificationRepositoryImp!);
    getCostTravelUsecase = GetCostTravelUsecase(notificationRepository: notificationRepositoryImp!);

    idDeviceUsecase = IdDeviceUsecase(notificationRepository: notificationRepositoryImp!);
    getDeviceUsecase = GetDeviceUsecase(notificationRepository: notificationRepositoryImp!);

    travelsAlertUsecase = TravelsAlertUsecase(notificationRepository: notificationRepositoryImp!);
    currentTravelUsecase = CurrentTravelUsecase(notificationRepository: notificationRepositoryImp!);
    travelByIdUsecase = TravelByIdUsecase(travelRepository: notificationRepositoryImp!);

    getSearchHistoryUsecase = GetSearchHistoryUsecase(travelRepository: travelRepositoryImp!);
    saveSearchHistoryUsecase = SaveSearchHistoryUsecase(travelRepository: travelRepositoryImp!);
    getPlaceDetailsAndMoveUsecase = GetPlaceDetailsAndMoveUsecase(travelRepository: travelRepositoryImp!);
    getPlacePredictionsUsecase = GetPlacePredictionsUsecase(travelRepository: travelRepositoryImp!);
    calculateDistanceUsecase = CalculateDistanceUsecase(travelRepository: travelRepositoryImp!);
    getRouteUsecase = GetRouteUsecase(travelRepository: travelRepositoryImp!);
    getEncodedPointsUsecase = GetEncodedPointsUsecase(travelRepository: travelRepositoryImp!);    
    decodePolylineUsecase = DecodePolylineUsecase(travelRepository: travelRepositoryImp!);
    getDurationUsecase = GetDurationUsecase(travelRepository: travelRepositoryImp!);

 
   confirmTravelWithTariffUsecase = ConfirmTravelWithTariffUsecase(notificationRepository: notificationRepositoryImp!);
  rejectTravelOfferUsecase = RejectTravelOfferUsecase(notificationRepository: notificationRepositoryImp!);

  removeDataAccountUsecase = RemoveDataAccountUsecase(notificationRepository: notificationRepositoryImp!);
  getGendersUsecase =   GetGendersUsecase(clientRepository: clientRepositoryImpl!);



   createRecoveryCodeUsecase=CreateRecoveryCodeUsecase(clientRepository:clientRepositoryImpl!);
  updatePasswordUsecase=UpdatePasswordUsecase(clientRepository:clientRepositoryImpl!);
   checkRecoveryCodeUsecase=CheckRecoveryCodeUsecase(clientRepository:clientRepositoryImpl!);
  }
}
