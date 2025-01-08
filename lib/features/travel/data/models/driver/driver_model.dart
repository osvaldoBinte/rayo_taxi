import 'package:rayo_taxi/features/travel/domain/entities/driver/dirver.dart';
class DriverModel extends Driver {
  DriverModel({
    required int id,
    required String name,
    required int id_user, // Cambiado a int
    required String birthdate,
    required int years_old, // Cambiado a int
  }) : super(
          id: id,
          name: name,
          id_user: id_user,
          birthdate: birthdate,
          years_old: years_old,
        );

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      id_user: json['id_user'] ?? 0, // Asegúrate de que el valor sea un int
      birthdate: json['birthdate'] ?? '',
      years_old: json['years_old'] ?? 0, // Asegúrate de que el valor sea un int
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'id_user': id_user,
      'birthdate': birthdate,
      'years_old': years_old,
    };
  }
}
