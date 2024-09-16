import 'package:rayo_taxi/features/driver/domain/entities/driver.dart';

class DriverModel extends Driver {
  DriverModel({
    int? id,
     String? name,
     String? email,
     String? password,
     int? years_old,
    int? id_company,
    
  }) : super(
            id: id,
            name: name,
            email: email,
            password: password,
            years_old: years_old,
            id_company: id_company,
            );
  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      years_old: json['years_old'] ?? '',
      id_company: json['id_company'] ?? '',
    );
  }

  factory DriverModel.fromEntity(Driver client) {
    return DriverModel(
      id: client.id,
      name: client.name,
      email: client.email,
      password: client.password,
      years_old: client.years_old,
      id_company: client.id_company,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'years_old': years_old,
      'id_company': id_company,
    };
  }
}