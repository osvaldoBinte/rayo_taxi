import 'package:rayo_taxi/features/travel/data/models/driver/driver_model.dart';

class TravelAlert {
  final int id;
  final String date;
  final String start_longitude;
  final String start_latitude;
  final String end_longitude;
  final String end_latitude;
  final num kilometers;
  final int id_client;
  final int id_company;
  final int id_status;
  final String status;
  String? client;
  String? name;
  String?model;
  final double cost;
  final String? tarifa;
  final int waiting_for;
  final String driver;
  final String id_travel_driver;
  final String path_photo;
  final String plates;
  final int pending_qualification;
  final int qualification;
  final String passenger;
  TravelAlert(
      {required this.id,
      required this.date,
      required this.start_longitude,
      required this.start_latitude,
      required this.end_longitude,
      required this.end_latitude,
      required this.kilometers,
      required this.id_client,
      required this.id_company,
      required this.id_status,
      required this.status,
      required this.cost,
      this.client,
      required this.waiting_for,
      required this.id_travel_driver,
      this.tarifa,
      this.model,
      required this.driver,
      required this.path_photo,
      required this.plates,
      this.name,
      required this.pending_qualification,
      required this.qualification,
      required this.passenger});
}
