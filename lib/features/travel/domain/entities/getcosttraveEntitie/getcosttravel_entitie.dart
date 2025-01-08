import 'package:rayo_taxi/features/travel/data/models/driver/driver_model.dart';

class GetcosttravelEntitie {
   String? message;
num? data;
  final num kilometers;
  final double duration;
  GetcosttravelEntitie(
      {required this.kilometers,
      required this.duration,
      this.data,
      this.message
     });
}
