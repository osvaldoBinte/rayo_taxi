import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import 'package:rayo_taxi/features/mapa/data/datasources/travel_local_data_source.dart';
import 'package:rayo_taxi/features/mapa/domain/entities/travel.dart';
import 'package:rayo_taxi/features/mapa/domain/repository/travel_repository.dart';

class TravelRepositoryImp implements TravelRepository{
  final TravelLocalDataSource travelLocalDataSource;
  TravelRepositoryImp({required this.travelLocalDataSource});

  @override
  double calculateDistance(LatLng start, LatLng end) {
   return  travelLocalDataSource.calculateDistance(start, end);
  }

  @override
  List<LatLng> decodePolyline(String encoded) {
   return  travelLocalDataSource.decodePolyline(encoded);
  }

  @override
  double degreesToRadians(double degrees) {
    return  travelLocalDataSource.degreesToRadians(degrees);
  }

  @override
  Future<String> getEncodedPoints() async {
    return await travelLocalDataSource.getEncodedPoints();
  }

  @override
  Future<void> getPlaceDetailsAndMove(String placeId, Function(LatLng p1) moveToLocation, Function(LatLng p1) addMarker) async {
    return await travelLocalDataSource.getPlaceDetailsAndMove(placeId, moveToLocation, addMarker);
  }

  @override
  Future<List> getPlacePredictions(String input) async {
    return await travelLocalDataSource.getPlacePredictions(input);
  }

  @override
  Future<void> getRoute(LatLng startLocation, LatLng endLocation) async {
    return await travelLocalDataSource.getRoute(startLocation, endLocation);
  }

  @override
  Future<void> poshTravel(Travel travel) async {
    return await travelLocalDataSource.poshTravel(travel);
  }
  
  @override
 Future<void> deleteTravel(String id, bool connection) async {
    return await travelLocalDataSource.deleteTravel(id,connection);
  }

}