
import 'package:rayo_taxi/features/travel/domain/repositories/travel_repository.dart';

class AcceptedTravelUsecase{
  final TravelRepository travelRepository;
  AcceptedTravelUsecase({required this.travelRepository});
    Future<void>execute(int? id_travel) async{
      return await travelRepository.acceptedTravel(id_travel);
    }

}