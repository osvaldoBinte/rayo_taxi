import 'package:rayo_taxi/features/travel/data/models/driver/driver_model.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelalert/travel_alert.dart';

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
    required double cost,
    String? client,
    final String? tarifa,
    required int waiting_for,
    required String driver,
    required String id_travel_driver,
    required String path_photo,
    required String plates,
    String? name,
    String? model,
    required int pending_qualification,
    required int qualification,
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
            cost: cost,
            client: client,
            tarifa: tarifa,
            waiting_for: waiting_for,
            driver: driver,
            id_travel_driver: id_travel_driver,
            path_photo: path_photo,
            plates: plates,
            name: name,
            model: model,
            qualification: qualification,
            pending_qualification: pending_qualification);
  factory TravelAlertModel.fromJson(Map<String, dynamic> json) {
    return TravelAlertModel(
        id: json['id'] ?? 0,
        date: json['date'] ?? '',
        start_longitude: json['start_longitude'] ?? '',
        start_latitude: json['start_latitude'] ?? '',
        end_longitude: json['end_longitude'] ?? '',
        end_latitude: json['end_latitude'] ?? '',
        kilometers: (json['kilometers'] as num).toDouble(),
        id_client: json['id_client'] ?? 0,
        id_company: json['id_company'] ?? 0,
        id_status: json['id_status'] ?? 0,
        status: json['status'] ?? '',
        cost: (json['cost'] as num).toDouble(),
        client: json['client'],
        tarifa: (json['tarifa'] != null) ? json['tarifa'].toString() : '0',
        waiting_for: (json['waiting_for'] is String)
            ? int.tryParse(json['waiting_for']) ?? 0
            : (json['waiting_for'] ?? 0),
        driver: json['driver'] ?? '',
        id_travel_driver: json['id_travel_driver'] ?? '0',
        path_photo: json['path_photo'] ?? '',
        plates: json['plates'] ?? '',
        name: json['name'] ?? '',
        model: json['model'] ?? '',
        qualification: json['qualification'] ?? 0,
        pending_qualification: json['pending_qualification'] ?? 0);
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
        client: travelAlert.client,
        tarifa: travelAlert.tarifa,
        waiting_for: travelAlert.waiting_for,
        driver: travelAlert.driver,
        id_travel_driver: travelAlert.id_travel_driver,
        path_photo: travelAlert.path_photo,
        plates: travelAlert.plates,
        name: travelAlert.name,
        model: travelAlert.model,
        qualification: travelAlert.qualification,
        pending_qualification: travelAlert.pending_qualification);
  }

  static String _getImporte(dynamic travelData) {
    if (travelData.id_status == 1 || travelData.id_status == 2) {
      return travelData.cost.toString();
    }
    return travelData.tarifa.toString();
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
      'cost': cost,
      'client': client,
      'tarifa': tarifa,
      'waiting_for': waiting_for,
      'driver': driver,
      'id_travel_driver': id_travel_driver,
      'path_photo': path_photo,
      'plates': plates,
      'name': name,
      'model': model,
      'qualification': qualification,
      'pending_qualification': pending_qualification
    };
  }
}
