import 'package:rayo_taxi/features/travel/domain/entities/qualification/qualification_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/travelwithtariff_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class SkipQualificationUsecase {
  final NotificationRepository notificationRepository;
  SkipQualificationUsecase({required this.notificationRepository});
  Future<void> execute(QualificationEntitie qaualificationEntitie) async{
    return await notificationRepository.skipqualification(qaualificationEntitie);
  }
}