

import 'package:rayo_taxi/features/travel/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/repositories/travel_repository.dart';

class TravelAlertUsecase {
  final TravelRepository travelRepository;
  TravelAlertUsecase({required this.travelRepository});
  Future<List<TravelAlertModel>> execute(bool connection) async {
    return await travelRepository.getNotification(connection);
  }
}