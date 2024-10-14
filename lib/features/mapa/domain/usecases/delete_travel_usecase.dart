import 'package:rayo_taxi/features/mapa/domain/entities/travel.dart';
import 'package:rayo_taxi/features/mapa/domain/repository/travel_repository.dart';

class DeleteTravelUsecase{
  final TravelRepository travelRepository;
  DeleteTravelUsecase({required this.travelRepository});
  Future<void> execute(String id, bool connection) async {
    return await travelRepository.deleteTravel(id,connection);
  }
}