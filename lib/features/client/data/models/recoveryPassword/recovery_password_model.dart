import 'package:rayo_taxi/features/client/domain/entities/recoveryPassword/recovery_password_entitie.dart';

class RecoveryPasswordModel extends RecoveryPasswordEntitie {
  RecoveryPasswordModel(
      {final String? email,
      final String? recovery_code,
      final String? new_password})
      : super(
            email: email,
            recovery_code: recovery_code,
            new_password: new_password);

  factory RecoveryPasswordModel.fromJson(Map<String, dynamic> json) {
    return RecoveryPasswordModel(
      email: json['email'] ?? '',
      recovery_code: json['recovery_code'] ?? '',
      new_password: json['new_password'] ?? '',
    );
  }
  factory RecoveryPasswordModel.fromEntity(
      RecoveryPasswordEntitie recoveryPassword) {
    return RecoveryPasswordModel(
      email: recoveryPassword.email,
      recovery_code: recoveryPassword.recovery_code,
      new_password: recoveryPassword.new_password,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'recovery_code': recovery_code,
      'new_password': new_password,
    };
  }
}
