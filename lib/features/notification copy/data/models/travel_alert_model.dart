import 'package:rayo_taxi/features/travel/domain/entities/travel_alert.dart';

class TravelAlertModel extends TravelAlert {
  TravelAlertModel({
    required int id,
    required String date,
    required String start_longitude,
    required String start_latitude,
    required String end_longitude,
    required String end_latitude,
    required num kilometers,
    required int id_client,
    required int id_company,
    required int id_status,
    required String status,
    required int cost,
    String? client
  }) : super(
            id: id,
            date: date,
            start_longitude: start_longitude,
            start_latitude: start_latitude,
            end_longitude: end_longitude,
            end_latitude: end_latitude,
            kilometers: kilometers,
            id_client: id_client,
            id_company: id_company,
            id_status: id_status,
            status: status,
            cost:cost,
            client:client);
  factory TravelAlertModel.fromJson(Map<String, dynamic> json) {
    return TravelAlertModel(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      start_longitude: json['start_longitude'] ?? '',
      start_latitude: json['start_latitude'] ?? '',
      end_longitude: json['end_longitude'] ?? '',
      end_latitude: json['end_latitude'] ?? '',
      kilometers: json['kilometers'] ?? '',
      id_client: json['id_client'] ?? '',
      id_company: json['id_company'] ?? '',
      id_status: json['id_status'] ?? '',
      status: json['status'] ?? '', 
      cost: json['cost'] ?? '',
      client:json['client']?? ''
    );
  }

  factory TravelAlertModel.fromEntity(TravelAlert travelAlert) {
    return TravelAlertModel(
      id: travelAlert.id,
      date: travelAlert.date,
      start_longitude: travelAlert.start_longitude,
      start_latitude: travelAlert.start_latitude,
      end_longitude: travelAlert.end_longitude,
      end_latitude: travelAlert.end_latitude,
      kilometers: travelAlert.kilometers,
      id_client: travelAlert.id_client,
      id_company: travelAlert.id_company,
      id_status: travelAlert.id_status,
      status: travelAlert.status, 
      cost: travelAlert.cost,
      client:travelAlert.client
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'start_longitude': start_longitude,
      'start_latitude': start_latitude,
      'end_longitude': end_longitude,
      'end_latitude': end_latitude,
      'kilometers': kilometers,
      'id_client': id_client,
      'id_company': id_company,
      'id_status': id_status,
      'status': status,
      'cost':cost,
      'client':client
    };
  }
}
