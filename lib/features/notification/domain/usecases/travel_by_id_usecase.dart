

import 'package:rayo_taxi/features/notification/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/notification/domain/repositories/notification_repository.dart';

class TravelByIdUsecase {
  final NotificationRepository travelRepository;
  TravelByIdUsecase({required this.travelRepository});
  Future<List<TravelAlertModel>> execute(int? idTravel,bool connection) async {
    return await travelRepository.getbyIdtravelid(idTravel, connection);
  }
}