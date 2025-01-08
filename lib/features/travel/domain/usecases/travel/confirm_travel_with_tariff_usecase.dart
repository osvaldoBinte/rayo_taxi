import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/confirmar_tariff_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/travelwithtariff_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class ConfirmTravelWithTariffUsecase {
  final NotificationRepository notificationRepository;
  ConfirmTravelWithTariffUsecase({required this.notificationRepository});
  Future<void> execute(ConfirmarTariffEntitie confirmarTariffEntitie) async{
    return await notificationRepository.confirmTravelWithTariff(confirmarTariffEntitie);
  }
}