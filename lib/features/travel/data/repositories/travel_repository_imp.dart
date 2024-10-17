import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/entities/device.dart';
import 'package:rayo_taxi/features/travel/domain/repositories/travel_repository.dart';

class TravelRepositoryImp implements TravelRepository {
  final TravelLocalDataSource travelLocalDataSource;
  TravelRepositoryImp({required this.travelLocalDataSource});

  @override
  Future<void> updateIdDevice() async {
    return await travelLocalDataSource.updateIdDevice();
  }

  @override
  Future<List<TravelAlertModel>> getNotification(bool connection) async {
    return await travelLocalDataSource.getTravel(connection);
  }

  @override
  Future<List<TravelAlertModel>> getalltravel(bool connection) async {
    return await travelLocalDataSource.getalltravel(connection);
  }

  @override
  Future<List<TravelAlertModel>> getbyIdtravelid(
      int? idTravel, bool connection) async {
    return await travelLocalDataSource.getbyIdtravelid(idTravel, connection);
  }

  @override
  Future<String?> fetchDeviceId() async {
    return await travelLocalDataSource.fetchDeviceId();
  }
  
  @override
  Future<void> acceptedTravel(int? id_travel) async {
    return await travelLocalDataSource.acceptedTravel(id_travel);
  }
  
  @override
  Future<void> endTravel(int? id_travel) async {
    return await travelLocalDataSource.endTravel(id_travel);
  }
  
  @override
  Future<void> startTravel(int? id_travel) async {
    return await travelLocalDataSource.startTravel(id_travel);
  }
}
