import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/entities/device.dart';
import 'package:rayo_taxi/features/travel/domain/repositories/travel_repository.dart';

class TravelRepositoryImp {
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
  Future<List<TravelAlertModel>> getbyIdtravelid(int idTravel, bool connection) {
    // TODO: implement getbyIdtravelid
    throw UnimplementedError();
  }

}