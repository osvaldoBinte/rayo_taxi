import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/travelwithtariff_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/confirm_travel_with_tariff_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/reject_travel_offer_usecase.dart';


part 'rejectTravelOffer_event.dart';
part 'rejectTravelOffer_state.dart';
class RejecttravelofferGetx   extends GetxController {
  final RejectTravelOfferUsecase rejectTravelOfferUsecase;
  var state = Rx<RejecttravelofferState>(RejecttravelofferInitial());
  
  RejecttravelofferGetx({required this.rejectTravelOfferUsecase});
 
  rejecttravelofferGetx(RejectTravelofferEventEvent event) async {
    print("rejecttravelofferGetx.rejecttravelofferGetx: Start");
    state.value = RejecttravelofferLoading();
    try {
      await rejectTravelOfferUsecase.execute(event.travel);
      print("rejecttravelofferGetx.rejecttravelofferGetx: After execute");
      print("object");
      state.value = RejecttravelofferSuccessfully();
      
    } catch (e) {
      print("rejecttravelofferGetx.rejecttravelofferGetx: Exception - $e");
      state.value = RejecttravelofferFailure(e.toString());
    }
    print("rejecttravelofferGetx.rejecttravelofferGetx: End");
  }
}
