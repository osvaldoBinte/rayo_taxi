

import 'package:rayo_taxi/features/travel/domain/repository/mapa_repository.dart';

class GetSearchHistoryUsecase {
    final TravelRepository travelRepository;
    GetSearchHistoryUsecase({required this.travelRepository});
      Future<List<Map<String, String>>> execute() async{
        return await travelRepository.getSearchHistory();
      }

}