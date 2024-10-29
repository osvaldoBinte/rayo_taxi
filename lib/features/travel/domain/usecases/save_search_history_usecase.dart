import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class SaveSearchHistoryUsecase {
  final TravelRepository travelRepository;
  SaveSearchHistoryUsecase({required this.travelRepository});
    Future<void> execute(Map<String, String> searchItem) async {
      return  await travelRepository.saveSearchHistory(searchItem);
    }
}