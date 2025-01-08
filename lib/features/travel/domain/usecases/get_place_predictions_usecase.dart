
 import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/domain/repository/mapa_repository.dart';

class GetPlacePredictionsUsecase {
  final TravelRepository travelRepository;
  GetPlacePredictionsUsecase ({required this.travelRepository});
   Future<List<dynamic>>  execute(String input, {LatLng? location}) async {
      return travelRepository.getPlacePredictions(input,location: location);
    }
 }