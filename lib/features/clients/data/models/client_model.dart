import 'package:rayo_taxi/features/clients/domain/entities/client.dart';

class ClientModel extends Client {
  ClientModel({
    int? id,
     String? name,
     String? email,
     String? password,
     int? years_old,
    int? id_company,
      String? birthdate,
    String? token,
  }) : super(
            id: id,
            name: name,
            email: email,
            password: password,
            years_old: years_old,
            id_company: id_company,
            token: token , birthdate: birthdate);
  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      years_old: json['years_old'] ?? '',
      id_company: json['id_company'] ?? '',
      token: json['token'] ?? '',
            birthdate: json['birthdate'] ?? '',

    );
  }

  factory ClientModel.fromEntity(Client client) {
    return ClientModel(
      id: client.id,
      name: client.name,
      email: client.email,
      password: client.password,
      years_old: client.years_old,
      id_company: client.id_company,
      token: client.token,
      birthdate:client.birthdate
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
      'token': token,
      'birthdate':birthdate
    };
  }
}
