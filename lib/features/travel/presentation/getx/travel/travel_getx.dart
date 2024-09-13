import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/clients/domain/usecases/create_client_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/posh_travel_usecase.dart';

part 'travel_event.dart';
part 'travel_state.dart';
class TravelGetx extends GetxController {
  final PoshTravelUsecase poshTravelUsecase;
  var state = Rx<TravelState>(TravelInitial());
  TravelGetx({required this.poshTravelUsecase});
  poshTravel(CreateTravelEvent event) async {
    state.value = TravelLoading();
    try {
      await poshTravelUsecase.execute(event.travel);
      state.value = TravelCreatedSuccessfully();
    } catch (e) {
      state.value = TravelCreationFailure(e.toString());
    }
  }
}