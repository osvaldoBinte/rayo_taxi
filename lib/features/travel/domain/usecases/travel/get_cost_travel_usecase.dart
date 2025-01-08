

  import 'package:rayo_taxi/features/travel/domain/entities/getcosttraveEntitie/getcosttravel_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class GetCostTravelUsecase {
  final NotificationRepository notificationRepository;
  GetCostTravelUsecase({required this.notificationRepository});
  Future<GetcosttravelEntitie> execute (GetcosttravelEntitie getcosttravelEntitie) async {
    return await notificationRepository.getcosttravel(getcosttravelEntitie);
  }
}
