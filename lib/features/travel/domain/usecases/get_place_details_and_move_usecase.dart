
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/domain/repository/mapa_repository.dart';

class GetPlaceDetailsAndMoveUsecase {
  final TravelRepository travelRepository;
  GetPlaceDetailsAndMoveUsecase({required this.travelRepository});
  Future<void> execute(String placeId, Function(LatLng p1) moveToLocation, Function(LatLng p1) addMarker) async {
    return await travelRepository.getPlaceDetailsAndMove(placeId, moveToLocation, addMarker);
  }

}