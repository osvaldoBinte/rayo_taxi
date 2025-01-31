import 'package:rayo_taxi/features/travel/domain/entities/qualification/qualification_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/travelwithtariff_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class QualificationUsecase {
  final NotificationRepository notificationRepository;
  QualificationUsecase({required this.notificationRepository});
  Future<void> execute(QualificationEntitie qaualificationEntitie) async{
    return await notificationRepository.qualification(qaualificationEntitie);
  }
}