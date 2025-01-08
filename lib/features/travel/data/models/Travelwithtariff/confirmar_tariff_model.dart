import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/confirmar_tariff_entitie.dart';

class ConfirmarTariffModel extends ConfirmarTariffEntitie {
  ConfirmarTariffModel({
    required int driverId,
    required int travelId,
  }) : super(
          driverId: driverId,
          travelId: travelId,
        );
  factory ConfirmarTariffModel.fromJson(Map<String, dynamic> json) {
    return ConfirmarTariffModel(
      driverId: json['driverId'] ?? 0,
      travelId: json['travelId'] ?? 0,
    );
  }

  factory ConfirmarTariffModel.fromEntity(
      ConfirmarTariffEntitie travelwithtariff) {
    return ConfirmarTariffModel(
        driverId: travelwithtariff.driverId,
        travelId: travelwithtariff.travelId,
        );
  }

  Map<String, dynamic> toJson() {
    return {'driverId': driverId, 'travelId': travelId};
  }
}
