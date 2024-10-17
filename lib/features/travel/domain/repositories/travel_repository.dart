import 'package:rayo_taxi/features/travel/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/entities/device.dart';

abstract class TravelRepository {
  Future<void> updateIdDevice();
  Future<void> acceptedTravel(int? id_travel);
  Future<void> startTravel(int? id_travel);
  Future<void> endTravel(int? id_travel);
  Future<List<TravelAlertModel>> getNotification(bool connection);
  Future<List<TravelAlertModel>> getalltravel(bool connection);
  Future<List<TravelAlertModel>> getbyIdtravelid(
      int? idTravel, bool connection);
  Future<String?> fetchDeviceId();
}
