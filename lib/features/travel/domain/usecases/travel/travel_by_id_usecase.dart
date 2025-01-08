

import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class TravelByIdUsecase {
  final NotificationRepository travelRepository;
  TravelByIdUsecase({required this.travelRepository});
  Future<List<TravelAlertModel>> execute(int? idTravel,bool connection) async {
    return await travelRepository.getbyIdtravelid(idTravel, connection);
  }
}