

import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class CurrentTravelUsecase {
  final NotificationRepository notificationRepository;
  CurrentTravelUsecase({required this.notificationRepository});
  Future<List<TravelAlertModel>> execute() async {
    return await notificationRepository.current_travel();
  }
}