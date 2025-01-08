import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/delete/delete_travel_getx.dart';

class CancelTravelButton extends StatelessWidget {
  final String travelId;
  final int idStatus;
  final GlobalKey<NavigatorState> navigatorKey;
  final DeleteTravelGetx _deleteTravelGetx = Get.find<DeleteTravelGetx>();

  CancelTravelButton({
    required this.travelId,
    required this.idStatus,
    required this.navigatorKey,
  });
  final currentTravelGetx = Get.find<CurrentTravelGetx>();

  void _handleCancelTravel(BuildContext context) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: '¿Estás seguro?',
      text: '¿Deseas cancelar este viaje?',
      confirmBtnText: 'Sí, cancelar',
      cancelBtnText: 'No',
      showCancelBtn: true,
      onConfirmBtnTap: () {
        _deleteTravelGetx.deleteTravel(DeleteTravelEvent(travelId));
        ever(_deleteTravelGetx.state, (DeleteState state) {
          if (state is DeleteCreatedSuccessfully) {
                                                   currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());

          }
        });
        Navigator.pop(context);
        
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (idStatus != 1) return const SizedBox.shrink();

    return Positioned(
      bottom: 80,
      left: 10,
      right: 10,
      child: ElevatedButton(
        onPressed: () => _handleCancelTravel(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.Statuscancelled,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Cancelar Viaje',
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