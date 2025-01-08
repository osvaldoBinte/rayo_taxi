
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/domain/repository/mapa_repository.dart';

class CalculateDistanceUsecase {
  final TravelRepository travelRepository;
  CalculateDistanceUsecase({required this.travelRepository});
  double execute(LatLng start, LatLng end)  {
    return  travelRepository.calculateDistance(start, end);
  }

}