import 'package:rayo_taxi/features/travel/domain/entities/deviceEntitie/device.dart';
import 'package:rayo_taxi/features/travel/domain/entities/getcosttraveEntitie/getcosttravel_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/entities/qualification/qualification_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelalert/travel_alert.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/confirmar_tariff_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/travelwithtariff_entitie.dart';

import '../../data/models/travel/travel_alert_model.dart';

abstract class NotificationRepository {
  Future<void> updateIdDevice();
  Future<List<TravelAlertModel>> getNotification(bool connection);
  Future<List<TravelAlertModel>> current_travel();
  Future<String?> fetchDeviceId();
  Future<List<TravelAlertModel>> getbyIdtravelid(
      int? idTravel, bool connection);
  Future<void> confirmTravelWithTariff(
      ConfirmarTariffEntitie confirmarTariffEntitie);
  Future<void> rejectTravelOffer(
      TravelwithtariffEntitie travelwithtariffEntitie);
  Future<void> removedataaccount();
  Future<void> offerNegotiation(
      TravelwithtariffEntitie travelwithtariffEntitie);
  Future<GetcosttravelEntitie> getcosttravel(
      GetcosttravelEntitie getcosttravelEntitie);
  Future<void> qualification(QualificationEntitie aualificationEntitie);
  Future<void> skipqualification(QualificationEntitie qaualificationEntitie);
}
