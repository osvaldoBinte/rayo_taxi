import 'package:rayo_taxi/features/travel/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/entities/device.dart';

abstract class TravelRepository {
  Future<void> updateIdDevice();
  Future<List<TravelAlertModel>> getNotification(bool connection);
  Future<List<TravelAlertModel>> getalltravel(bool connection);
  Future<List<TravelAlertModel>> getbyIdtravelid(
      int idTravel, bool connection);
}
