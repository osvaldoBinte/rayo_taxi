
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/travelwithtariff_entitie.dart';

class TravelwithtariffModal extends TravelwithtariffEntitie {
  TravelwithtariffModal({
    
  required int driverId,
  required int travelId,
required double? tarifa})
      : super(driverId: driverId,travelId:travelId, tarifa: tarifa);
  factory TravelwithtariffModal.fromJson(Map<String, dynamic> json) {
    return TravelwithtariffModal(
        driverId: json['driverId'] ?? 0,
        travelId: json['travelId'] ?? 0,
         tarifa: json['tarifa'] ?? 0);
  }

  factory TravelwithtariffModal.fromEntity(TravelwithtariffEntitie travelwithtariff) {
    return TravelwithtariffModal(
        driverId: travelwithtariff.driverId,
                travelId: travelwithtariff.travelId,

         tarifa: travelwithtariff.tarifa);
  }

  Map<String, dynamic> toJson() {
    return {'driverId': driverId,
    'travelId': travelId,
     'tarifa': tarifa};
  }
}
