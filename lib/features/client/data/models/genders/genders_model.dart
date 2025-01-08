import 'package:rayo_taxi/features/client/domain/entities/client.dart';
import 'package:rayo_taxi/features/client/domain/entities/genders_entities.dart';

class GendersModel extends GendersEntities {
  GendersModel({
    required final int id,
   required final String label,
  }) : super(
            id: id,
            label: label,);
  factory GendersModel.fromJson(Map<String, dynamic> json) {
    return GendersModel(
        id: json['id'] ?? '',
        label: json['label'] ?? '',
        );
        
  }

  factory GendersModel.fromEntity(GendersEntities gendersEntities) {
    return GendersModel(
        id: gendersEntities.id,
        label: gendersEntities.label,
        );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
    };
  }
}
