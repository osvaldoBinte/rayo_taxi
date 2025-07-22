import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';

class TravelModel extends Travel {
  TravelModel({
    double? start_longitude,
    double? start_latitude,
    double? end_longitude,
    double? end_latitude,
    String? kilometers,
    String? duration,
    String? state,
    String? municipality,
    required String passenger,
  }) : super(
            start_longitude: start_longitude,
            start_latitude: start_latitude,
            end_longitude: end_longitude,
            end_latitude: end_latitude,
            kilometers: kilometers,
            duration: duration,
            state: state,
            municipality: municipality,
            passenger:passenger);
  factory TravelModel.fromJson(Map<String, dynamic> json) {
    return TravelModel(
      start_longitude: json['start_longitude'] ?? '',
      start_latitude: json['start_latitude'] ?? '',
      end_longitude: json['end_longitude'] ?? '',
      end_latitude: json['end_latitude'] ?? '',
      kilometers: json['kilometers'] ?? '',
      duration: json['duration'] ?? '',
      state: json['state'] ?? '',
      municipality: json['municipality'] ?? '',
      passenger: json['passenger'] ?? ''
    );
  }

  factory TravelModel.fromEntity(Travel travel) {
    return TravelModel(
        start_longitude: travel.start_longitude,
        start_latitude: travel.start_latitude,
        end_longitude: travel.end_longitude,
        end_latitude: travel.end_latitude,
        kilometers: travel.kilometers,
        duration: travel.duration,
        state: travel.state,
        municipality: travel.municipality,
        passenger: travel.passenger);
  }

  Map<String, dynamic> toJson() {
    return {
      'start_longitude': start_longitude,
      'start_latitude': start_latitude,
      'end_longitude': end_longitude,
      'end_latitude': end_latitude,
      'kilometers': kilometers,
      'duration': duration,
      'state':state,
      'municipality':municipality,
      'passenger':passenger
    };
  }
}
