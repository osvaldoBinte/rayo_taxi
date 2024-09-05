import 'package:rayo_taxi/features/driver/domain/entities/driver.dart';

class DriverModel extends Driver {
  DriverModel({
    String? email,
    String? password,
  }) : super(email: email, password: password);

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
        email: json['email'] ?? '', password: json['password'] ?? '');
  }
  factory DriverModel.fromEntity(Driver driver) {
    return DriverModel(
     
      email: driver.email,
      password: driver.password,
    );
  }
   Map<String, dynamic> toJson(){
    return {
      'email': email,
      'password':password
    };
   }
}
