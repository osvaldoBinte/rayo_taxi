
 import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class GetPlacePredictionsUsecase {
  final TravelRepository travelRepository;
  GetPlacePredictionsUsecase ({required this.travelRepository});
    Future<List> execute(String input) async {
      return travelRepository.getPlacePredictions(input);
    }
 }