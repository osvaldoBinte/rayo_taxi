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
  final int cost;
  String? client;
  TravelAlert({
    required this.id,
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
    this.client
  });
}
