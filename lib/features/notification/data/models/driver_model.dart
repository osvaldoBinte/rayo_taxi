import 'package:rayo_taxi/features/notification/domain/entities/dirver.dart';
class DriverModel extends Driver {
  DriverModel( {

      required int id,
  required String name,
  required String id_user,
  required String birthdate,
  required String years_old
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
      id_user: json['id_user'] ?? 0,
      birthdate: json['birthdate'] ?? '',
      years_old: json['years_old'] ?? 0,
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
