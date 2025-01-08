

import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/travelwithtariff_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class RejectTravelOfferUsecase {
  final NotificationRepository notificationRepository;
  RejectTravelOfferUsecase({required this.notificationRepository});
  Future<void> execute(TravelwithtariffEntitie travelwithtariffEntitie) async{
    return await notificationRepository.rejectTravelOffer(travelwithtariffEntitie);
  }
}