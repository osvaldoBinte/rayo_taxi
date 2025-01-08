import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/travelwithtariff_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class OfferNegotiationUsecase {
  final NotificationRepository notificationRepository;
  OfferNegotiationUsecase({required this.notificationRepository});
  Future<void> execute(TravelwithtariffEntitie travelwithtariffEntitie) async{
    return await notificationRepository.offerNegotiation(travelwithtariffEntitie);
  }
}