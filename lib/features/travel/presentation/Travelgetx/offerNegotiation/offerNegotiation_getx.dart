import 'package:meta/meta.dart';
import 'package:get/get.dart';

import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/travelwithtariff_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/offer_negotiation_usecase.dart';

part 'offerNegotiationevent.dart';
part 'offerNegotiation_state.dart';
class OffernegotiationGetx   extends GetxController {
  final OfferNegotiationUsecase offerNegotiationUsecase;
  var state = Rx<OffernegotiationState>(OffernegotiationInitial());
  
  OffernegotiationGetx({required this.offerNegotiationUsecase});

  offernegotiation(OfferNegotiationevent event) async {
    print("offernegotiation.Travelwithtariff: Start");
    state.value = OffernegotiationLoading();
    try {
      await offerNegotiationUsecase.execute(event.travel);
      print("OffernegotiationGetx.OffernegotiationGetx: After execute");
      print("object");
      state.value = OffernegotiationSuccessfully();
    } catch (e) {
      print("OffernegotiationGetx.OffernegotiationGetx: Exception - $e");
      state.value =OffernegotiationFailure(e.toString());
    }
    print("OffernegotiationGetx.OffernegotiationGetx: End");
  }
}
