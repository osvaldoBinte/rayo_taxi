import 'package:rayo_taxi/features/travel/domain/entities/qualification/qualification_entitie.dart';

class QualificationModel extends QualificationEntitie {
  QualificationModel({
    required int qualification,
    required int id_travel_driver,
  }) : super(
          qualification: qualification,
          id_travel_driver: id_travel_driver,
        );
  factory QualificationModel.fromJson(Map<String, dynamic> json) {
    return QualificationModel(
      qualification: json['qualification'] ?? 0,
      id_travel_driver: json['id_travel_driver'] ?? 0,
    );
  }

  factory QualificationModel.fromEntity(QualificationEntitie qualification) {
    return QualificationModel(
      qualification: qualification.qualification,
      id_travel_driver: qualification.id_travel_driver,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'qualification': qualification,
      'id_travel_driver': id_travel_driver
    };
  }
}
