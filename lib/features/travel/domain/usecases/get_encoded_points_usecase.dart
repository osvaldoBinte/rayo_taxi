


import 'package:rayo_taxi/features/travel/domain/repository/mapa_repository.dart';

class GetEncodedPointsUsecase {
    final TravelRepository travelRepository;
    GetEncodedPointsUsecase({required this.travelRepository});
     Future<String> execute() async{
        return await travelRepository.getEncodedPoints();
      }

}