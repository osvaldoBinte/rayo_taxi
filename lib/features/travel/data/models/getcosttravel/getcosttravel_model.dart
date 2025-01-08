import 'package:rayo_taxi/features/travel/domain/entities/getcosttraveEntitie/getcosttravel_entitie.dart';

class GetcosttravelModel extends GetcosttravelEntitie {
  GetcosttravelModel({
    String? message,
    num? data,
    required num kilometers,
    required double duration,
  }) : super(
            message: message,
            data: data,
            kilometers: kilometers,
            duration: duration);

  factory GetcosttravelModel.fromJson(Map<String, dynamic> json) {
    return GetcosttravelModel(
      kilometers: json['kilometers'] ?? 0, 
      duration: json['duration'] is num 
          ? (json['duration'] as num).toDouble() 
          : 0.0,
      message: json['message'],
      data: json['data'] is num 
          ? json['data'] 
          : 0,
    );
  }

  factory GetcosttravelModel.fromEntity(GetcosttravelEntitie getcosttrave) {
    return GetcosttravelModel(
      kilometers: getcosttrave.kilometers,
      duration: getcosttrave.duration,
      message: getcosttrave.message,
      data: getcosttrave.data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
 'kilometers': kilometers,
      'duration': duration,
      'message': message,
      'data': data,     
    };
  }
}
