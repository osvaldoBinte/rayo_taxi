import 'package:rayo_taxi/features/client/domain/entities/client.dart';
import 'package:rayo_taxi/features/client/domain/entities/genders_entities.dart';

class GendersModel extends GendersEntities {
  GendersModel({
    required int id,
    required String label,
  }) : super(
          id: id,
          label: label,
        );
  factory GendersModel.fromJson(Map<String, dynamic> json) {
    return GendersModel(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
    );
  }
}
