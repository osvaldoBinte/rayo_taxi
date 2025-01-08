import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/confirmar_tariff_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/travelwithtariff_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/confirm_travel_with_tariff_usecase.dart';


part 'travelWithTariff_event.dart';
part 'travelWithTariff_state.dart';
class TravelwithtariffGetx   extends GetxController {
  final ConfirmTravelWithTariffUsecase confirmTravelWithTariffUsecase;
  var state = Rx<TravelwithtariffState>(TravelwithtariffInitial());
  
  TravelwithtariffGetx({required this.confirmTravelWithTariffUsecase});

  travelwithtariffGetx(TravelWithtariffEvent event) async {
    print("TravelGetx.Travelwithtariff: Start");
    state.value = TravelwithtariffLoading();
    try {
       // Check the entity values
    print('Entity driverId: ${event.travel.driverId}');
    print('Entity travelId: ${event.travel.travelId}');

      await confirmTravelWithTariffUsecase.execute(event.travel);
      print("TravelGetx.Travelwithtariff: After execute");
      print("object");
      state.value = TravelwithtariffSuccessfully();
    } catch (e) {

    print('Entity driverId: ${event.travel.driverId}');
    print('Entity travelId: ${event.travel.travelId}');

      print("TravelGetx.Travelwithtariff: Exception - $e");
      state.value = TravelwithtariffFailure(e.toString());
    }
    print("TravelGetx.Travelwithtariff: End");
  }
}
