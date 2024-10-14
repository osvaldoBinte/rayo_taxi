import 'package:rayo_taxi/features/mapa/domain/entities/travel.dart';
import 'package:rayo_taxi/features/mapa/domain/repository/travel_repository.dart';

class PoshTravelUsecase{
  final TravelRepository travelRepository;
  PoshTravelUsecase({required this.travelRepository});
  Future<void> execute(Travel travel) async {
    return await travelRepository.poshTravel(travel);
  }
}