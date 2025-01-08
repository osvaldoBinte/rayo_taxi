import 'package:rayo_taxi/features/client/domain/entities/client.dart';

class ClientModel extends Client {
  ClientModel(
      {int? id,
      String? name,
      String? email,
      String? password,
      int? years_old,
      String? new_password,
      String? current_password,
      int? id_company,
      String? birthdate,
      String? token,
      String? phone_support,
      String? photo_profile,
      String? path_photo,
      int? id_gender})
      : super(
            id: id,
            name: name,
            email: email,
            password: password,
            new_password: new_password,
            current_password: current_password,
            years_old: years_old,
            id_company: id_company,
            token: token,
            birthdate: birthdate,
            photo_profile: photo_profile,
            path_photo: path_photo,
            phone_support: phone_support,
            id_gender: id_gender);

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        password: json['password'] ?? '',
        new_password: json['new_password'] ?? '',
        current_password: json['current_password'] ?? '',
        years_old: json['years_old'] ?? '',
        id_company: json['id_company'] ?? '',
        token: json['token'] ?? '',
        birthdate: json['birthdate'] ?? '',
        photo_profile: json['photo_profile'] ?? '',
        path_photo: json['path_photo' ?? ''],
        id_gender: json['id_gender'] ?? '',
              phone_support: json['phone_support'] ?? '',
);
  }

  factory ClientModel.fromEntity(Client client) {
    return ClientModel(
        id: client.id,
        name: client.name,
        email: client.email,
        password: client.password,
        new_password: client.new_password,
        current_password: client.current_password,
        years_old: client.years_old,
        id_company: client.id_company,
        token: client.token,
        birthdate: client.birthdate,
        photo_profile: client.photo_profile,
        path_photo: client.path_photo,
      phone_support: client.phone_support,
        id_gender: client.id_gender);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'new_password': new_password,
      'current_password': current_password,
      'years_old': years_old,
      'id_company': id_company,
      'token': token,
      'birthdate': birthdate,
      'photo_profile': photo_profile,
      'path_photo': path_photo,
      'id_gender': id_gender,
            'phone_support': phone_support,
            

    };
  }
}
