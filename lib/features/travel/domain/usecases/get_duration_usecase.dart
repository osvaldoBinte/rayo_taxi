
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/domain/repository/mapa_repository.dart';

class GetDurationUsecase {
  final TravelRepository travelRepository;
  GetDurationUsecase({required this.travelRepository});
 double execute()  {
    return  travelRepository.getDuration();}

}