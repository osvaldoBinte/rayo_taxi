import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class TravelRepositoryImp implements TravelRepository{
  final TravelLocalDataSource travelLocalDataSource;
  TravelRepositoryImp({required this.travelLocalDataSource});

  @override
  double calculateDistance(LatLng start, LatLng end) {
   return travelLocalDataSource.calculateDistance(start, end);
  }

  @override
  List<LatLng> decodePolyline(String encoded) {
   return travelLocalDataSource.decodePolyline(encoded);
  }

  @override
  double degreesToRadians(double degrees) {
    return travelLocalDataSource.degreesToRadians(degrees);
  }

  @override
  Future<String> getEncodedPoints() {
    return travelLocalDataSource.getEncodedPoints();
  }

  @override
  Future<void> getPlaceDetailsAndMove(String placeId, Function(LatLng p1) moveToLocation, Function(LatLng p1) addMarker) {
    return travelLocalDataSource.getPlaceDetailsAndMove(placeId, moveToLocation, addMarker);
  }

  @override
  Future<List> getPlacePredictions(String input) {
    return travelLocalDataSource.getPlacePredictions(input);
  }

  @override
  Future<void> getRoute(LatLng startLocation, LatLng endLocation) {
    return travelLocalDataSource.getRoute(startLocation, endLocation);
  }

  @override
  Future<void> poshTravel(Travel travel) {
    return travelLocalDataSource.poshTravel(travel);
  }

}