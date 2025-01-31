import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/travelwithtariff_entitie.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/rejectTravelOffer/rejectTravelOffer_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/delete/delete_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/customSnacknar.dart';

class CancelTravelButton extends StatelessWidget {
  final String travelId;
  final int idStatus;
  final GlobalKey<NavigatorState> navigatorKey;

  final DeleteTravelGetx _deleteTravelGetx = Get.find<DeleteTravelGetx>();
  final RejecttravelofferGetx _rejectTravelOfferGetx =
      Get.find<RejecttravelofferGetx>();
  final travelAlertGetx = Get.find<TravelsAlertGetx>();
  final currentTravelGetx = Get.find<CurrentTravelGetx>();

  CancelTravelButton({
    required this.travelId,
    required this.idStatus,
    required this.navigatorKey,
  });

  void _handleCancelTravel() {
    if (idStatus == 1) {
      // Lógica para idStatus == 1
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Cancelar Vieaje',
        text: '¿Deseas cancelar este viaje?',
        confirmBtnText: 'Sí, cancelar',
        cancelBtnText: 'No',
        showCancelBtn: true,
        onConfirmBtnTap: () {
          _deleteTravelGetx.deleteTravel(DeleteTravelEvent(travelId));
          ever(_deleteTravelGetx.state, (DeleteState state) {
            if (state is DeleteCreatedSuccessfully) {
              currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());
              travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());
            }
          });
          Navigator.pop(Get.context!);
        },
      );
    } else if (idStatus == 3) {
  QuickAlert.show(
    context: Get.context!,
    type: QuickAlertType.error,
    title: 'Cancelar Vieaje',
    text: '¿Deseas cancelar el viaje?',
    confirmBtnText: 'Sí, rechazar',
    cancelBtnText: 'No',
    showCancelBtn: true,
    onConfirmBtnTap: () async {  // Hacer async
      final state = currentTravelGetx.state.value;

      if (state is! TravelAlertLoaded) {
        print("Error: No travel data available.");
          Navigator.pop(Get.context!);
        return;
      }

      final travel2 = state.travel.first;
      final travelId = travel2.id;
      final driverId = int.parse(travel2.id_travel_driver);

      try {          Navigator.pop(Get.context!);

        
        final travel = TravelwithtariffEntitie(
          driverId: driverId,
          travelId: travelId,
        );
        final event = RejectTravelofferEventEvent(travel: travel);
        await Get.find<RejecttravelofferGetx>().rejecttravelofferGetx(event);

        CustomSnackBar.showSuccess(
          'Éxito',
          'El rechazo de la oferta de viaje se realizó correctamente',
        );
        await currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());

      } catch (error) {
        CustomSnackBar.showError(
          'Error',
          'Hubo un problema al rechazar la oferta de viaje',
        );
      }
    },
  );
}
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar el botón solo si el idStatus es 1 o 3
    if (idStatus != 1 && idStatus != 3) return const SizedBox.shrink();

    return Positioned(
      bottom: 80,
      left: 10,
      right: 10,
      child: ElevatedButton(
        onPressed: () => _handleCancelTravel(),
        style: ElevatedButton.styleFrom(
          backgroundColor: idStatus == 1
              ? Theme.of(context).colorScheme.Statuscancelled
              : Theme.of(context).colorScheme.Statuscancelled,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          idStatus == 1 ? 'Cancelar Viaje' : 'Cancelar Viaje',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.buttontext,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
