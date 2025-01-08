import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/entities/deviceEntitie/device.dart';
import 'package:rayo_taxi/features/travel/domain/entities/getcosttraveEntitie/getcosttravel_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/confirmar_tariff_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/travelwithtariff_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class NotificationRepositoryImp implements NotificationRepository {
  final NotificationLocalDataSource notificationLocalDataSource;
  NotificationRepositoryImp({required this.notificationLocalDataSource});

  @override
  Future<void> updateIdDevice() async {
    return await notificationLocalDataSource.updateIdDevice();
  }

  @override
  Future<List<TravelAlertModel>> getNotification(bool connection) async {
    return await notificationLocalDataSource.getNotification(connection);
  }

  @override
  Future<List<TravelAlertModel>> current_travel() async {
    return await notificationLocalDataSource.current_travel();
  }
  
  @override
  Future<String?> fetchDeviceId() async {
     return await notificationLocalDataSource.fetchDeviceId();
  }
  
  @override
  Future<List<TravelAlertModel>> getbyIdtravelid(int? idTravel, bool connection)  async{
   return await notificationLocalDataSource.getbyIdtravelid(idTravel, connection);
  }
  
  @override
  Future<void> confirmTravelWithTariff(ConfirmarTariffEntitie confirmarTariffEntitie) async {
    return await notificationLocalDataSource.confirmTravelWithTariff(confirmarTariffEntitie);
  }
  
  @override
  Future<void> rejectTravelOffer(TravelwithtariffEntitie travelwithtariffEntitie) async {
    return await notificationLocalDataSource.rejectTravelOffer(travelwithtariffEntitie);
  }
  
  @override
  Future<void> removedataaccount() async {
   return await notificationLocalDataSource.removedataaccount();
  }

  @override
  Future<void> offerNegotiation(TravelwithtariffEntitie travelwithtariffEntitie) async {
    return await notificationLocalDataSource.offerNegotiation(travelwithtariffEntitie);
  }

  @override
  Future<GetcosttravelEntitie> getcosttravel( GetcosttravelEntitie getcosttravelEntitie) async {
    return await notificationLocalDataSource.getcosttravel(getcosttravelEntitie);
  }
}
